package com.maxadamski.vitamin.parser

import math.max
import reflect.ClassTag
import collection.JavaConverters._
import com.maxadamski.vitamin.gen.VitaminParser._
import com.maxadamski.vitamin.gen._
import com.maxadamski.vitamin.ast.{Atom, Rule, Span, Term, Tree}
import com.maxadamski.vitamin.ast.Term._
import org.antlr.v4.runtime._
import org.antlr.v4.runtime.tree.ParseTree

object Parser {
  def parseExpr(x: String): Tree = parseRule(new ANTLRInputStream(x), p => p.expr())

  def parseFile(x: String): Tree = parseRule(new ANTLRFileStream(x), p => p.file())

  def parseRule(input: CharStream, rule: VitaminParser => ParseTree): Tree = {
    val lexer = new VitaminLexer(input)
    val tokens = new CommonTokenStream(lexer)
    val parser = new VitaminParser(tokens)
    val visitor = new VitaminCVisitor()
    visitor.visit(rule(parser))
  }
}

private class VitaminCVisitor extends VitaminParserBaseVisitor[Tree] {
  implicit class ParserRuleContextExtension(ctx: ParserRuleContext) {
    def mkTerm(data: List[Tree]): Term = withRule(Term(data))

    def mkAtom(data: String): Atom = withRule(Atom(data))

    def text: String = ctx.getText

    def withRule[T <: Tree](tree: T): T = {
      tree.rule = Some(rule)
      tree
    }

    def rule: Rule = {
      val start = ctx.start.getStartIndex
      val stop = max(ctx.start.getStopIndex, ctx.stop.getStopIndex)
      val line = ctx.start.getLine
      val char = ctx.start.getCharPositionInLine
      val span = Span(start, stop)
      Rule(ctx.getText, line, char, span)
    }
  }

  implicit class JavaListExtension[T](javaList: java.util.List[T]) {
    def map[U](transform: T => U): List[U] = {
      javaList.asScala.toList.map(transform)
    }
  }

  override def visitBody(ctx: BodyContext): Tree =
    ctx.mkTerm(BLOCK :: ctx.expr.map(visit))

  override def visitExpr(ctx: ExprContext): Tree = {
    ctx.prim.map(visit).map(expandFlat) match {
      case head :: Nil => head
      case list => ctx.mkTerm(PARSE :: list.map(expandFlat))
    }
  }

  def expandFlat(x: Tree): Tree = x match {
    case Term(TUPLE :: head :: Nil) => head
    case _ => x
  }

  override def visitFile(ctx: FileContext): Tree = visit(ctx.body)

  override def visitList(ctx: ListContext): Tree = ctx.expr.map(visit) match {
    //case head :: Nil => head
    case list => ctx.mkTerm(TUPLE :: list)
  }

  override def visitPrim(ctx: PrimContext): Tree = {
    if (ctx.lite != null) return visit(ctx.lite)
    val callee = visit(ctx.call)
    val args = ctx.list.map(visit)
    val res = args.fold(callee)((sum, it) => ctx.mkTerm(sum :: toArguments(it)))
    if (ctx.func != null) res.asInstanceOf[Term].value :+= visit(ctx.func)
    res
  }

  def toArguments(ast: Tree): List[Tree] = ast match {
    case it@Term(TUPLE :: tail) => tail
    case it@Term(head :: Nil) => head :: Nil
    case _ => ast :: Nil
  }

  override def visitFunc(ctx: FuncContext): Tree = {
    val params = if (ctx.expr != null) visit(ctx.expr) else Term(Nil)
    ctx.mkTerm(LAMBDA :: params :: visit(ctx.body) :: Nil)
  }

  override def visitAtom(ctx: AtomContext): Tree = {
    var (quoted, text) = (false, ctx.text)
    if (text.startsWith("`") && text.endsWith("`")) {
      text = text.stripPrefix("`").stripSuffix("`")
      quoted = true
    }
    val leaf = ctx.mkAtom(text)
    leaf.escaped = quoted
    leaf
  }

  override def visitLite(ctx: LiteContext): Tree = {
    if (ctx.Num1 != null) return visitNum1(ctx, ctx.Num1.getText)
    if (ctx.Num2 != null) return visitNum2(ctx, ctx.Num2.getText)
    if (ctx.Str1 != null) return visitStr1(ctx, ctx.Str1.getText)
    if (ctx.Str2 != null) return visitStr2(ctx, ctx.Str2.getText)
    if (ctx.Symb != null) return visitSymb(ctx, ctx.Symb.getText)
    throw new Exception("impossible")
  }

  def visitNum1(ctx: LiteContext, str: String): Tree = {
    val bases = Map('b' -> 2, 'o' -> 8, 'x' -> 16)
    val (radix, number) = if (str.startsWith("0")) {
      (bases(1).toString, str.substring(2).replace("_", ""))
    } else {
      val Array(x, y) = str.split("#", 1)
      (x, y.replace("_", ""))
    }
    ctx.mkTerm(NUMBER :: Atom(radix) :: Atom(number) :: Atom("") :: Nil)
  }

  def visitNum2(ctx: LiteContext, str: String): Tree = {
    val args: List[Tree] = str.split('.') match {
      case Array(integer, decimal) => Atom(integer) :: Atom(decimal) :: Nil
      case Array(integer) => Atom(integer) :: Atom("") :: Nil
      case _ => throw new Exception("impossible@visitVNum")
    }
    ctx.mkTerm(NUMBER ::  args)
  }

  def processStr(str: String, leftSep: String, rightSep: String): (String, String) = {
    val x = str.stripSuffix(rightSep).stripPrefix(leftSep).split(leftSep, 1)
    val (sigil, text) = x match { case Array(x) => ("", x); case Array(x, y) => (x, y) }
    (sigil, StringContext.treatEscapes(text))
  }

  def visitStr1(ctx: LiteContext, str: String): Tree = {
    val (f, text) = processStr(str, "\"", "\"")
    val term = ctx.mkTerm(STRING :: Atom(text) :: Nil)
    if (f.nonEmpty) Term(Atom(f"sigil_$f") :: term :: Nil) else term
  }

  def visitStr2(ctx: LiteContext, str: String): Tree = {
    val (f, text) = processStr(str, "\"\"\"", "\"\"\"")
    val term = ctx.mkTerm(STRING :: Atom(text) :: Nil)
    if (f.nonEmpty) Term(Atom(f"sigil_$f") :: term :: Nil) else term
  }

  def visitSymb(ctx: LiteContext, str: String): Tree = ctx.mkAtom(str)
}

