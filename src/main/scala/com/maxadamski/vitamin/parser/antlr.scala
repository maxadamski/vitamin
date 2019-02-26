package com.maxadamski.vitamin.parser

import math.max
import reflect.ClassTag
import collection.JavaConverters._

import com.maxadamski.vitamin.gen.VitaminCParser._
import com.maxadamski.vitamin.gen._
import com.maxadamski.vitamin.ast.{Tree, Term, Atom, Rule, Span}
import com.maxadamski.vitamin.ast.Term._
import org.antlr.v4.runtime._

object Parser {
  def parseString(string: String): Tree = {
    parseInput(new ANTLRInputStream(string))
  }

  def parseFile(path: String): Tree = {
    parseInput(new ANTLRFileStream(path))
  }

  def parseExpr(string: String): Tree = {
    val lexer = new VitaminCLexer(new ANTLRInputStream(string))
    val tokens = new CommonTokenStream(lexer)
    val parser = new VitaminCParser(tokens)
    val visitor = new VitaminCVisitor()
    visitor.visit(parser.expr)
  }

  def parseInput(input: CharStream): Tree = {
    val lexer = new VitaminCLexer(input)
    val tokens = new CommonTokenStream(lexer)
    val parser = new VitaminCParser(tokens)
    val visitor = new VitaminCVisitor()
    visitor.visit(parser.program)
  }
}

private class VitaminCVisitor extends VitaminCBaseVisitor[Tree] {
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

  override def visitProgram(ctx: ProgramContext): Tree =
    visit(ctx.chunk)

  override def visitChunk(ctx: ChunkContext): Tree =
    ctx.mkTerm(BLOCK :: ctx.expr.map(visit))

  /*
  override def visitExprDef(ctx: ExprDefContext): Tree =
    ctx.mkTerm(DEF :: visit(ctx.atom) :: ctx.expr.map(visit))

  override def visitExprFun(ctx: ExprFunContext): Tree =
    ctx.mkTerm(FUN :: visit(ctx.atom) :: ctx.expr.map(visit))

  override def visitExprLet(ctx: ExprLetContext): Tree =
    ctx.mkTerm(LET :: ctx.expr.map(visit))
  */

  override def visitExprIf(ctx: ExprIfContext): Tree =
    ctx.mkTerm(IF :: ctx.expr.map(visit))

  override def visitExprWhile(ctx: ExprWhileContext): Tree =
    ctx.mkTerm(WHILE :: ctx.expr.map(visit))

  override def visitExprFor(ctx: ExprForContext): Tree =
    ctx.mkTerm(FOR :: ctx.expr.map(visit))

  override def visitExprUse(ctx: ExprUseContext): Tree = {
    val args = ctx.expr.map(visit)
    val mode = if (ctx.text.contains("select")) "select" else "except"
    val qual = if (ctx.text.contains("qualified")) TRUE else FALSE
    ctx.mkTerm(USE :: Atom(mode) :: qual :: args)
  }

  override def visitExprFlat(ctx: ExprFlatContext): Tree = {
    ctx.prim.map(visit).map(expandFlat) match {
      case head :: Nil => head
      case list => ctx.mkTerm(PARSE :: list.map(expandFlat))
    }
  }

  def expandFlat(x: Tree): Tree = x match {
    case Term(TUPLE :: head :: Nil) => head
    case _ => x
  }

  override def visitPrimList(ctx: PrimListContext): Tree = ctx.expr.map(visit) match {
    //case head :: Nil => head
    case list => ctx.mkTerm(TUPLE :: list)
  }

  override def visitPrimCall(ctx: PrimCallContext): Tree = {
    val callee = visit(ctx.callee)
    val args = ctx.primList.map(visit)
    val res = args.fold(callee)((sum, it) => ctx.mkTerm(sum :: toArguments(it)))
    if (ctx.primLambda != null) res.asInstanceOf[Term].value :+= visit(ctx.primLambda)
    res
  }

  def toArguments(ast: Tree): List[Tree] = ast match {
    case it@Term(TUPLE :: tail) => tail
    case it@Term(head :: Nil) => head :: Nil
    case _ => ast :: Nil
  }

  override def visitPrimLambda(ctx: PrimLambdaContext): Tree = {
    val params = if (ctx.expr != null) visit(ctx.expr) else Term(Nil)
    ctx.mkTerm(LAMBDA :: params :: visit(ctx.chunk) :: Nil)
  }

  override def visitPrimBlock(ctx: PrimBlockContext): Tree =
    visit(ctx.chunk)

  override def visitSymbol(ctx: SymbolContext): Tree =
    ctx.mkAtom(ctx.text)

  override def visitStr(ctx: StrContext): Tree = {
    val text = StringContext.treatEscapes(ctx.text.stripPrefix("\"").stripSuffix("\""))
    ctx.mkTerm(STRING :: Atom(text) :: Nil)
  }


  override def visitNum(ctx: NumContext): Tree = {
    val text = ctx.text.toLowerCase
    val sign = if (text.contains("-")) "-" else "+"
    val args: List[Tree] = text.stripPrefix("-").stripPrefix("+").split('.') match {
      case Array(integer, decimal) => Atom(integer) :: Atom(decimal) :: Nil
      case Array(integer) => Atom(integer) :: Atom("") :: Nil
      case _ => throw new Exception("impossible@visitVNum")
    }
    ctx.mkTerm(NUMBER :: Atom(sign) :: args)
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
}

