package com.maxadamski.vitamin

import com.maxadamski.vparser._
import com.maxadamski.vparser.VitaminCParser._
import org.antlr.v4.runtime._
import org.antlr.v4.runtime.tree._

import math.max
import scala.reflect.ClassTag

class ANTLRException(message: String) extends Exception

object Parser {
  def parseFile(path: String): AST = {
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
      Map(Meta.Span -> Span(start, stop), Meta.Text -> ctx.getText)
    }

    def text: String = {
      ctx.getText
    }
  }

  implicit class JavaListExtension[T](list: java.util.List[T]) {
    def mapArray[U](transform: T => U)(implicit UT: ClassTag[U]): Array[U] = {
      var arr = Array[U]()
      list.forEach(arr :+= transform(_))
      arr
    }
  }

  val impossible = new ANTLRException("ANTLRListener is outdated")
  var program: Option[AST] = None

  override def enterProgram(ctx: ProgramContext): Unit = {
    program = Some(getChunk(ctx.chunk))
  }

  def getChunk(ctx: ChunkContext): AST = {
    AST(Tag.Block, Node(ctx.expr.mapArray(getExpr)), ctx.meta)
  }

  def getExpr(ctx: ExprContext): AST = {
    if (!ctx.primary.isEmpty)
      AST(Tag.Flat, Node(ctx.primary.mapArray(getPrimary)), ctx.meta)
    else
      throw impossible
  }

  def getPrimary(ctx: PrimaryContext): AST = {
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
    else if (ctx.expr != null)
      getExpr(ctx.expr)
    else
      throw impossible
  }

  def getIf(ctx: IfexprContext): AST = {
    val func = AST(Tag.Atom, Leaf("if"))
    var args = ctx.expr.mapArray(getExpr)
    if (args.length == 2) args :+= AST(Tag.Atom, Leaf("()"))
    AST(Tag.Call, Node(Array(func, args(0), args(1), args(2))), ctx.meta)
  }

  def getFun(ctx: FunContext): AST = {
    AST(Tag.Lambda, Node(ctx.atom.mapArray(getAtom) :+ getChunk(ctx.chunk)), ctx.meta)
  }

  def getCall(ctx: CallContext): AST = {
    AST(Tag.Call, Node(getAtom(ctx.atom) +: ctx.callArg.mapArray(getCallArg)), ctx.meta)
  }

  def getCallArg(ctx: CallArgContext): AST = {
    var data = Array(getExpr(ctx.expr))
    if (ctx.atom != null) data +:= getAtom(ctx.atom)
    AST(Tag.Arg, Node(data), ctx.meta)
  }

  def getPragma(ctx: PragmaContext): AST = {
    if (ctx.call != null)
      AST(Tag.Pragma, getCall(ctx.call).data, ctx.meta)
    else if (ctx.atom != null)
      AST(Tag.Pragma, Node(Array(getAtom(ctx.atom))), ctx.meta)
    else
      throw impossible
  }

  def getConstant(ctx: ConstantContext): AST = {
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

  def getAtom(ctx: AtomContext): AST = {
    var (meta, text) = (ctx.meta, ctx.text)
    if (text.startsWith("`") && text.endsWith("`")) {
      text = text.stripPrefix("`").stripSuffix("`")
      meta += Meta.QuotedAtom -> true
    }
    AST(Tag.Atom, Leaf(text), meta)
  }

  def getStr(ctx: StringContext): AST = {
    val text = ctx.text.stripPrefix("\"").stripSuffix("\"")
    AST(Tag.String, Leaf(text), ctx.meta)
  }

  def getInt(ctx: IntnContext): AST = {
    AST(Tag.Int, Leaf(ctx.text.toInt), ctx.meta)
  }

  def getReal(ctx: RealContext): AST = {
    AST(Tag.Int, Leaf(ctx.text.toDouble), ctx.meta)
  }

}

