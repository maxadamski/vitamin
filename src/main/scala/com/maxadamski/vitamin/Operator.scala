package com.maxadamski.vitamin

import Fixity.Fixity
import Assoc.Assoc
import AST._

import scala.annotation.tailrec
import scala.collection.mutable
import scala.collection.mutable.ArrayBuffer

object Fixity extends Enumeration {
  type Fixity = Value
  val Prefix, Suffix, Infix, LeftChain, NullChain = Value
}

object Assoc extends Enumeration {
  type Assoc = Value
  val Left, Right, None = Value
}

object OpUtils {
  def topologicalSort(graph: Map[String, Iterable[String]]): Iterable[String] = {
    val status = mutable.Map[String, String]()
    graph.keys foreach { status.put(_, "") }
    var result = ArrayBuffer[String]()

    def visit(node: String): Unit = {
      if (status(node) == "temp") throw new Exception("Not a DAG!")
      if (status(node) == "done") return
      status(node) = "temp"
      graph(node) foreach visit
      status(node) = "done"
      result +:= node
    }

    for (node <- graph.keys) {
      if (status(node) == "") visit(node)
    }

    result
  }


  def opKind(kind: String): (Fixity, Assoc) = kind match {
    case "xfx" => (Fixity.Infix, Assoc.None)
    case "xfy" => (Fixity.Infix, Assoc.Right)
    case "yfx" => (Fixity.Infix, Assoc.Left)
    case "fx" => (Fixity.Prefix, Assoc.None)
    case "fy" => (Fixity.Prefix, Assoc.Right)
    case "xf" => (Fixity.Suffix, Assoc.None)
    case "yf" => (Fixity.Suffix, Assoc.Left)
    case _ => throw new Exception("Unknown parser kind")
  }

  def mkGroup(name: String, kind: String, gt: Option[String], lt: Option[String]): OpGroup = {
    val (fix, ass) = opKind(kind)
    OpGroup(name, fix, ass, gt, lt)
  }

  def sortedGroups(groups: Map[String, OpGroup]): Seq[String] = {
    val graph = mutable.Map[String, ArrayBuffer[String]]()
    groups.keys foreach { key => graph.put(key, ArrayBuffer[String]()) }
    for (group <- groups.values) {
      // error if referring to unknown group
      if (group.gt.isDefined) graph(group.gt.get) :+= group.name
      if (group.lt.isDefined) graph(group.name) :+= group.lt.get
    }
    topologicalSort(graph.toMap).toSeq
  }

  def updateGroups(groups: Map[String, OpGroup]): Map[String, OpGroup] = {
    val order = sortedGroups(groups)
    order.zipWithIndex.map { case (group, i) =>
      group -> groups(group).copy(prec = i + 1)
    }.toMap
  }

  def mkOps(names: Set[OpName], groups: Map[String, OpGroup]): List[Op] = {
    names.flatMap { name =>
      if (groups.contains(name.group)) {
        val group = groups(name.group)
        Some(Op(name.name, group.prec, group.fix, group.ass))
      } else {
        // warn that operator was not created
        println(s"operator $name not created")
        None
      }
    }.toList
  }

  def getArgs(params: Seq[Param], given: Seq[Arg]): Seq[Tree] = {
    // FIXME?
    val args = Array.ofDim[Tree](params.length)
    val keys = params.map(_.key)
    val list = params.last.list
    var startedKeys = false
    var listArgs = List[Tree]()

    given.zipWithIndex foreach { case (arg, i) =>
      arg.key match {
        case Some(name) =>
          val pos = keys.indexOf(name)
          if (pos == -1) throw new Exception("unknown named argument")
          args(pos) = arg.value
          startedKeys = true
        case None =>
          if (startedKeys || i >= params.length - 1)
            if (list)
              listArgs :+= arg.value
            else
              throw new Exception("unamed arguments must precede named arguments")
          else
            args(i) = arg.value
      }
    }

    if (list)
      args(args.length - 1) = Node(Tag.Array, listArgs)

    args.zipWithIndex foreach {
      case (null, i) =>
        if (params(i).default.isEmpty)
          throw new Exception("required argument was ommited")
        args(i) = params(i).default.get
      case _ =>
    }

    args
  }
}

case class OpGroup(
  name: String, fix: Fixity, ass: Assoc,
  gt: Option[String], lt: Option[String],
  prec: Int = -1)

case class OpName(group: String, name: String)

case class Op(name: String, prec: Int, fix: Fixity, ass: Assoc)

case class Arg(key: Option[String], value: Tree)

case class Param(key: String, default: Option[Tree] = None, list: Boolean = false)


object Functions {

  sealed trait AFunction

  case class Lambda(typ: Types.Fun, param: List[String], body: Tree) extends AFunction
  case class Builtin(typ: Types.Fun, body: List[Any] => Any) extends AFunction

}


object Types {

  sealed trait AType

  case class Typ(x: String) extends AType {
    override def toString: String = x
  }

  case class Var(x: String) extends AType {
    override def toString: String = "'" + x
  }

  case class Fun(x: AType, y: AType) extends AType {
    override def toString: String = s"$x -> $y"

    def toList: List[AType] = (x, y) match {
      case (_, f: Fun) => x +: f.toList
      case _ => List(x, y)
    }
  }

  def mkFun(arg: AType*): Fun = arg match {
    case Seq() => Fun(VOID, VOID)
    case Seq(one) => Fun(one, VOID)
    case Seq(one, two) => Fun(one, two)
    case head +: tail => Fun(head, mkFun(tail: _*))
  }


  def arity(fun: AType): Int = {
    @tailrec
    def go(typ: AType, sum: Int): Int = typ match {
      case Fun(VOID, y) => go(y, sum)
      case Fun(_, y) => go(y, sum + 1)
      case _ => sum
    }
    go(fun, 0)
  }

  val VOID = Typ("Void")
  val TYPE = Typ("Type")
  val ANY = Typ("Any")
  val NIL = Typ("Nothing")
  val STR = Typ("Str")
  val INT = Typ("Int")
  val I64 = Typ("I64")
  val REAL = Typ("Real")
  val BOOL = Typ("Bool")
  val EXPR = Typ("Expr")

  object OBJ_NIL
  object OBJ_VOID

}

