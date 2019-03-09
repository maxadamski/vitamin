package com.maxadamski.vitamin.parser1

import java.nio.charset.StandardCharsets

import collection.mutable.ArrayBuffer
import com.maxadamski.vitamin.ast.{Atom, Term, Tree}
import com.maxadamski.vitamin.ast.Term.{BLOCK, NUMBER, STRING, PARSE}
import com.maxadamski.vitamin.lexer.Token
import com.maxadamski.vitamin.lexer.TokenType._
import com.maxadamski.vitamin.Utils.btos

class Parser(tokens: Array[Token]) {
  private var next: Token = tokens.head
  private val len: Int = tokens.length
  private var pos: Int = 0

  private def isEmpty: Boolean = pos >= len

  private def accepts(t: TokenType): Boolean = {
    !isEmpty && next.t == t
  }

  private def advance(): Unit = {
    pos += 1
    next = if (isEmpty) null else tokens(pos)
  }

  private def consume(t: TokenType): Boolean = {
    if (!accepts(t)) return false
    advance()
    true
  }

  def parsePrim(): Option[Tree] = {
    if (accepts(BEG)) {
      val beg = Atom("{"); beg.span = next.span
      consume(BEG)
      val x = parseProg()
      val end = Atom("}"); end.span = next.span
      consume(END)
      val term = Term(List(beg, x, end))
      term.isBlock = true
      Some(term)
    } else if (accepts(ATOM)) {
      val t = next
      val x = btos(t.x(0))
      advance()
      val str = if (x.startsWith("`") && x.endsWith("`")) {
        x.stripPrefix("`").stripSuffix("`")
      } else {
        x
      }
      val tree = Atom(str)
      tree.span = t.span
      Some(tree)
    } else if (accepts(Str)) {
      val t = next
      val x = btos(t.x(0))
      advance()
      val str = if (x.startsWith("\"")) {
        x.stripPrefix("\"").stripSuffix("\"")
      } else if (x.startsWith("\"\"\"")) {
        x.stripPrefix("\"\"\"").stripSuffix("\"\"\"")
      } else {
        x
      }
      val tree = Atom(str)
      tree.span = t.span
      Some(Term(STRING :: tree :: Nil))

    } else if (accepts(Num)) {
      val integral = btos(next.x(0))
      val fraction = btos(next.x(1))
      consume(Num)
      Some(Term(NUMBER :: Atom(integral) :: Atom(fraction) :: Nil))
    } else {
      None
    }
  }

  def parseExpr(): Option[Tree] = {
    val prim = ArrayBuffer[Tree]()
    var x = parsePrim()
    while (x.nonEmpty) {
      val X = x.get
      if (X.isBlock && X.isInstanceOf[Term])
        prim.appendAll(X.asInstanceOf[Term].value)
      else
        prim.append(x.get)
      x = parsePrim()
    }
    if (prim.isEmpty) return None
    if (prim.length == 1) return Some(prim(0))
    Some(Term(PARSE :: prim.toList))
  }

  def parseProg(): Tree = {
    while (accepts(EOS)) consume(EOS)
    val expr = ArrayBuffer[Tree]()
    var x = parseExpr()
    while (x.nonEmpty) {
      expr.append(x.get)
      while (accepts(EOS)) consume(EOS)
      x = parseExpr()
    }
    while (accepts(EOS)) consume(EOS)
    Term(BLOCK :: expr.toList)
  }
}
