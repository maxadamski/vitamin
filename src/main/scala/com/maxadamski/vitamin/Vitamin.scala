package com.maxadamski.vitamin

import OpUtils.{getArgs, mkGroup}
import ASTUtils._
import Report._
import Functions._
import Types._

import scala.collection.mutable
import scala.reflect.ClassTag

class Env(
  var opGroups: Map[String, OpGroup] = Map(),
  var opNames: List[OpName] = List(),
  var parent: Option[Env] = None,
  var vars: mutable.Map[String, Any] = mutable.Map(),
  var name: String = "main"
)

class Ctx(
  var env: Env = new Env(),
  var fileStack: mutable.Stack[String] = mutable.Stack(),
  var nodeStack: mutable.Stack[AST] = mutable.Stack(),
  var parser: PrattParser = null,
) {

  def node: AST = nodeStack.top

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
    case Lambda(typ, _, _) => typ
    case Builtin(typ, _) => typ
    case _ => ANY
  }

  def parseExpressions(ctx: Ctx, ast: AST): AST = ast.map() { it =>
    val res = it match {
      case Term(Tag.Flat, _) => parsedAST(ctx, it)
      case _ => it
    }

    res match {
      case Term(Tag.Pragma, Atom(name) :: arg) => runPragma(ctx, name, pragmaArg(arg))
      case _ =>
    }

    res
  }

  def expandMacros(ctx: Ctx, ast: AST): AST = ast.map() {
    case Term(Tag.Call, Atom(":=") :: arg) =>
      Term(Tag.Let, arg)
    case Term(Tag.Call, Atom("=") :: Atom(name) :: tail) =>
      Term(Tag.Set, Atom(name) :: tail)
    case Term(Tag.Call, Atom("'") :: arg) =>
      Term(Tag.Quote, arg)
    case Term(Tag.Pragma, _) =>
      Zero
    case it =>
      it
  }

  def parsedAST(ctx: Ctx, ast: AST): AST = {
    try {
      ctx.parser.parse(ast)
    } catch {
      case e: ParserException =>
        println(e.message)
        ast
    }
  }

  def pragmaArg(arg: List[AST]): List[Arg] = arg.map {
    case Term(Tag.Arg, value :: Atom(key) :: Nil) => Arg(Some(key), value)
    case Term(Tag.Arg, value :: Zero :: Nil) => Arg(None, value)
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
      val group = args(0).asInstanceOf[Atom].value
      val names = args(1).asInstanceOf[Term].data.map(_.asInstanceOf[Atom].value)
      for (name <- names) ctx.env.opNames :+= OpName(group, name)
    case "operatorcompile" =>
      ctx.env.opGroups = OpUtils.updateGroups(ctx.env.opGroups)
      val ops = OpUtils.mkOps(ctx.env.opNames, ctx.env.opGroups)
      ctx.parser = PrattTools.makeParser(ctx, ops)
    case pragma =>
      println(s"unknown pragma $pragma")
  }

  def eval(ctx: Ctx, node: AST): Any = {
    ctx.nodeStack.push(node)
    val ret = node match {
      case Zero =>
        OBJ_VOID

      case Leaf(_, value) =>
        value

      case Term(Tag.Lambda, _) =>
        node

      case Term(Tag.Block, children) =>
        var ans: Any = None
        for (child <- children) ans = eval(ctx, child)
        ans

      case Term(Tag.Let, Atom(name) :: value :: Nil) =>
        val res = eval(ctx, value)
        ctx.let(name, res)
        res

      case Term(Tag.Set, Atom(name) :: value :: Nil) =>
        val res = eval(ctx, value)
        ctx.set(name, res)
        res

      case Atom(name) =>
        val ans = ctx.get(name)
        if (ans.isEmpty)
          throw new RuntimeException(error__eval__get_undefined(ctx, name))
        ans.get

      case Term(Tag.Quote, quoted) =>
        quoted

      case Term(Tag.Call, Atom("if") :: cond :: onT :: onF :: Nil) =>
        (eval(ctx, cond), onT, onF) match {
          case (cond: Boolean, t: AST, f: AST) =>
            return if (cond) eval(ctx, t) else eval(ctx, f)
          case _ =>
            throw new RuntimeException(error__type__call_mismatch(
              ctx, "if", Array("Bool", "AST", "AST"), Array()))
        }

      case Term(Tag.Call, Atom("while") :: cond :: Term(Tag.Lambda, body :: _) :: Nil) =>
        var loop = eval(ctx, cond)

        while (loop == true) {
          ctx.pushEnv()
          eval(ctx, body)
          ctx.popEnv()
          loop = eval(ctx, cond)
        }

        OBJ_VOID

      case Term(Tag.Call, Atom("eval") :: arg :: Nil) =>
        eval(ctx, arg)

      case Term(Tag.Call, head :: tail) =>
        val arg = tail.map {
          case Term(Tag.Arg, value :: name :: Nil) =>
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
          case Term(Tag.Lambda, body :: ret :: par) =>
            ctx.pushEnv()
            // set environment name for nice stack traces
            ctx.env.name = sig
            // get parameter names
            val names = par.map { case Term(Tag.Param, Atom(k) :: _) => k }
            // define arguments
            for ((k, v) <- names zip arg) ctx.let(k, v)
            // evaluate the body and save return value
            val ret = eval(ctx, body)
            ctx.popEnv()
            ret

          case Builtin(_, body) =>
            // just pass things to a regular lambda
            body(arg)

          case _ =>
            throw new Exception("cannot call non lambda!")
        }

      case _ =>
        print("this shouldn't happen")
    }

    ctx.nodeStack.pop()
    ret
  }

  def main(args: Array[String]): Unit = {
    val mainFile = "res/main.vc"
    var program: AST = Parser.parseFile(mainFile)

    val ctx = new Ctx()
    ctx.parser = PrattTools.makeParser(ctx, List())
    ctx.fileStack.push(mainFile)
    Corelib.register(ctx)


    // 1. parse expressions
    program = parseExpressions(ctx, program)
    println("parse flat ------------------------------")
    program.child.foreach(x => println(repr(x)))

    // 2. expand macros
    program = expandMacros(ctx, program)
    println("expand macro ----------------------------")
    program.child.filterNot(_ == Zero).foreach(x => println(repr(x)))

    // 3. run interpreter
    println("eval program ----------------------------")
    try {
      eval(ctx, program)
    } catch {
      case e: RuntimeException =>
        println(e.message)
      case e =>
        e.printStackTrace()
        print(e)
    }

  }

}
