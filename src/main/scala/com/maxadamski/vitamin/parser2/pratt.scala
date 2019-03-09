package com.maxadamski.vitamin.parser2

import util.control.Breaks._
import PrattParser._
import PrattFunctions._
import Reason.Reason
import com.maxadamski.vitamin.ast.{Atom, Term, Tree}
import com.maxadamski.vitamin.lexer.Span
import com.maxadamski.vitamin.{Err, Ok, Result}

import scala.collection.mutable.ArrayBuffer

// TODO: do something about the expr metadata

sealed trait OpComp
case class Name(x: String) extends OpComp
case class Hole() extends OpComp

sealed trait Error
case class UnexpectedEOF(last: Option[Tree]) extends Error
case class BadPrecedenceLeft(curr: Tree, last: Tree) extends Error
case class BadPrecedenceNull(curr: Tree, last: Tree) extends Error
case class UnknownLeft(curr: Tree, last: Option[Tree]) extends Error
case class UnknownNull(curr: Tree, last: Option[Tree]) extends Error
case class BadMix(name: String, expected: Tree, actual: Tree) extends Error
case class PrattError(reason: Reason, curr: Tree, last: Option[Tree]) extends Error

object Reason extends Enumeration {
  type Reason = Value
  val UnexpectedNull, UnexpectedLeft = Value
}
case class NullOp(
                   parse: (PrattParser, Tree) => Result[Error, Tree],
                   rbp: Int, nbp: Int
)

case class LeftOp(
                   parse: (PrattParser, Tree, Tree) => Result[Error, Tree],
                   lbp: Int, rbp: Int, nbp: Int
)

class PrattParser(
  var nud: Map[String, NullOp],
  var led: Map[String, LeftOp]
) {
  var history: List[Tree] = List()
  var tokens: Array[Tree] = Array()
  var len: Int = 0
  var pos: Int = 0
  val NullLiteral = NullOp(literal(0), 10000, 10000)
  val NullError = NullOp(nullError(0), -1, -1)
  val LeftError = LeftOp(leftError(0), -1, -1, -1)

  def parse(tree: Tree): Result[Error, Tree] = tree match {
    case Term(Atom("parse") :: x) => parse(x.toArray)
    case x => Ok(x)
  }

  def parse(tokens: Array[Tree]): Result[Error, Tree] = {
    this.tokens = tokens
    len = tokens.length
    pos = 0
    val res = parseUntil(0)
    res
  }

  def isEmpty: Boolean = pos >= len

  def getLeft(t: Tree): LeftOp = t match {
    case Atom(key) if led contains key => led(key)
    case _ => LeftError
  }

  def getNull(t: Tree): NullOp = t match {
    case Atom(key) if nud contains key => nud(key)
    case _ => NullLiteral
  }

  def getLeftPrec(t: Tree): Int = t match {
    case Atom(key) if led contains key => led(key).lbp
    case _ => 0
  }

  def next: Option[Tree] = {
    pos += 1
    peek
  }

  def last: Option[Tree] = {
    if (pos == 0) return None
    Some(tokens(pos - 1))
  }

  def peek: Option[Tree] = {
    if (isEmpty) return None
    Some(tokens(pos))
  }

  def parseUntil(rbp: Int): Result[Error, Tree] = {
    var (t, l) = (peek, last)
    next

    var tree = t getOrElse {
      return Err(UnexpectedEOF(l))
    }
    /*
    if (!(nud contains t.key)) {
      return Err(PrattError(Reason.UnexpectedNull, t, l))
    }
    */

    val nullFun = getNull(tree)

    //if (!(rbp <= nullFun.rbp))
    //  return Err(BadPrecedenceNull(tree, l.getOrElse(Term(Nil))))

    val res = nullFun.parse(this, tree)
    var ast = res.getOrElse(return res)
    var nbp = Int.MaxValue

    var done = false
    while (!done && peek.nonEmpty) {
      tree = peek.get
      l = last

      /*
      if (!this.led.contains(t.key))
        return Err(PrattError(Reason.UnexpectedLeft, t, l))
      */

      val leftFun = getLeft(peek.get)

      if (!(leftFun.lbp <= nbp))
        return Err(BadPrecedenceLeft(tree, l.getOrElse(Term(Nil))))

      if (rbp <= leftFun.lbp && leftFun.lbp <= nbp) {
        next
        val res = leftFun.parse(this, tree, ast)
        ast = res.getOrElse(return res)
        nbp = leftFun.nbp
      } else {
        done = true
      }
    }

    Ok(ast)
  }
}



object PrattFunctions {
  def nullError(rpb: Int)(p: PrattParser, op: Tree): Result[Error, Tree] = {
    Err(UnknownNull(op, p.last))
  }

  def leftError(rbp: Int)(p: PrattParser, op: Tree, x: Tree): Result[Error, Tree] = {
    Err(UnknownLeft(op, p.last))
  }

  def literal(rbp: Int)(p: PrattParser, op: Tree): Result[Error, Tree] = {
    Ok(op)
  }

  def leftCall(rbp: Int)(p: PrattParser, op: Tree, x: Tree): Result[Error, Tree] = {
    val args = ArrayBuffer[Tree](x)

    var done = false
    if (p.peek contains Atom(")")) {
      p.next
      done = true
    }
    while (!done) {
      val next = p.parseUntil(rbp)
      args append next.getOrElse(return next)
      if (p.peek contains Atom(",")) {
        p.next
      } else if (p.peek contains Atom(")")) {
        p.next
        done = true
      } else {
        return Err(BadMix(name = x.toString, expected = Atom(") or ,"), actual = p.peek.getOrElse(Term(Nil))))
      }
    }

    val term = Term(args.toList)
    term.span = term.compSpan
    Ok(term)
  }

  def parseMix(name: String, mix: Array[String], args: ArrayBuffer[Tree], rbp: Int)(p: PrattParser, start: Int): Option[Error] = {
    var i = start
    while (i < mix.length) {
      val key = mix(i)
      if (key == "_?" && p.peek.contains(Atom(mix(i + 1)))) {
        p.next
        args append Term(Nil)
        i += 1
      } else if (key == "_" || key == "_?" || key == "_!") {
        val bp = if (key == "_!") rbp else rbp + 1
        val next = p.parseUntil(bp)
        args append next.getOrElse(return Some(next.getError))
      } else if (key == "_+") {
        val repeat = Atom(mix(i - 1))
        var done = false
        while (!done) {
          val next = p.parseUntil(rbp + 1)
          args append next.getOrElse(return Some(next.getError))
          if (p.peek contains repeat)
            p.next
          else
            done = true
        }
      } else if (p.peek contains Atom(key)) {
        p.next
      } else if (p.peek.isEmpty) {
        return Some(BadMix(name = name, expected = Atom(key), Term(Nil)))
      } else {
        return Some(BadMix(name = name, expected = Atom(key), actual = p.peek.get))
      }
      i += 1
    }

    None
  }

  def leftMix(name: String, mix: Array[String], rbp: Int)(p: PrattParser, op: Tree, x: Tree): Result[Error, Tree] = {
    val head = if (name == "nil") op else if (name == "_") x else Atom(name)
    val args = ArrayBuffer[Tree](head)
    if (name != "_") args append x
    val res = parseMix(name, mix, args, rbp)(p, 2)
    if (res.nonEmpty) return Err(res.get)
    val term = Term(args.toList)
    term.span = term.compSpan
    Ok(term)
  }

  def nullMix(name: String, mix: Array[String], rbp: Int)(p: PrattParser, op: Tree): Result[Error, Tree] = {
    val head = if (name == "nil") op else Atom(name)
    val args = ArrayBuffer[Tree](head)
    val res = parseMix(name, mix, args, rbp)(p, 1)
    if (res.nonEmpty) return Err(res.get)
    val term = Term(args.toList)
    term.span = term.compSpan
    Ok(term)
  }
}

object PrattParser {
  val LIT = "Literal"
  val EOF = "EOF"
  val BOF = "BOF"

  def makeLeft(name: String, led: (PrattParser, Tree, Tree) => Result[Error, Tree],
                       lbp: Int, rbp: Int, nbp: Option[Int] = None) = {
    name -> LeftOp(led, lbp, rbp, nbp.getOrElse(rbp))
  }

  def makeNull(name: String, nud: (PrattParser, Tree) => Result[Error, Tree],
                       rbp: Int, nbp: Option[Int] = None) = {
    name -> NullOp(nud, rbp, nbp.getOrElse(rbp))
  }

  def makeParser(ops: List[Operator]): PrattParser = {
    var nud = Map[String, NullOp]()
    var led = Map[String, LeftOp]()

    led += makeLeft("(", leftCall(100), 100, 100)

    new PrattParser(nud, led)
  }
}
