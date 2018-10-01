package com.maxadamski.vitamin

import com.maxadamski.vitamin.Types.{AType, Typ}
import com.maxadamski.vparser._
import com.maxadamski.vparser.VitaminCParser._
import org.antlr.v4.runtime._
import org.antlr.v4.runtime.tree._

import math.max
import scala.reflect.ClassTag

class ANTLRException(message: String) extends Exception

object Parser {
  def parseFile(path: String): Syntax = {
    val input = new ANTLRFileStream(path)
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
    def meta: Map[String, Any] = {
      val start = ctx.start.getStartIndex
      val stop = max(ctx.start.getStopIndex, ctx.stop.getStopIndex)
      Map(
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

  val impossible = new ANTLRException("ANTLRListener is outdated")
  var program: Option[Syntax] = None

  override def enterProgram(ctx: ProgramContext): Unit = {
    program = Some(getChunk(ctx.chunk))
  }

  def getChunk(ctx: ChunkContext): Node = {
    Node(Tag.Block, ctx.expr.map(getExpr))
  }

  def getExpr(ctx: ExprContext): Node = {
    if (!ctx.primary.isEmpty)
      Node(Tag.Flat, ctx.primary.map(getPrimary))
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
    var args = ctx.expr.map(getExpr)
    if (args.length == 2) args :+= Atom("()")
    Call(Atom("if"), args)
  }

  def getWh(ctx: WhexprContext) = {
    Call(Atom("while"), ctx.expr.map(getExpr))
  }


  def getFun(ctx: FunContext) = {
    val ret = if (ctx.typ != null) getTyp(ctx.typ) else TypNode(Types.VOID)
    FunNode(getChunk(ctx.chunk), ret, ctx.par.map(getPar))
  }

  def getPar(ctx: ParContext) = {
    ParNode(getAtom(ctx.atom), getTyp(ctx.typ))
  }

  def getTyp(ctx: TypContext) = {
    TypNode(Types.Typ(ctx.atom().getText))
  }

  def getCall(ctx: CallContext) = {
    val head = if (ctx.atom != null) getAtom(ctx.atom) else getFun(ctx.fun)
    Call(head, ctx.callArg.map(getCallArg))
  }

  def getCallArg(ctx: CallArgContext) = {
    val expr = getExpr(ctx.expr)
    if (ctx.atom != null)
      ArgNode(getAtom(ctx.atom), expr)
    else
      expr
  }

  def getPragma(ctx: PragmaContext) = {
    if (ctx.call != null)
      getCall(ctx.call)
    else if (ctx.atom != null)
      Call(getAtom(ctx.atom), List())
    else
      throw impossible
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
    Atom(text)
  }

  def getStr(ctx: StringContext) = {
    val text = ctx.text.stripPrefix("\"").stripSuffix("\"")
    StrLit(text)
  }

  def getInt(ctx: IntnContext) = {
    IntLit(ctx.text.toInt)
  }

  def getReal(ctx: RealContext) = {
    RealLit(ctx.text.toDouble)
  }

}

