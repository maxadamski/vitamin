package com.maxadamski.vitamin.parser

import collection.mutable.{Map => MutableMap}

import Fixity.Fixity
import Associativity.Associativity

case class OpGroup(
  name: String, fix: Fixity, ass: Associativity,
  gt: Option[String], lt: Option[String],
  precedence: Int = -1
)

case class OpName(group: String, name: String)

object OpUtils {
  def topologicalSort(graph: Map[String, List[String]]): List[String] = {
    var status = MutableMap[String, String]()
    graph.keys foreach { key => status += key -> "" }
    var result = List[String]()

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

  def sortedGroups(groups: Map[String, OpGroup]): List[String] = {
    var graph = MutableMap[String, List[String]]()
    groups.keys foreach { key => graph += key -> Nil }
    for (group <- groups.values) {
      // error if referring to unknown group
      if (group.gt.isDefined) graph(group.gt.get) :+= group.name
      if (group.lt.isDefined) graph(group.name) :+= group.lt.get
    }
    topologicalSort(graph.toMap)
  }

  def updateGroups(groups: Map[String, OpGroup]): Map[String, OpGroup] = {
    val order = sortedGroups(groups)
    order.zipWithIndex.map { case (group, i) =>
      group -> groups(group).copy(precedence = i + 1)
    }.toMap
  }

  def mkOps(names: Set[OpName], groups: Map[String, OpGroup]): List[Operator] = {
    names.flatMap { name =>
      if (groups.contains(name.group)) {
        val group = groups(name.group)
        Some(Operator(name.name, group.precedence, group.fix, group.ass))
      } else {
        // warn that operator was not created
        println(s"operator $name not created")
        None
      }
    }.toList
  }

  // this should be a library function
  def opKind(kind: String): (Fixity, Associativity) = kind match {
    case "xfxfx" => (Fixity.LeftChain, Associativity.None)
    case "fxfx" => (Fixity.NullMix, Associativity.None)
    case "xfx" => (Fixity.Infix, Associativity.None)
    case "xfy" => (Fixity.Infix, Associativity.Right)
    case "yfx" => (Fixity.Infix, Associativity.Left)
    case "fx" => (Fixity.Prefix, Associativity.None)
    case "fy" => (Fixity.Prefix, Associativity.Right)
    case "xf" => (Fixity.Suffix, Associativity.None)
    case "yf" => (Fixity.Suffix, Associativity.Left)
    case _ => throw new Exception("Unknown parser kind")
  }
}
