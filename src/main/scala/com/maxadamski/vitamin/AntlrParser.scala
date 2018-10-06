package com.maxadamski.vitamin

import com.maxadamski.vitamin.Tag.Tag
import com.maxadamski.vitamin.Types.{AType, Typ}
import com.maxadamski.vparser._
import com.maxadamski.vparser.VitaminCParser._
import org.antlr.v4.runtime._
import org.antlr.v4.runtime.tree._

import math.max
import scala.collection.mutable
import scala.reflect.ClassTag

class ANTLRException(message: String) extends Exception

object Parser {

  def parseString(string: String): AST = {
    parseInput(new ANTLRInputStream(string))
  }

  def parseFile(path: String): AST = {
    parseInput(new ANTLRFileStream(path))
  }

  def parseInput(input: CharStream): AST = {
    val lexer = new VitaminCLexer(input)
    val tokens = new CommonTokenStream(lexer)
    val parser = new VitaminCParser(tokens)
    val listener = new Listener()
    val walker = new ParseTreeWalker()
    walker.walk(listener, parser.program())
    listener.program match {
      case Some(value) => value
      case None => throw new Exception("Failed to parse file")
    }
  }

}

class Listener extends VitaminCBaseListener {

  implicit class ParserRuleContextExtension(ctx: ParserRuleContext) {
    def meta: mutable.Map[String, Any] = {
      val start = ctx.start.getStartIndex
      val stop = max(ctx.start.getStopIndex, ctx.stop.getStopIndex)
      mutable.Map(
        Meta.Span -> Span(start, stop),
        Meta.Text -> ctx.getText,
        Meta.Line -> ctx.start.getLine,
        Meta.Char -> ctx.start.getCharPositionInLine,
      )
    }

    def text: String = {
      ctx.getText
    }
  }

  implicit class JavaListExtension[T](list: java.util.List[T]) {
    def map[U](transform: T => U)(implicit UT: ClassTag[U]): List[U] = {
      var arr = List[U]()
      list.forEach(arr :+= transform(_))
      arr
    }
  }

  def withMeta[T <: AST](ctx: ParserRuleContext, ast: T): T = {
    ast.meta = ctx.meta
    ast
  }

  def mkTerm(ctx: ParserRuleContext, tag: Tag, data: List[AST]): Term = withMeta(ctx, Term(tag, data))
  def mkLeaf(ctx: ParserRuleContext, tag: Tag, data: Any): Leaf = withMeta(ctx, Leaf(tag, data))
  def mkAtom(ctx: ParserRuleContext, text: String): Atom = withMeta(ctx, Atom(text))


  val impossible = new ANTLRException("ANTLRListener is outdated")
  var program: Option[AST] = None

  override def enterProgram(ctx: ProgramContext): Unit = {
    program = Some(getChunk(ctx.chunk))
  }

  def getChunk(ctx: ChunkContext): Term = {
    mkTerm(ctx, Tag.Block, ctx.expr.map(getExpr))
  }

  def getExpr(ctx: ExprContext): Term = {
    if (!ctx.primary.isEmpty)
      mkTerm(ctx, Tag.Flat, ctx.primary.map(getPrimary))
    else
      throw impossible
  }

  def getPrimary(ctx: PrimaryContext) = {
    if (ctx.call != null)
      getCall(ctx.call)
    else if (ctx.constant != null)
      getConstant(ctx.constant)
    else if (ctx.fun != null)
      getFun(ctx.fun)
    else if (ctx.pragma != null)
      getPragma(ctx.pragma)
    else if (ctx.ifexpr != null)
      getIf(ctx.ifexpr)
    else if (ctx.whexpr != null)
      getWh(ctx.whexpr)
    else if (ctx.expr != null)
      getExpr(ctx.expr)
    else
      throw impossible
  }

  def getIf(ctx: IfexprContext) = {
    var args: List[AST] = ctx.expr.map(getExpr)
    if (args.length == 2) args :+= Atom("()")
    mkTerm(ctx, Tag.Call, Atom("if") :: args)
  }

  def getWh(ctx: WhexprContext) = {
    mkTerm(ctx, Tag.Call, Atom("while") :: ctx.expr.map(getExpr))
  }

  def getFun(ctx: FunContext) = {
    val ret = if (ctx.typ != null) getTyp(ctx.typ) else Leaf(Tag.Type, Types.VOID)
    val body = getChunk(ctx.chunk)
    mkTerm(ctx, Tag.Lambda, body :: ret :: ctx.par.map(getPar))
  }

  def getTyp(ctx: TypContext) = {
    Leaf(Tag.Type, Typ(ctx.atom().getText))
  }

  def getPar(ctx: ParContext) = {
    var data = getAtom(ctx.atom) :: getTyp(ctx.typ) :: Nil
    mkTerm(ctx, Tag.Param, data)
  }

  def getCall(ctx: CallContext) = {
    // TODO: support any Expr on the left-hand side
    val head: AST = if (ctx.atom != null) getAtom(ctx.atom) else getFun(ctx.fun)
    mkTerm(ctx, Tag.Call, head :: ctx.callArg.map(getCallArg))
  }

  def getCallArg(ctx: CallArgContext) = {
    val name = if (ctx.atom != null)  getAtom(ctx.atom) else Zero
    val value = getExpr(ctx.expr)
    mkTerm(ctx, Tag.Arg, value :: name :: Nil)
  }

  def getPragma(ctx: PragmaContext) = {
    if (ctx.call != null) {
      getCall(ctx.call).copy(tag = Tag.Pragma)
    } else if (ctx.atom != null) {
      mkTerm(ctx, Tag.Pragma, getAtom(ctx.atom) :: Nil)
    } else {
      throw impossible
    }
  }

  def getConstant(ctx: ConstantContext) = {
    if (ctx.atom != null)
      getAtom(ctx.atom)
    else if (ctx.intn != null)
      getInt(ctx.intn)
    else if (ctx.real != null)
      getReal(ctx.real)
    else if (ctx.string != null)
      getStr(ctx.string)
    else
      throw impossible
  }

  def getAtom(ctx: AtomContext) = {
    var (meta, text) = (ctx.meta, ctx.text)
    if (text.startsWith("`") && text.endsWith("`")) {
      text = text.stripPrefix("`").stripSuffix("`")
      meta += Meta.QuotedAtom -> true
    }
    val atom = Atom(text)
    atom.meta = meta
    atom
  }

  def getStr(ctx: StringContext) = {
    val text = ctx.text.stripPrefix("\"").stripSuffix("\"")
    mkLeaf(ctx, Tag.String, text)
  }

  def getInt(ctx: IntnContext) = {
    mkLeaf(ctx, Tag.Int, ctx.text.toInt)
  }

  def getReal(ctx: RealContext) = {
    mkLeaf(ctx, Tag.Real, ctx.text.toDouble)
  }

}

