package com.maxadamski.vitamin

import PrattTools._
import PrattFunctions._
import com.maxadamski.vitamin.Report._

import util.control.Breaks._

// TODO: do something about the expr metadata

case class Null(
  nud: (PrattParser, Token, Int) => PrattCall,
  rbp: Int, nbp: Int)

case class Left(
  led: (PrattParser, Token, Int, PrattCall) => PrattCall,
  lbp: Int, rbp: Int, nbp: Int)

case class PrattCall(head: Token, tail: List[PrattCall])

case class Token(key: String, value: Any)

class PrattParser(
  val ctx: Ctx,
  val nud: Map[String, Null],
  val led: Map[String, Left],
  val ops: List[String],
) {
  var history: List[Token] = List()
  var tokens: Iterator[Token] = Iterator()
  var token: Token = EOF_TOKEN

  def parse(node: AST.Tree): AST.Tree = {
    val tokens = encodeSyntax(node, ops)
    ctx.nodeStack.push(node)
    val parsed = parse(tokens.toIterator)
    ctx.nodeStack.pop()
    decodeSyntax(parsed)
  }

  def parse(tokens: Iterator[Token]): PrattCall = {
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

  def parseUntil(rbp: Int): PrattCall = {
    val (t, l) = (token, last)
    advance()

    if (t == EOF_TOKEN)
      throw new ParserException(error__parser__unexpected_eof(ctx))
    if (!this.nud.contains(t.key))
      throw new ParserException(error__parser__null_unexpected_token(ctx, t))

    val nud = this.nud(t.key)

    if (!(rbp <= nud.rbp))
      throw new ParserException(error__parser__null_bad_precedence(ctx, t, l))

    var ast = nud.nud(this, t, nud.rbp)
    var nbp = Int.MaxValue

    breakable {
      while (true) {
        val (t, l) = (token, last)

        if (!this.led.contains(t.key))
          throw new ParserException(error__parser__left_unexpected_token(ctx, t))

        val led = this.led(t.key)

        if (!(led.lbp <= nbp))
          throw new ParserException(error__parser__left_bad_precedence(ctx, t, l))

        if (t == EOF_TOKEN)
          break
        if (!(rbp <= led.lbp && led.lbp <= nbp))
          break

        advance()
        ast = led.led(this, t, led.rbp, ast)
        nbp = led.nbp
      }
    }

    ast
  }
}

object PrattFunctions {

  def nullError(p: PrattParser, t: Token, rbp: Int): PrattCall = {
    throw new ParserException(error__parser__null_not_registered(p.ctx, t))
  }

  def leftError(p: PrattParser, t: Token, rbp: Int, left: PrattCall): PrattCall = {
    throw new ParserException(error__parser__left_not_registered(p.ctx, t))
  }

  def literal(p: PrattParser, t: Token, rbp: Int): PrattCall = {
    PrattCall(t, List())
  }

  def prefix(p: PrattParser, t: Token, rbp: Int): PrattCall = {
    PrattCall(t, List(p.parseUntil(rbp)))
  }

  def infix(p: PrattParser, t: Token, rbp: Int, left: PrattCall): PrattCall = {
    PrattCall(t, List(left, p.parseUntil(rbp)))
  }

  def suffix(p: PrattParser, t: Token, rbp: Int, left: PrattCall): PrattCall = {
    PrattCall(t, List(left))
  }

}

object PrattTools {

  val LIT = "Literal"
  val EOF = "EOF"
  val BOF = "BOF"
  val EOF_TOKEN = Token(EOF, Nil)
  val BOF_TOKEN = Token(BOF, Nil)

  private def makeLeft(name: String, led: (PrattParser, Token, Int, PrattCall) => PrattCall,
    lbp: Int, rbp: Int, nbp: Option[Int] = None) = {
    name -> Left(led, lbp, rbp, nbp.getOrElse(rbp))
  }

  private def makeNull(name: String, nud: (PrattParser, Token, Int) => PrattCall,
    rbp: Int, nbp: Option[Int] = None) = {
    name -> Null(nud, rbp, nbp.getOrElse(rbp))
  }

  def makeParser(ctx: Ctx, ops: List[Op]): PrattParser = {
    var max_prec = if (ops.nonEmpty) ops.map(_.prec).max else 0
    val op_names = ops.map(_.name)
    val offset = 10
    max_prec += offset
    val lit_prec = max_prec + 1
    val inf_prec = lit_prec + 1

    var nud = Map[String, Null]()
    var led = Map[String, Left]()

    nud += makeNull(LIT, literal, lit_prec)
    nud += makeNull(EOF, nullError, 0)
    led += makeLeft(EOF, leftError, 0, 0)

    for (op <- ops) {
      val (name, prec) = (op.name, op.prec + offset)
      op match {
        case Op(_, _, Fixity.Infix, Assoc.None) =>
          led += makeLeft(name, infix, prec, prec + 1, nbp = Some(prec - 1))
        case Op(_, _, Fixity.Infix, Assoc.Right) =>
          led += makeLeft(name, infix, prec, prec)
        case Op(_, _, Fixity.Infix, Assoc.Left) =>
          led += makeLeft(name, infix, prec, prec + 1)
        case Op(_, _, Fixity.Prefix, Assoc.None) =>
          nud += makeNull(name, prefix, prec, nbp = Some(prec - 1))
        case Op(_, _, Fixity.Prefix, Assoc.Right) =>
          nud += makeNull(name, prefix, prec)
        case Op(_, _, Fixity.Suffix, _) =>
          led += makeLeft(name, suffix, prec, prec)
        case _ =>
          throw new ParserException("err_parser_unsupported_operator")
      }
    }

    new PrattParser(ctx, nud, led, op_names)
  }

  def encodeSyntax(expr: AST.Tree, ops: List[String]): List[Token] = expr match {
    case AST.Node(_, children, _) =>
      children map {
        case atom@AST.Atom(name) if !atom.isEscaped && ops.contains(name) =>
          Token(name, atom)
        case primary =>
          Token(LIT, primary)
      }
    case _ =>
      throw new Exception("not implemented")
  }

  def decodeSyntax(call: PrattCall): AST.Tree = {
    decode[AST.Tree](call, { (head, tail) =>
      AST.Node(AST.Tag.Call, head :: tail)
    })
  }

  def decode[T](call: PrattCall, makeCall: (T, List[T]) => T): T = {
    val head = call.head.value.asInstanceOf[T]
    call.tail match {
      case Nil => head
      case tail => makeCall(head, tail.map(decode(_, makeCall)))
    }
  }

}

