package com.maxadamski.vitamin

import PrattTools._
import PrattFunctions._
import com.maxadamski.vitamin.Report._
import com.maxadamski.vitamin.Vitamin.Ctx

import util.control.Breaks._

// TODO: do something about the expr metadata

case class Token(key: String, value: AST)

case class Null(
  nud: (PrattParser, Token, Int) => AST,
  rbp: Int, nbp: Int)

case class Left(
  led: (PrattParser, Token, Int, AST) => AST,
  lbp: Int, rbp: Int, nbp: Int)

class PrattParser(
  val ctx: Ctx,
  val nud: Map[String, Null],
  val led: Map[String, Left],
  val opNames: Array[String],
) {
  var history: Array[Token] = Array()
  var tokens: Iterator[Token] = Iterator()
  var token: Token = EOF_TOKEN

  def parse(node: AST): AST = node.data match {
    case Node(children) =>
      val tokens = children map {
        case atom@AST(Tag.Atom, Leaf(name: String), meta) if opNames.contains(name) =>
          val key = if (meta.contains(Meta.QuotedAtom)) LIT else name
          Token(key, atom)
        case prim@AST(_, _, _) =>
          Token(LIT, prim)
      }
      ctx.nodeStack.push(node)
      val parsed = parse(tokens.toIterator)
      ctx.nodeStack.pop()
      parsed
    case Leaf(value) =>
      throw new Exception("not implemented")
  }

  def parse(tokens: Iterator[Token]): AST = {
    history = Array()
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

  def parseUntil(rbp: Int): AST = {
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
  def mkArg(arg: AST): AST = {
    arg
  }

  def sum(x: Span, y: Span): Span = {
    Span(Math.min(x.start, y.start), Math.max(x.stop, y.stop))
  }

  def mkCall(args: AST*): AST = {
    val call = AST(Tag.Call, Node(args), Map(
      Meta.Span -> args.flatMap(_.span).reduce(sum),
      Meta.Line -> args(0).line.get,
      Meta.Char -> args(0).char.get,
    ))
    call
  }

  def nullError(p: PrattParser, t: Token, rbp: Int): AST = {
    throw new ParserException(error__parser__null_not_registered(p.ctx, t))
  }

  def leftError(p: PrattParser, t: Token, rbp: Int, left: AST): AST = {
    throw new ParserException(error__parser__left_not_registered(p.ctx, t))
  }

  def literal(p: PrattParser, t: Token, rbp: Int): AST = {
    t.value
  }

  def prefix(p: PrattParser, t: Token, rbp: Int): AST = {
    val arg = mkArg(p.parseUntil(rbp))
    mkCall(t.value, arg)
  }

  def infix(p: PrattParser, t: Token, rbp: Int, left: AST): AST = {
    val lhs = mkArg(left)
    val rhs = mkArg(p.parseUntil(rbp))
    mkCall(t.value, lhs, rhs)
  }

  def suffix(p: PrattParser, t: Token, rbp: Int, left: AST): AST = {
    val arg = mkArg(left)
    mkCall(t.value, arg)
  }
}

object PrattTools {
  val LIT = "Literal"
  val EOF = "EOF"
  val BOF = "BOF"
  val EOF_TOKEN = Token(EOF, AST(null, null))
  val BOF_TOKEN = Token(BOF, AST(null, null))

  private def makeLeft(name: String, led: (PrattParser, Token, Int, AST) => AST,
    lbp: Int, rbp: Int, nbp: Option[Int] = None) = {
    name -> Left(led, lbp, rbp, nbp.getOrElse(rbp))
  }

  private def makeNull(name: String, nud: (PrattParser, Token, Int) => AST,
    rbp: Int, nbp: Option[Int] = None) = {
    name -> Null(nud, rbp, nbp.getOrElse(rbp))
  }

  def makeParser(ctx: Ctx, ops: Iterable[Op]): PrattParser = {
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

    new PrattParser(ctx, nud, led, op_names.toArray)
  }
}

