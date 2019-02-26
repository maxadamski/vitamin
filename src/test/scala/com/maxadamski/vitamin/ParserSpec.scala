package com.maxadamski.vitamin

import org.scalatest._
import org.scalatest.Matchers._

import ast.{Atom, Term, Tree}
import ast.Term._
import parser.{PrattParser, Associativity, Fixity, OpGroup, OpName, Parser}
import runtime.ParserContext

/*
class ParserSpec extends FunSpec {
  def toTerm(x: String): Tree = {
    val tokens = x.split(" ").toList
    Term(PARSE :: tokens.map(Atom))
  }

  def pp(ctx: ParserContext, x: String) = {
    println(ctx.parse(toTerm(x)))
  }

  it("parses parentheses") {
    val ctx = ParserContext()
    ctx.opGroups = Map(
      "comma" -> OpGroup("comma", Fixity.LeftChain, Associativity.Left, None, None),
    )
    ctx.opNames = Set(
      OpName("comma", ","),
    )
    ctx.updateParser()

    pp(ctx, "a")
    pp(ctx, "( a )")
    pp(ctx, "( ( ( a ) ) )")
  }
}
*/
