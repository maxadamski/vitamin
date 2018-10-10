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

class Env(
  var opGroups: Map[String, OpGroup] = Map(),
  var opNames: Set[OpName] = Set(),
  var parent: Option[Env] = None,
  var vars: mutable.Map[String, Any] = mutable.Map(),
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
    if (oldEnv.parent.isEmpty) throw new Exception()
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

  def let(name: String, value: Any): Unit = {
    if (env.vars.contains(name))
      throw new RuntimeException(error__eval__let_defined(this, name))
    env.vars.put(name, value)
  }

  def set(name: String, value: Any): Unit = lookup(name) match {
    case Some(dst) => dst.vars(name) = value
    case None =>
      throw new RuntimeException(error__eval__set_undefined(this, name))
  }

  def get(name: String): Option[Any] = lookup(name).map(dst => dst.vars(name))

  def mangleTyp(typ: AType): String = typ match {
    case fun: Fun => fun.toList.dropRight(1).map(mangleTyp).mkString("->")
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
        ctx.let(name, res)
        res

      case Node(Tag.Set, Atom(name) :: value :: Nil, _) =>
        val res = eval(ctx, value)
        ctx.set(name, res)
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

      case Call(Atom("if"), cond :: onT :: onF :: Nil) =>
        (eval(ctx, cond), onT, onF) match {
          case (cond: Boolean, t: Tree, f: Tree) =>
            return if (cond) eval(ctx, t) else eval(ctx, f)
          case _ =>
            throw new RuntimeException(error__type__call_mismatch(
              ctx, "if", Array("Bool", "AST", "AST"), Array()))
        }

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

      case Call(head, tail) =>
        val arg = tail.map {
          case Node(Tag.Arg, value :: name :: Nil, _) =>
            // TODO: respect keywords
            eval(ctx, value)
          case expr =>
            eval(ctx, expr)
        }
        val typ = mkFun(arg.map(getTyp) :+ VOID: _*)
        val sig = if (head.toString.startsWith("(")) "lambda" else head.toString

        val lambda = head match {
          case Atom(name) =>
            val key = ctx.mangleFun(name, arg.length, typ)
            val fun1 = ctx.get(key)
            val fun2 = ctx.get(name)

            if (fun1.isEmpty && fun2.isEmpty)
              // TODO: calling an undefined function (more specific message)
              throw new RuntimeException(error__eval__get_undefined(ctx, key))

            if (fun1.isDefined) fun1.get else fun2.get

          case _ =>
            eval(ctx, head)
        }

        lambda match {
          case AST.Lambda(Node(Tag.TupMatch, par, _), body) =>
            ctx.pushEnv()
            // set environment name for nice stack traces
            ctx.env.name = sig
            // get parameter names
            val names = par.map { case Node(Tag.VarMatch, Atom(name) :: Nil, _) => name }
            // define arguments
            for ((k, v) <- names zip arg) ctx.let(k, v)
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

          case _ =>
            throw new Exception("cannot call non lambda!")
        }

      case ast =>
        throw new Exception("cannot evaluate " + ast.toString)
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
