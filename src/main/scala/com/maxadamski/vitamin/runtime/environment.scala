package com.maxadamski.vitamin.runtime

import com.maxadamski.vitamin.Result

import scala.collection.mutable.{Map => MutableMap}
import com.maxadamski.vitamin.ast.{Atom, Term, Tree}
import com.maxadamski.vitamin.parser2.{Error, OpGroup, OpName, OpUtils, Operator, PrattFunctions, PrattParser}
import com.maxadamski.vitamin.runtime.Core.DynamicIL
import com.maxadamski.vitamin.runtime.TypeSystem.Poly

case class Macro(params: List[String], body: Tree, env: Env)

case class Lambda(params: List[String], body: Core.DynamicIL.Form, env: Env)

sealed trait Sig

case class TypSig(typ: TypeSystem.Poly)

case class FunSig(typ: TypeSystem.Poly, args: Array[String]) {
  val arity = args.length
}

class Env {
  var file: String = ""
  var parent: Option[Env] = None
  var node: Tree = Term(Nil)
  var parser: ParserContext = ParserContext()
  var variables: MutableMap[String, Any] = MutableMap()
  var typeOf: MutableMap[String, Poly] = MutableMap()
  var kindOf: MutableMap[String, Int] = MutableMap()
  var macros: MutableMap[String, Macro] = MutableMap()
  var currentVars: MutableMap[String, Poly] = MutableMap()

  def findVariable(key: String): Option[Env] =
    if (variables contains key) Some(this) else parent.flatMap(it => it.findVariable(key))

  def findTypeOf(key: String): Option[Env] =
    if (typeOf contains key) Some(this) else parent.flatMap(it => it.findTypeOf(key))

  def findKindOf(key: String): Option[Env] =
    if (kindOf contains key) Some(this) else parent.flatMap(it => it.findKindOf(key))

  def findMacro(key: String): Option[Env] =
    if (macros contains key) Some(this) else parent.flatMap(it => it.findMacro(key))

  def extend(): Env = {
    val env = new Env()
    env.parent = Some(this)
    env.parser = parser
    env.file = file
    env
  }
}

case class ParserContext() {
  var operators: List[Operator] = Nil
  var opGroups: Map[String, OpGroup] = Map()
  var opNames: Set[OpName] = Set()
  var parser: PrattParser = PrattParser.makeParser(Nil)
  updateParser()

  def parse(tree: Tree): Result[Error, Tree] = parser.parse(tree)

  def addGroup(group: OpGroup): Unit = opGroups += group.name -> group

  def addName(group: OpName): Unit = opNames += group

  def addMix(rbp: Int, name: String, pattern: Array[String]): Unit = {
    val isLeft = pattern(0) == "_" || pattern(0) == "_!"
    if (isLeft) {
      val nonass = pattern(0) == "_!"
      val first = pattern(1)
      val nbp = if (nonass) rbp - 1 else rbp
      val fun = PrattParser.makeLeft(first, PrattFunctions.leftMix(name, pattern, rbp), rbp, rbp, nbp = Some(nbp))
      parser.led += fun
    } else {
      val first = pattern(0)
      val fun = PrattParser.makeNull(first, PrattFunctions.nullMix(name, pattern, rbp), rbp)
      parser.nud += fun
    }
  }

  def updateParser(): Unit = {
    //operators = OpUtils.mkOps(opNames, OpUtils.updateGroups(opGroups))
    //parser = PrattParser.makeParser(operators)
  }
}
