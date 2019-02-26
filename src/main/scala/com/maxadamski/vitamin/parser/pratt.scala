package com.maxadamski.vitamin.parser

import util.control.Breaks._

import PrattParser._
import PrattFunctions._
import Fixity.Fixity
import Associativity.Associativity
import Reason.Reason

// TODO: do something about the expr metadata

object Extensions {
}

trait PrattTokenizable {
  def isFunctor(ops: List[String]): Boolean

  def encodePratt(ops: List[String]): List[Token]
}

object Reason extends Enumeration {
  type Reason = Value
  val UnexpectedNull, UnexpectedLeft,
  BadPrecedenceNull, BadPrecedenceLeft,
  UnknownNull, UnknownLeft,
  UnexpectedEOF = Value
}

case class PrattError(reason: Reason, curr: Token, last: Token)

object Associativity extends Enumeration {
  type Associativity = Value
  val Left, Right, None = Value
}

object Fixity extends Enumeration {
  type Fixity = Value
  val Prefix, Suffix, Infix, LeftChain, NullMix = Value
}

case class Operator(name: String, precedence: Int, fixity: Fixity, associativity: Associativity)

case class NullOp(
  nud: (PrattParser, Token, Int) => Either[PrattError, PrattCall],
  rbp: Int, nbp: Int
)

case class LeftOp(
  led: (PrattParser, Token, Int, PrattCall) => Either[PrattError, PrattCall],
  lbp: Int, rbp: Int, nbp: Int
)

case class PrattCall(head: Token, var tail: List[PrattCall])

case class Token(key: String, value: Any) {
  override def toString: String = key match {
    case EOF => "EOF"
    case BOF => "BOF"
    case LIT => f"`$value`"
    case _ => key
  }

  def typeString: String = key match {
    case EOF | BOF => "special token"
    case LIT => "primary expression"
    case _ => "operator"
  }
}

class PrattParser(
  val nud: Map[String, NullOp],
  val led: Map[String, LeftOp],
  val ops: List[String]
) {
  var history: List[Token] = List()
  var tokens: Iterator[Token] = Iterator()
  var token: Token = BOF_TOKEN

  def parse[T <: PrattTokenizable](t: T): Either[PrattError, PrattCall] = {
    val tokens = t.encodePratt(ops)
    val result = parse(tokens.toIterator)
    result
  }

  def parse(tokens: Iterator[Token]): Either[PrattError, PrattCall] = {
    history = List()
    this.tokens = tokens
    advance()
    parseUntil(0)
  }

  def next: Token = {
    if (tokens.hasNext) tokens.next() else EOF_TOKEN
  }

  def last: Token = {
    history.last
  }

  def advance(): Token = {
    history :+= token
    token = next
    token
  }

  def parseUntil(rbp: Int): Either[PrattError, PrattCall] = {
    val (t, l) = (token, last)
    advance()

    if (t == EOF_TOKEN)
      return Left(PrattError(Reason.UnexpectedEOF, t, l))
    if (!this.nud.contains(t.key))
      return Left(PrattError(Reason.UnexpectedNull, t, l))

    val nud = this.nud(t.key)

    if (!(rbp <= nud.rbp))
      return Left(PrattError(Reason.BadPrecedenceNull, t, l))

    val res = nud.nud(this, t, nud.rbp)
    if (res.isLeft) return res
    var ast = res.right.get
    var nbp = Int.MaxValue

    breakable {
      while (true) {
        val (t, l) = (token, last)

        if (!this.led.contains(t.key))
          return Left(PrattError(Reason.UnexpectedLeft, t, l))

        val led = this.led(t.key)

        if (!(led.lbp <= nbp))
          return Left(PrattError(Reason.BadPrecedenceLeft, t, l))

        // not (rbp <= lbp <= nbp)
        if (t == EOF_TOKEN || !(rbp <= led.lbp && led.lbp <= nbp))
          break

        advance()
        val res = led.led(this, t, led.rbp, ast)
        if (res.isLeft)
          return res
        ast = res.right.get
        nbp = led.nbp
      }
    }

    Right(ast)
  }
}



object PrattFunctions {
  implicit class EitherExtension[Left, Right](value: Either[Left, Right]) {
    def map[T](transform: Right => T): Either[Left, T] = value match {
      case Left(inner) => Left(inner)
      case Right(inner) => Right(transform(inner))
    }
  }

  def nullError(p: PrattParser, t: Token, rbp: Int): Either[PrattError, PrattCall] = {
    Left(PrattError(Reason.UnknownNull, t, p.last))
  }

  def leftError(p: PrattParser, t: Token, rbp: Int, left: PrattCall): Either[PrattError, PrattCall] = {
    Left(PrattError(Reason.UnknownLeft, t, p.last))
  }

  def literal(p: PrattParser, t: Token, rbp: Int): Either[PrattError, PrattCall] = {
    Right(PrattCall(t, Nil))
  }

  def prefix(p: PrattParser, t: Token, rbp: Int): Either[PrattError, PrattCall] = {
    p.parseUntil(rbp).map(right => PrattCall(t, List(right)))
  }

  def infix(p: PrattParser, t: Token, rbp: Int, left: PrattCall): Either[PrattError, PrattCall] = {
    p.parseUntil(rbp).map(right => PrattCall(t, List(left, right)))
  }

  def suffix(p: PrattParser, t: Token, rbp: Int, left: PrattCall): Either[PrattError, PrattCall] = {
    Right(PrattCall(t, List(left)))
  }

  def leftChain(p: PrattParser, op: Token, rbp: Int, x: PrattCall): Either[PrattError, PrattCall] = {
    // TODO: report better errors
    val y = p.parseUntil(rbp)
    if (y.isLeft)
      return y
    var args = List(x, y.right.get)
    while (p.token.key == op.key) {
      p.advance()
      val next = p.parseUntil(rbp)
      if (next.isLeft)
        return next
      args :+= next.right.get
    }
    Right(PrattCall(op, args))
  }

  def nullMix(p: PrattParser, op: Token, rbp: Int): Either[PrattError, PrattCall] = {
    val x = p.parseUntil(p.led("=").nbp)
    if (x.isLeft) return x
    var args = List(x.right.get)
    if (p.token.key == "=") {
      p.advance()
      val body = p.parseUntil(rbp)
      if (body.isLeft)
        return body
      args :+= body.right.get
    }
    Right(PrattCall(op, args))
  }

  def require(actual: String, expected: String): Unit = {
    if (actual != expected)
      throw new Exception(f"$actual != $expected")
  }
}

object PrattParser {
  val LIT = "Literal"
  val EOF = "EOF"
  val BOF = "BOF"
  val EOF_TOKEN = Token(EOF, Nil)
  val BOF_TOKEN = Token(BOF, Nil)

  private def makeLeft(name: String, led: (PrattParser, Token, Int, PrattCall) => Either[PrattError, PrattCall],
    lbp: Int, rbp: Int, nbp: Option[Int] = None) = {
    name -> LeftOp(led, lbp, rbp, nbp.getOrElse(rbp))
  }

  private def makeNull(name: String, nud: (PrattParser, Token, Int) => Either[PrattError, PrattCall],
    rbp: Int, nbp: Option[Int] = None) = {
    name -> NullOp(nud, rbp, nbp.getOrElse(rbp))
  }

  def makeParser(ops: List[Operator]): PrattParser = {
    var max_prec = if (ops.nonEmpty) ops.map(_.precedence).max else 0
    var op_names = ops.map(_.name)
    // FIXME: hack hack hack
    val offset = 10
    max_prec += offset
    val lit_prec = max_prec + 10
    val inf_prec = max_prec + 20

    var nud = Map[String, NullOp]()
    var led = Map[String, LeftOp]()

    nud += makeNull(LIT, literal, lit_prec)
    nud += makeNull(EOF, nullError, -1)
    nud += makeNull("=", nullError, -1)
    led += makeLeft(EOF, leftError, -1, -1)

    ops foreach { op =>
      val (name, prec) = (op.name, op.precedence + offset)
      op match {
        case Operator(_, _, Fixity.Infix, Associativity.None) =>
          led += makeLeft(name, infix, prec, prec + 1, nbp = Some(prec - 1))
        case Operator(_, _, Fixity.Infix, Associativity.Left) =>
          led += makeLeft(name, infix, prec, prec + 1)
        case Operator(_, _, Fixity.Infix, Associativity.Right) =>
          led += makeLeft(name, infix, prec, prec)
        case Operator(_, _, Fixity.Prefix, Associativity.None) =>
          nud += makeNull(name, prefix, prec, nbp = Some(prec - 1))
        case Operator(_, _, Fixity.Prefix, Associativity.Right) =>
          nud += makeNull(name, prefix, prec)
        case Operator(_, _, Fixity.Suffix, _) =>
          led += makeLeft(name, suffix, prec, prec)
        case Operator(_, _, Fixity.LeftChain, _) =>
          led += makeLeft(name, leftChain, prec, prec + 1, nbp = Some(prec - 1))
        case Operator(_, _, Fixity.NullMix, _) =>
          nud += makeNull(name, nullMix, prec, nbp = Some(prec - 1))
        case Operator(_, _, fix, ass) =>
          throw new Exception(s"err_parser_unsupported_operator $fix $ass")
      }
    }

    new PrattParser(nud, led, op_names)
  }
}
