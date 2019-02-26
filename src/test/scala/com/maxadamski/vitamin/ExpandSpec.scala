package com.maxadamski.vitamin

import runtime.{Core, Env, Lambda}
import ast.{Atom, Term, Tree}
import ast.Term._
import Core._
import parser.{Associativity, Fixity, OpGroup, OpName, Parser}
import org.scalatest._
import org.scalatest.Matchers._

class ExpandSpec extends FunSpec {
  def mkEnv(): Env = {
    val env = new Env()
    env.parser.opGroups = Map(
      "comma" -> OpGroup("comma", Fixity.LeftChain, Associativity.Left, None, None)
    )
    env.parser.opNames = Set(
      OpName("comma", ",")
    )
    env.parser.updateParser()
    env
  }

  val Seq(x0, x1, x2) = Range(0, 3).map(i => Atom(f"x$i"))
  val Seq(x, y, z) = Seq("x", "y", "z").map(Atom)
  val Seq(a, b, c, d) = Seq("a", "b", "c", "d").map(Atom)
  val Seq(foo, bar, baz) = Seq("foo", "bar", "baz").map(Atom)

  describe("parse_once") {
    val parse = parse_once(mkEnv()) _

    it("should not parse Nil") {
      parse(Term(Nil)) should equal (Term(Nil), false)
    }

    it("should not parse Atom") {
      parse(Atom("")) should equal (Atom(""), false)
      parse(Atom("xxx")) should equal (Atom("xxx"), false)
    }

    it("should not parse parsed Term") {
      val inner = Term(Atom("x") :: Atom("y") :: Nil)
      val outer = Term(Atom("a") :: inner :: Nil)
      parse(outer) should equal (outer, false)
    }

    it("should parse flat unparsed Term") {
      val flat = Term(List(PARSE, x0, TUPLE, x1))
      parse(flat) should equal (Term(List(TUPLE, x0, x1)), true)
    }

    it("should parse deep unparsed Term") {
      val flat = Term(List(PARSE, x0, TUPLE, x1))
      val deep = Term(List(PARSE, flat))
      parse(deep) should equal (flat, true)
    }

  }

  describe("expand") {
    def exp(str: String) = expand(mkEnv())(Parser.parseExpr(str))

    it("should splice argument tuple") {
      val ab = Term(TUPLE :: a :: b :: Nil)

      exp("foo(a)") should equal (Term(foo :: a :: Nil))
      exp("foo(a, b)") should equal (Term(foo :: a :: b :: Nil))
      exp("foo((a, b))") should equal (Term(foo :: ab :: Nil))
      exp("foo((a, b), (a, b))") should equal (Term(foo :: ab :: ab :: Nil))
    }

    it("should parse deep tree") {
      val env = mkEnv()
      def ex(x: String): Tree = Core.expand(env)(Parser.parseExpr(x))
      def pp(x: String): Unit = println(Parser.parseExpr(x))
      def pex(x: String): Unit = println(ex(x))

      //pp("foo()")
      //pp("foo(bar(x, y, z), bar(baz(a, {f(x); g(y)}, c), bar(baz(a, b, c))))")

      pp("(a, b, c)")
      pp("foo")
      pp("foo()")
      pp("foo(a)")
      pp("foo(a)(b)")
      pp("foo(a, b, c)")
      pp("foo(a, b, c)(a, b, c)")
      pp("foo((a, b, c))")
      pp("foo((a, b, c), (a, b, c))")

      pp("foo(a * (b + c))")

      pp("quasiquote(unquote(f))")
      pp("quasiquote(unquote(f)())")
      pp("quasiquote(unquote(f)(unquote(x)))")
      pp("quasiquote(unquote(f)(unquote(x), unquote(y)))")
      pp("quasiquote(unquote(f)((unquote(x), unquote(y))))")

      // '(@f(,(@x @y))
    }

    it("should expand macro") {
      val env = mkEnv()
      //exp("quasiquote(unquote(x))") should equal (Term(x :: Nil))

      //ev("1, 2, 3, 4") should equal (List(1, 2, 3, 4))

      //ev("quote(x)") should equal (x)
      //ev("quote(x(y, z))") should equal (Term(x :: y :: z :: Nil))
      //eval("let!(L, quote(1, 2, 3))") should equal (None)
      //eval("L") should equal (None)

      /*
      'x => x
      '(one 2 3) => (one 2 3)
      (define L (list 1 2 3)) => None
      `(testing ,@L testing) => (testing 1 2 3 testing)
      `(testing ,L testing) => (testing (1 2 3) testing)
      */
    }
  }
}
