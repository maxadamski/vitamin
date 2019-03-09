package com.maxadamski.vitamin.ast

import com.maxadamski.vitamin.lexer.Span

sealed trait Tree {
  var span: Option[Span] = None
  val atom: Boolean = false
  var escaped: Boolean = false
  var isBlock = false

  def depth: Int = 0

  def sexpr(pretty: Boolean, level: Int = 0): String

  override def toString: String = sexpr(pretty = true)

  def cons(other: Tree): Tree

  def compSpan: Option[Span] = this match {
    case it: Atom => it.span
    case it: Term =>
      it.value match {
        case Nil =>
          None
        case x =>
          (x.head.span, x.last.span) match {
            case (Some(beg), Some(end)) =>
              Some(Span(beg.a, end.b))
            case (beg, None) =>
              beg
            case (None, end) =>
              end
          }
      }
  }
}

case class Atom(var value: String) extends Tree {
  override val atom: Boolean = true

  def sexpr(pretty: Boolean, level: Int = 0): String = {
    import scala.reflect.runtime.universe._
    if (value.isEmpty) return "''"
    if ("[ \t]".r.findFirstMatchIn(value).nonEmpty) return "'" + value + "'"
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
