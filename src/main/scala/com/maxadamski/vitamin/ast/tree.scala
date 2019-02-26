package com.maxadamski.vitamin.ast

import com.maxadamski.vitamin.parser.{PrattCall, PrattParser, PrattTokenizable, Token}

case class Span(start: Int, stop: Int)

case class Rule(text: String, line: Int, char: Int, span: Span)

sealed trait Tree extends PrattTokenizable {
  var rule: Option[Rule] = None
  val atom: Boolean = false
  var escaped: Boolean = false

  def depth: Int = 0

  def sexpr(pretty: Boolean, level: Int = 0): String

  override def toString: String = sexpr(pretty = true)

  def cons(other: Tree): Tree
}

case class Atom(var value: String) extends Tree {
  override val atom: Boolean = true

  def isFunctor(ops: List[String]): Boolean = !escaped && ops.contains(value)

  def encodePratt(ops: List[String]): List[Token] = Nil

  def sexpr(pretty: Boolean, level: Int = 0): String = {
    import scala.reflect.runtime.universe._
    if (value.isEmpty) return "''"
    //if (value.matches("[^#@A-Za-z0-9!?]+")) return "'" + value + "'"
    if (value.matches("\\s+")) return "'" + value + "'"
    Literal(Constant(value)).toString.stripPrefix("\"").stripSuffix("\"")
  }

  def cons(other: Tree): Tree = other match {
    case Term(tail) => Term(this :: tail)
    case atom: Atom => Term(this :: atom :: Nil)
  }
}

case class Term(var value: List[Tree]) extends Tree {
  override def depth: Int = value.map(x => x.depth).max

  def isFunctor(ops: List[String]): Boolean = false

  def encodePratt(ops: List[String]): List[Token] = value.tail map {
    case it@Atom(name) if it.isFunctor(ops) => Token(name, it)
    case it => Token(PrattParser.LIT, it)
  }

  def sexpr(pretty: Boolean, level: Int = 0): String = {
    val ugly = value.map(_.sexpr(pretty = false)).mkString("(", " ", ")")
    if (!pretty || ugly.length < 80) return ugly
    val ind = "\n" + "\t" * level
    val head = value.head.sexpr(pretty, level + 1)
    value.tail.map(_.sexpr(pretty, level + 1)).mkString(s"($head$ind\t", s"$ind\t", s"$ind)")
  }

  def cons(other: Tree): Tree = other match {
    case Term(Nil) => this
    case Term(tail) => Term(this :: tail)
  }
}

object PrattDecoder {
  def decode(call: PrattCall): Tree = call match {
    case PrattCall(head, Nil) =>
      call.head.value.asInstanceOf[Tree]
    case PrattCall(head, tail) =>
      val callee = call.head.value.asInstanceOf[Tree]
      val args = call.tail.map(decode)
      Term(callee :: args)
  }
}

object Term {
  val BLOCK = Atom("block")
  val QUOTE = Atom("quote")
  val PARSE = Atom("parse")
  val LAMBDA = Atom("lambda")
  val NUMBER = Atom("number")
  val STRING = Atom("string")
  val TRUE = Atom("true")
  val FALSE = Atom("false")
  val TUPLE = Atom(",")
  val NIL = Atom("nil")
  val FUN = Atom("fun")
  val DEF = Atom("def")
  val LET = Atom("let!")
  val SET = Atom("set!")
  val IF = Atom("if")
  val WHILE = Atom("while")
  val FOR = Atom("for")
  val USE = Atom("use")
}
