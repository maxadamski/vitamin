package com.maxadamski.vitamin

import ASTUtils._
import OpUtils.{getArgs, mkGroup}

import scala.collection.mutable
import scala.reflect.ClassTag


object Vitamin {

  implicit class Castable[A](val self: A) {
    def as[B](implicit tag: ClassTag[B]): Option[B] = self match {
      case that: B => Some(that)
      case _ => None
    }
  }

  class Env(
    var opGroups: Map[String, OpGroup] = Map(),
    var opNames: Seq[OpName] = Seq(),
    var parent: Option[Env] = None,
    var vars: mutable.Map[String, Any] = mutable.Map(),
    var name: String = "main"
  )

  class Ctx(
    var env: Env = new Env(),
  ) {
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

    def let(name: String, value: Any): Unit = {
      env.vars.put(name, value)
    }

    def set(name: String, value: Any): Unit = {
      val (dst, old) = get(name)
      dst.vars(name) = value
    }

    def get(name: String): (Env, Any) = {
      var local: Option[Env] = Some(env)
      while (local.isDefined) {
        if (local.get.vars.contains(name))
          return (local.get, local.get.vars(name))
        else
          local = local.get.parent
      }
      throw new Exception(s"no variable $name")
    }

  }

  def main(args: Array[String]): Unit = {
    var program: AST = Parser.parseFile("res/main.vc")
    var parser = PrattTools.makeParser(Array[Op]())
    var env = new Env()
    //println(program)

    // 1. parse expressions
    program = program.map() { it =>
      val res = it match {
        case AST(Tag.Flat, _, _) =>
          parser.parse(it)
        case _ =>
          it
      }

      if (res != it) {
        res match {
          case AST(Tag.Pragma, Node(AST(Tag.Atom, Leaf(name: String), _) +: args), _) =>
            val arguments = args.map {
              case AST(Tag.Arg, Node(Seq(AST(Tag.Atom, Leaf(key: String), _), value)), _) =>
                Arg(Some(key), value)
              case arg =>
                Arg(None, arg)
            }.toSeq


            name match {
              case "operatorgroup" =>
                val nil = Some(AST(Tag.Atom, Leaf("nil")))
                val defn = Seq(Param("name"), Param("kind"), Param("gt", nil), Param("lt", nil))
                val args = getArgs(defn, arguments).map(_.data.asInstanceOf[Leaf].data.asInstanceOf[String])
                val gt = if (args(2) != "nil") Some(args(2)) else None
                val lt = if (args(3) != "nil") Some(args(3)) else None
                env.opGroups += args(0) -> mkGroup(args(0), args(1), gt, lt)
              case "operator" =>
                val defn = Seq(Param("group"), Param("name", list = true))
                val args = getArgs(defn, arguments)
                val group = args(0).data.asInstanceOf[Leaf].data.asInstanceOf[String]
                val names = args(1).data.asInstanceOf[Node].data.map { name =>
                  name.data.asInstanceOf[Leaf].data.asInstanceOf[String]
                }
                for (name <- names) {
                  env.opNames :+= OpName(group, name)
                }
              case "operatorcompile" =>
                env.opGroups = OpUtils.updateGroups(env.opGroups)
                val ops = OpUtils.mkOps(env.opNames, env.opGroups)
                parser = PrattTools.makeParser(ops)
              case _ =>
                println(s"unknown pragma $res")
            }

          case _ =>
        }
      }

      res
    }

    def mkAtom(value: String): AST =
      AST(Tag.Atom, Leaf(value))

    def mkCall(func: AST, args: AST*): AST =
      AST(Tag.Call, Node(func +: args.toArray))

    def mkNode(args: AST*): Node = Node(args)

    def mkBlock(args: AST*): AST = AST(Tag.Block, Node(args))

    def mkLet(name: String, arg: AST): AST =
      AST(Tag.Let, mkNode(AST(Tag.Quote, Leaf(name)), arg))

    def mkNull: AST = AST(Tag.Null, Leaf(null))

    def mkQuote(arg: AST): AST = AST(Tag.Quote, mkNode(arg))

    def exIf(it: AST): AST = it match {
      case AST(Tag.Call, Node(AST(Tag.Atom, Leaf(op), _) +: args), _) =>
        val quoted = args.toList
        AST(Tag.Call, mkNode(mkAtom("if") +: quoted: _*))
      case _ => throw new Exception()
    }

    def mkCall2(key: String, values: AST*): AST = mkCall(mkAtom(key), values:_*)

    // 2. expand macros
    program = program.map(next = {
      case it@AST(Tag.Call, Node(AST(Tag.Arg, Node(_ :+ AST(Tag.Atom, Leaf("'"), _)), _) +: _), _) =>
        List()
      case it =>
        it.child.toList

    }) {
      case it@AST(Tag.Call, Node(AST(Tag.Atom, Leaf(op), _) +: args), _) =>
        (op, args) match {
          case (":=", AST(Tag.Atom, Leaf(name), _) +: tail) =>
            AST(Tag.Let, mkNode(AST(Tag.Quote, Leaf(name)) +: tail.toList: _*))
          case ("=", AST(Tag.Atom, Leaf(name), _) +: tail) =>
            AST(Tag.Set, mkNode(AST(Tag.Quote, Leaf(name)) +: tail.toList: _*))
          case ("'", Seq(arg: AST)) =>
            AST(Tag.Quote, mkNode(arg))
          case ("if", args) =>
            //val quoted = args.map(mkQuote).toList
            //AST(Tag.Call, mkNode(mkAtom("if") +: quoted: _*))
            exIf(it)
          case ("while", Seq(cond: AST, AST(Tag.Lambda, Node(Seq(AST(Tag.Block, Node(body), _))), _))) =>
            val call = AST(Tag.Call, mkNode(mkAtom("if"), cond, mkBlock(
              body.toSeq :+ mkCall2("while"): _*
            ), mkAtom("()")))

            AST(Tag.Call, mkNode(
              AST(Tag.Lambda, mkNode(mkBlock(
                mkLet("while",
                  AST(Tag.Lambda, mkNode(mkBlock(
                    call
                  )))
                ),
                mkCall2("while")
              ))))
            )
          case _ => it
        }

      case it@AST(Tag.Call, Node(AST(Tag.Arg, Node(_ :+ AST(Tag.Atom, Leaf("'"), _)), _) +: _), _) =>
        it
      case AST(Tag.Pragma, _, _) =>
        mkNull
      case it =>
        it
    }


    val builtins = Seq("+", "*", "-", "=", "==", ">", "printr", "newline", "if", "eval")
    val ctx = new Ctx(env = env)
    ctx.let("true", true)
    ctx.let("false", false)
    ctx.let("()", false)

    // 3. run interpreter
    def eval(node: AST): Any = node match {
      case AST(Tag.Block, Node(children), _) =>
        var last: Any = None
        for (child <- children) {
          last = eval(child)
        }
        last
      case AST(Tag.Let, Node(Seq(AST(_, Leaf(name: String), _), value)), _) =>
        val res = eval(value)
        ctx.let(name, res)
        res
      case AST(Tag.Set, Node(Seq(AST(_, Leaf(name: String), _), value)), _) =>
        val res = eval(value)
        ctx.set(name, res)
        res
      case AST(Tag.Atom, Leaf(name: String), _) =>
        val (env, res) = ctx.get(name)
        res
      case AST(Tag.Quote, Node(Seq(quoted)), _) =>
        quoted
      case AST(Tag.Call, Node(AST(Tag.Atom, Leaf(name: String), _) +: args), _)
        if builtins contains name =>
        if (name == "if") {
          val arg = args.toList
          val cond = eval(arg(0))
          if (!cond.isInstanceOf[Boolean])
            throw new Exception()
          return if (cond.asInstanceOf[Boolean]) eval(arg(1)) else eval(arg(2))
        }

        val arg = (args map eval).toList
        name match {
          case "+" =>
            if (!(arg(0).isInstanceOf[Int] && arg(1).isInstanceOf[Int])) throw new Exception()
            arg(0).asInstanceOf[Int] + arg(1).asInstanceOf[Int]
          case "-" =>
            if (!(arg(0).isInstanceOf[Int] && arg(1).isInstanceOf[Int])) throw new Exception()
            arg(0).asInstanceOf[Int] - arg(1).asInstanceOf[Int]
          case "*" =>
            if (!(arg(0).isInstanceOf[Int] && arg(1).isInstanceOf[Int])) throw new Exception()
            arg(0).asInstanceOf[Int] * arg(1).asInstanceOf[Int]
          case "printr" =>
            print(arg(0).toString)
          case "==" =>
            arg(0) == arg(1)
          case ">" =>
            arg(0).asInstanceOf[Int] > arg(1).asInstanceOf[Int]
          case "newline" =>
            println()
          case "eval" =>
            if (!arg(0).isInstanceOf[AST])
              throw new Exception()
            eval(arg(0).asInstanceOf[AST])
        }
      case AST(Tag.Call, Node((head: AST) +: args), _) =>
        val lambda = eval(head)
        val arg = (args map eval).toList
        lambda match {
          case AST(Tag.Lambda, Node(body), _) if body.toList.length == 1 =>
            ctx.pushEnv()
            ctx.env.name = head.toString
            if (ctx.env.name.startsWith("(")) ctx.env.name = "lambda"
            val ret = eval(body.toList(0))
            ctx.popEnv()
            ret

          case AST(Tag.Lambda, Node(kids), _) if kids.toList.length > 1 =>
            val body = kids.last
            val param = kids.dropRight(1)
            ctx.pushEnv()
            ctx.env.name = head.toString
            if (ctx.env.name.startsWith("(")) ctx.env.name = "lambda"
            val par = param.map { it => it.data.asInstanceOf[Leaf].data.asInstanceOf[String] }
            (par zip arg) foreach { case (k, v) => ctx.let(k, v) }
            val ret = eval(body)
            ctx.popEnv()
            ret

          case _ =>
            throw new Exception("cannot call non lambda!")
        }

      case it@AST(Tag.Lambda, _, _) =>
        it

      case AST(_, Leaf(value), _) =>
        value


    }


    //println(repr(program, multi = true))
    eval(program)

    /*
    val noPragma = nextExcept(it => it.tag == Tag.Pragma)(_)
    val nodes = program.fold[Array[AST]](Array(), foldDFS, nextAll) {
      case (sum, node) if node.tag == Tag.Pragma => sum :+ node
      case (sum, _) => sum
    }
    */
  }

}
