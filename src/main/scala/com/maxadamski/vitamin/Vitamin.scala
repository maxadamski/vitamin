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
  var nodeStack: mutable.Stack[Syntax] = mutable.Stack(),
  var parser: PrattParser = null,
) {

  def node: Syntax = nodeStack.top

  def file: String = fileStack.top

  def pushEnv(): Unit = {
    val newEnv = new Env(parent = Some(env))
    env = newEnv
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

  def get(name: String): Any = lookup(name) match {
    case Some(dst) => dst.vars(name)
    case None =>
      throw new RuntimeException(error__eval__get_undefined(this, name))
  }

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
    case _: Double => REAL
    case _: String => STR
    case Lambda(typ, _, _) => typ
    case Builtin(typ, _) => typ
    case _ => ANY
  }

  def parseExpressions(ctx: Ctx, ast: Node): Node = {
    val res: Syntax = if (ast.tag == Tag.Flat) {
      try {
        ctx.parser.parse(ast)
      } catch {
        case e: ParserException =>
          println(e.message)
          ast
      }
    } else {
      parseExpressions()
    }

    if (res != ast) {
      res match {
        case Node(Tag.Call, Atom(name) +: arg) =>
          val arg2 = arg.map {
            case Node(Tag.Arg, value + Atom(name)) =>
              Arg(Some(key), value)
            case value =>
              Arg(None, value)
          }
          runPragma(ctx, name, arg2)

        case _ =>
      }

    res
  }

  def runPragma(ctx: Ctx, name: String, arg: List[Arg]): Unit = {
    name match {
      case "operatorgroup" =>
        val nil = Some(Atom("nil"))
        val defn = Seq(Param("name"), Param("kind"), Param("gt", nil), Param("lt", nil))
        val args = getArgs(defn, arg).map { case Atom(str) => str }
        val gt = if (args(2) != "nil") Some(args(2)) else None
        val lt = if (args(3) != "nil") Some(args(3)) else None
        ctx.env.opGroups += args(0) -> mkGroup(args(0), args(1), gt, lt)
      case "operator" =>
        val defn = Seq(Param("group"), Param("name", list = true))
        val args = getArgs(defn, arg)
        val group = args(0).asInstanceOf[Atom].value
        val names = args(1).asInstanceOf[Node].data.map(_.asInstanceOf[Atom].value)
        for (name <- names) ctx.env.opNames :+= OpName(group, name)
      case "operatorcompile" =>
        ctx.env.opGroups = OpUtils.updateGroups(ctx.env.opGroups)
        val ops = OpUtils.mkOps(ctx.env.opNames, ctx.env.opGroups)
        ctx.parser = PrattTools.makeParser(ctx, ops)
      case _ =>
        println(s"unknown pragma $res")
  }

  def main(args: Array[String]): Unit = {
    val mainFile = "res/main.vc"
    var program: Syntax = Parser.parseFile(mainFile)

    val ctx = new Ctx()
    ctx.parser = PrattTools.makeParser(ctx, List())
    ctx.fileStack.push(mainFile)
    Corelib.register(ctx)


    // 1. parse expressions
    program = parseExpressions(ctx, program)

    // 2. expand macros
    program = program.map {
      case Call(Atom(":="), arg) =>
        Node(Tag.Let, arg)
      case Call(Atom("="), Atom(name) :: tail) =>
        Node(Tag.Set, Quote(Atom(name)) +: tail)
      case Call(Atom("'"), arg) =>
        Node(Tag.Quote, arg)
      case it if it.tag == Tag.Pragma =>
        Leaf(Tag.Null, Nil)
      case it =>
        it
    }

    println(repr(program, multi = true))

    // 3. run interpreter
    def eval(node: Syntax): Any = {
      ctx.nodeStack.push(node)
      val ret = node match {
        case Leaf(_, value) =>
          value

        case _: FunNode =>
          node

        case Block(children) =>
          var last: Any = None
          for (child <- children) last = eval(child)
          last

        case Node(Tag.Let, List(Atom(name), value)) =>
          val res = eval(value)
          ctx.let(name, res)
          res

        case Node(Tag.Set, List(Atom(name), value)) =>
          val res = eval(value)
          ctx.set(name, res)
          res

        case Atom(name) =>
          ctx.get(name)

        case Quote(quoted) =>
          quoted

        case Call(Atom("if"), arg) =>
          val (cond, t, f) = (eval(arg(0)), arg(1), arg(2))
          (cond, t, f) match {
            case (cond: Boolean, t: Syntax, f: Syntax) =>
              return if (cond) eval(t) else eval(f)
            case _ =>
              throw new RuntimeException(error__type__call_mismatch(
                ctx, "if", Array("Bool", "AST", "AST"), Array()))
          }

        case Call(Atom("eval"), List(arg)) =>
          eval(arg)

        case Call(head, tail) =>
          val arg = tail.map(eval)
          val typ = mkFun(arg.map(getTyp) :+ VOID: _*)
          val sig = if (head.toString.startsWith("(")) "lambda" else head.toString

          val lambda = head match {
            case Atom(name) =>
              val key = ctx.mangleFun(name, arg.length, typ)
              ctx.get(key)

            case _ =>
              eval(head)
          }


          lambda match {
            case FunNode(body, ret, par) =>
              ctx.pushEnv()
              // set environment name for nice stack traces
              ctx.env.name = sig
              // get parameter names
              val names = par.map(_.id.value)
              // define arguments
              for ((k, v) <- names zip arg) ctx.let(k, v)
              // evaluate the body and save return value
              val ret = eval(body)
              ctx.popEnv()
              ret

            case Builtin(_, body) =>
              // just pass things to a regular lambda
              body(arg)

            case _ =>
              throw new Exception("cannot call non lambda!")
          }
      }

      ctx.nodeStack.pop()
      ret
    }

    //println(repr(program, multi = true))

    try {
      eval(program)
    } catch {
      case e: RuntimeException =>
        println(e.message)
      case e =>
        e.printStackTrace()
        print(e)
    }

    /*
    val noPragma = nextExcept(it => it.tag == Tag.Pragma)(_)
    val nodes = program.fold[Array[AST]](Array(), foldDFS, nextAll) {
      case (sum, node) if node.tag == Tag.Pragma => sum :+ node
      case (sum, _) => sum
    }
    */
  }

}
