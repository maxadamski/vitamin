package com.maxadamski.vitamin

import OpUtils.{getArgs, mkGroup}
import System.err.{println => eprintln}
import System.exit
import java.nio.file.Paths

import AST.Tag.Tag
import ASTUtils._
import Report._
import Functions._
import Types._
import AST._

import scala.collection.mutable

case class Obj(
  var value: Any,
  var typ: AType = NIL,
  var const: Boolean = false,
)

class Env(
  var opGroups: Map[String, OpGroup] = Map(),
  var opNames: Set[OpName] = Set(),
  var parent: Option[Env] = None,
  var vars: mutable.Map[String, Obj] = mutable.Map(),
  var name: String = "main"
)

class Ctx(
  var env: Env = new Env(),
  var fileStack: mutable.Stack[String] = mutable.Stack(),
  var nodeStack: mutable.Stack[Tree] = mutable.Stack(),
  var parser: PrattParser = null,
) {

  def node: Tree = nodeStack.top

  def file: String = fileStack.top

  def newEnv(): Env = new Env(parent = Some(env))

  def pushEnv(env: Env = newEnv()): Unit = {
    this.env = env
  }

  def popEnv(): Env = {
    val oldEnv = env
    if (oldEnv.parent.isEmpty) throw new RuntimeException("Cannot pop environment, as the stack is empty")
    env = oldEnv.parent.get
    oldEnv
  }

  def name: String = {
    var local: Option[Env] = Some(env)
    var names = Array[String]()
    while (local.isDefined) {
      names +:= local.get.name
      local = local.get.parent
    }
    names.mkString("/")
  }

  def lookup(name: String): Option[Env] = {
    var local: Option[Env] = Some(env)
    while (local.isDefined) {
      if (local.get.vars.contains(name))
        return local
      else
        local = local.get.parent
    }
    None
  }

  def findFun(name: String): List[Obj] = {
    var local: Option[Env] = Some(env)
    var fun = List[Obj]()
    while (local.isDefined) {
      for ((k, v) <- local.get.vars) {
        if (k.split(":")(0) == name) {
          fun :+= v
        }
      }
      local = local.get.parent
    }
    fun
  }

  def let(name: String, typ: AType, value: Any): Unit = {
    if (env.vars.contains(name))
      throw new RuntimeException(error__eval__let_defined(this, name))
    env.vars.put(name, Obj(value, typ))
  }

  def set(name: String, typ: AType, value: Any): Unit = lookup(name) match {
    case Some(dst) =>
      if (dst.vars(name).typ != typ)
        throw new RuntimeException("Assigning to a variable of incompatible type")
      dst.vars(name).value = value
    case None =>
      throw new RuntimeException(error__eval__set_undefined(this, name))
  }

  def get(name: String): Option[Any] = lookup(name).map(dst => dst.vars(name))

  def mangleTyp(typ: AType): String = typ match {
    case Fun(FUN :: tail) => tail.map(_.toString).mkString(" -> ")
    case Typ(x) => x
    case Var(x) => x
  }

  def mangleFun(name: String, arity: Int, typ: AType): String = {
    s"$name:$arity:${mangleTyp(typ)}"
  }

}

object Vitamin {

  def getTyp(obj: Any): AType = obj match {
    case OBJ_VOID => VOID
    case OBJ_NIL => NIL
    case _: Boolean => BOOL
    case _: Int => INT
    case _: Long => I64
    case _: Float => REAL
    case _: Double => REAL
    case _: String => STR
    case AST.Lambda(_, _) => ANY
    case Builtin(typ, _) => typ
    case _ => ANY
  }

  def tupleTyp(typs: List[AType]): AType = {
    Types.Fun(typs)
  }

  def isFun(typ: AType): Boolean = typ match {
    case _: Fun => true
    case _ => false
  }

  def parseExpressions(ctx: Ctx, ast: Tree): Tree = ast.map() { it =>
    val res = it match {
      case Node(Tag.Flat, _, _) => parsedAST(ctx, it)
      case _ => it
    }
    res match {
      case Call(callee@Atom(name), arg) =>
        if (callee.isDirective)
          runPragma(ctx, name, pragmaArg(arg))
      case _ =>
    }
    res
  }

  def expandMacros(ctx: Ctx, ast: Tree): Tree = ast.map() {
    case Call(Atom(":="), arg) =>
      Node(Tag.Let, arg)
    case Call(Atom("="), Atom(name) :: tail) =>
      Node(Tag.Set, Atom(name) :: tail)
    case Call(Atom(op @ ("+=" | "-=" | "*=")), lhs :: rhs :: Nil) =>
      val do2bin = Map("+=" -> "+", "-=" -> "-", "*=" -> "*")
      Node(Tag.Set, lhs :: Node(Tag.Call, Atom(do2bin(op)) :: lhs :: rhs :: Nil) :: Nil)
    case Call(Atom("if"), pred :: onT :: Nil) =>
      val onT_ = if (onT.tag == Tag.Lambda) Node(Tag.Call, onT :: Nil) else onT
      Node(Tag.Call, Atom("if") :: pred :: onT_ :: Atom("()") :: Nil)
    case Call(Atom("if"), pred :: onT :: onF :: Nil) =>
      val onT_ = if (onT.tag == Tag.Lambda) Node(Tag.Call, onT :: Nil) else onT
      val onF_ = if (onF.tag == Tag.Lambda) Node(Tag.Call, onF :: Nil) else onF
      Node(Tag.Call, Atom("if") :: pred :: onT_ :: onF_ :: Nil)
    case Call(Atom("'"), arg :: Nil) =>
      Node(Tag.Quote, arg :: Nil)
    case it@Call(_, _) if it.isDirective =>
      Zero
    case it =>
      it
  }

  def parsedAST(ctx: Ctx, ast: Tree): Tree = {
    try {
      ctx.parser.parse(ast)
    } catch {
      case e: ParserException =>
        println(e.message)
        ast
    }
  }

  def pragmaArg(arg: List[Tree]): List[Arg] = arg.map {
    case Node(Tag.Arg, value :: Atom(key) :: Nil, _) => Arg(Some(key), value)
    case Node(Tag.Arg, value :: Zero :: Nil, _) => Arg(None, value)
    case it => throw new Exception(s"Pragma argument must have tag Tag.Arg, but was $it")
  }

  def runPragma(ctx: Ctx, name: String, arg: List[Arg]): Unit = name match {
    case "operatorgroup" =>
      val nil = Some(Atom("nil"))
      val defn = Seq(Param("name"), Param("kind"), Param("gt", nil), Param("lt", nil))
      val args = getArgs(defn, arg).map {
        case Atom(str) => str
        case _ => throw new Exception("operatorgroup argument must be an atom")
      }
      val gt = if (args(2) != "nil") Some(args(2)) else None
      val lt = if (args(3) != "nil") Some(args(3)) else None
      ctx.env.opGroups += args(0) -> mkGroup(args(0), args(1), gt, lt)
    case "operator" =>
      val defn = Seq(Param("group"), Param("name", list = true))
      val args = getArgs(defn, arg)
      val group = args(0).asInstanceOf[Leaf].value.asInstanceOf[String]
      val names = args(1).asInstanceOf[Node].data.map(_.asInstanceOf[Leaf].value.asInstanceOf[String])
      for (name <- names) ctx.env.opNames += OpName(group, name)
    case "operatorcompile" =>
      ctx.env.opGroups = OpUtils.updateGroups(ctx.env.opGroups)
      val ops = OpUtils.mkOps(ctx.env.opNames, ctx.env.opGroups)
      ctx.parser = PrattTools.makeParser(ctx, ops)
    case pragma =>
      println(s"unknown pragma $pragma")
  }

  // Call rules:
  // - if the head is an atom
  //   - if the variable exists and is a lambda
  //   - else begin overloaded lambda lookup, based on arg types
  //   - if no lambda is found
  //     - report lambdas with matching stems
  //     - if no stem was matched the lambda is undefined
  //   - evaluate the args, verify types, and begin call
  // - if the head is an expr
  //   - evaluate the expr
  //   - if the resulting value is a lambda
  //     - evaluate the args, verify types, and begin call
  //   - else the value cannot be called
  //
  // - when calling lambdas parameters are passed as a tuple
  // - the tuple is then extracted with pattern matching
  // { x, y, z in ... }
  // { x, (a, b) in ... }

  def evalCall(ctx: Ctx, lambda: Any, arg: List[Any], typ: Fun): Any = {
    lambda match {
      case AST.Lambda(Node(Tag.TupMatch, par, _), body) =>
        ctx.pushEnv()
        // set environment name for nice stack traces
        //ctx.env.name = sig
        // get parameter names
        val names = par.map { case Node(Tag.VarMatch, Atom(name) :: Nil, _) => name }
        // define arguments
        for (((k, v), t) <- names zip arg zip typ.x.tail) ctx.let(k, t, v)
        // evaluate the body and save return value
        val ret = eval(ctx, body)
        ctx.popEnv()
        ret

      case AST.Lambda(Zero, body) =>
        ctx.pushEnv()
        val ret = eval(ctx, body)
        ctx.popEnv()
        ret

      case Builtin(_, body) =>
        // just pass things to a regular lambda
        body(arg)
    }
  }

  def typesUnify(parTyp: AType, argTyp: AType): Boolean = parTyp match {
    case Var(_) => true
    case Typ(name) => argTyp == Typ(name)
    case Fun(head :: tail) =>
      argTyp match {
        case Fun(h :: t) if typesUnify(head, h) =>
          (tail zip t).forall { case (par, arg) => typesUnify(par, arg) }
        case _ => false
      }
  }

  def resolveCall(ctx: Ctx, head: String, args: List[Any]): Any = {
    val lambda = ctx.get(head)
    if (lambda.isDefined)
      return lambda.get
    val stems = ctx.findFun(head)
    if (stems.isEmpty)
      throw new RuntimeException("undefined function")

    val argTypes = tupleTyp(args.map(getTyp))
    val matching = stems.filter(stem => typesUnify(stem.typ, argTypes))
    if (matching.length > 1)
      throw new RuntimeException("multiple functions matched")
    if (matching.isEmpty)
      throw new RuntimeException("mismatched arguments")

    matching.head
  }

  def parseTyp(ast: AST.Tree): AType = {
    case Node(Tag.ConType, head :: tail, _) =>
    case Node(Tag.FunType, head :: tail, _) =>
  }

  def eval(ctx: Ctx, node: Tree): Any = {
    ctx.nodeStack.push(node)
    val ret = node match {
      case Zero =>
        OBJ_VOID

      case Atom(name) =>
        val ans = ctx.get(name)
        if (ans.isEmpty)
          throw new RuntimeException(error__eval__get_undefined(ctx, name))
        ans.get

      case Node(Tag.Let, Atom(name) :: typ :: value :: Nil, _) =>
        val res = eval(ctx, value)
        ctx.let(name, parseTyp(typ), res)
        res

      case Node(Tag.Set, Atom(name) :: value :: Nil, _) =>
        val res = eval(ctx, value)
        val typ = getTyp(res)
        ctx.set(name, typ, res)
        res

      case Leaf(_, value, _) =>
        value

      case AST.Lambda(_, _) =>
        node

      case Node(Tag.Block, children, _) =>
        var ans: Any = None
        for (child <- children) ans = eval(ctx, child)
        ans

      case Node(Tag.Quote, quoted, _) =>
        quoted

      case Call(callee, _) if callee.isDirective =>
      // do nothing

      case Call(Atom("while"), cond :: AST.Lambda(_, body) :: Nil) =>
        var loop = eval(ctx, cond)
        while (loop == true) {
          ctx.pushEnv()
          eval(ctx, body)
          ctx.popEnv()
          loop = eval(ctx, cond)
        }
        OBJ_VOID

      case Call(Atom("eval"), arg :: Nil) =>
        eval(ctx, arg)

      case Call(Atom(head), rawArgs) =>
        val args = rawArgs.map(eval(ctx, _))
        val typs = Fun(TUP :: args.map(getTyp))
        val lambda = resolveCall(ctx, head, args)
        evalCall(ctx, lambda, args, typs)

      case Call(rawHead, rawArgs) =>
        val head = eval(ctx, rawHead)
        if (!isFun(getTyp(head)))
          throw new RuntimeException("cannot call non-lambda")
        val args = rawArgs.map(arg => eval(ctx, arg))
        val typs = Fun(TUP :: args.map(getTyp))
        evalCall(ctx, head, args, typs)
    }

    ctx.nodeStack.pop()
    ret
  }

  def usageShort: String = {
    s"vc [-h|-H] FILE..."
  }

  def usageLong: String = {
    s"""
       | NAME
       |    vc - execute VitaminC code
       |
       | USAGE
       |    vc [-h|-H] FILE...
       |
       | DESCRIPTION
       |    -h, --help
       |        print usage
       |
       |    -H, --HELP
       |        print this help
       |
       | EXAMPLE
       |    vc stdlib.vc main.vc
       |
       | NOTES
       |    FILEs are evaluated in the order they're given
       |    (in fact the ASTs in FILEs are concatenated)
     """.stripMargin
  }

  case class Arguments(
    files: List[String]
  )

  def parseArgs(input: List[String]): Arguments = {
    var args = input
    var files = List[String]()

    while (args.nonEmpty) {
      val head = args.head
      head match {
        case "-h" | "--help" =>
          println(s"usage: $usageShort")
          exit(0)
        case "-H" | "--HELP" =>
          println(usageLong)
          exit(0)
        case _ =>
          files :+= head
          args = args.drop(1)
      }
    }

    Arguments(
      files = files
    )
  }

  def verifyArgs(args: Arguments): Unit = {
    args.files foreach verifyFile

    if (args.files.isEmpty) {
      printError(s"no files given")
      exit(1)
    }
  }

  def printError(str: String): Unit = {
    eprintln(s"[error] $str")
  }

  def printWarn(str: String): Unit = {
    println(s"[warn] $str")
  }

  def verifyFile(it: String): Unit = {
    val path = Paths.get(it)
    val file = path.toFile
    if (!file.exists) {
      printError(s"file '$it' doesn't exist")
      exit(1)
    }
    if (file.isDirectory) {
      printError(s"file '$it' is a directory, which is not allowed yet")
      exit(1)
    }
    if (!it.endsWith(".vc")) {
      printWarn(s"extension of file '$it' is not '.vc'")
    }
  }

  def evalFile(ctx: Ctx, file: String): Unit = {
    ctx.fileStack.push(file)

    // 1. parse with the generic parser
    var ast: Tree = Parser.parseFile(file)

    // 1. parse with context's parser
    ast = parseExpressions(ctx, ast)
    //println("-- PARSE FLAT ------------------------------")
    //program.child.foreach(x => println(repr(x)))

    // 2. expand macros
    ast = expandMacros(ctx, ast)
    //println("-- EXPAND MACRO ---------------------------")
    //ast.child.foreach(x => println(repr(x)))

    // 3. run interpreter
    //println("-- EVAL PROGRAM ----------------------------")
    try {
      eval(ctx, ast)
    } catch {
      case e: RuntimeException =>
        println(e.message)
    }

    ctx.fileStack.pop()
  }

  def evalFiles(files: List[String]): Unit = {
    // 0. Create the world
    val ctx = new Ctx()
    ctx.parser = PrattTools.makeParser(ctx, List())
    Corelib.register(ctx)

    files foreach { file => evalFile(ctx, file) }
  }

  def main(args: Array[String]): Unit = {
    var args2 = args.toList
    if (args2.isEmpty)
      args2 = "res/stdlib.vc" :: "res/calc.vc" :: Nil
    val arguments = parseArgs(args2)
    verifyArgs(arguments)
    evalFiles(arguments.files)
  }

}
