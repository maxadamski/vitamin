package com.maxadamski.vitamin

import Fixity.Fixity
import Assoc.Assoc
import OpUtils._

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

  def mkOps(names: Seq[OpName], groups: Map[String, OpGroup]): Seq[Op] = {
    names.flatMap { name =>
      if (groups.contains(name.group)) {
        val group = groups(name.group)
        Some(Op(name.name, group.prec, group.fix, group.ass))
      } else {
        // warn that operator was not created
        println(s"operator $name not created")
        None
      }
    }
  }

  def getArgs(params: Seq[Param], given: Seq[Arg]): Seq[AST] = {
    // FIXME?
    val args = Array.ofDim[AST](params.length)
    val keys = params.map(_.key)
    val list = params.last.list
    var startedKeys = false
    var listArgs = Array[AST]()

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
      args(args.length - 1) = AST(Tag.Array, Node(listArgs))

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

case class Arg(key: Option[String], value: AST)

case class Param(key: String, default: Option[AST] = None, list: Boolean = false)

case class Lambda(
  param: List[String],
  body: AST,
)