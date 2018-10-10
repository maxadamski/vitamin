package com.maxadamski.vitamin

import com.maxadamski.vitamin.AST.{Meta, Tag, Node, Leaf, Tree, Zero}
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

  def parseString(string: String): Tree = {
    parseInput(new ANTLRInputStream(string))
  }

  def parseFile(path: String): Tree = {
    parseInput(new ANTLRFileStream(path))
  }

  def parseInput(input: CharStream): Tree = {
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

  private def mkNode(ctx: ParserRuleContext, tag: Tag.Tag, data: List[Tree]) = Node(tag, data, ctx.meta)

  private def mkLeaf(ctx: ParserRuleContext, tag: Tag.Tag, data: Any) = Leaf(tag, data, ctx.meta)

  val impossible = new ANTLRException("ANTLRListener might be outdated")
  var program: Option[Tree] = None

  override def enterProgram(ctx: ProgramContext): Unit = {
    program = Some(getChunk(ctx.chunk))
  }

  def getChunk(ctx: ChunkContext): Tree = {
    mkNode(ctx, Tag.Block, ctx.expr.map(getExpr))
  }

  def getExpr(ctx: ExprContext): Tree = {
    if (ctx.funExpr != null) {
      getFun(ctx.funExpr)
    } else if (ctx.letExpr != null) {
      val typ = if (ctx.letExpr.`type` != null) getType(ctx.letExpr.`type`) else Zero
      mkNode(ctx, Tag.Let, getAtom(ctx.letExpr.atom) :: typ :: getExpr(ctx.letExpr.expr) :: Nil)
    } else if (ctx.ifExpr != null) {
      val args = ctx.ifExpr.expr.map(getExpr)
      mkNode(ctx, Tag.Call, Leaf(Tag.Atom, "if") :: args)
    } else if (ctx.whileExpr != null) {
      mkNode(ctx, Tag.Call, Leaf(Tag.Atom, "while") :: ctx.whileExpr.expr.map(getExpr))
    } else if (ctx.prim != null) {
        mkNode(ctx, Tag.Flat, ctx.prim.map(getPrim))
    } else {
      throw impossible
    }
  }

  def getPrim(ctx: PrimContext): Tree = {
    if (ctx.argList != null) {
      val args = ctx.argList.argItem.map(getArg)
      mkNode(ctx, Tag.Call, getPrim(ctx.prim) :: args)
    } else if (ctx.atom != null) {
      val node = getAtom(ctx.atom)
      if (ctx.text.startsWith("#")) node.meta += Meta.Directive -> true
      if (ctx.text.startsWith("@")) node.meta += Meta.Annotation -> true
      node
    } else if (ctx.lambda != null) {
      getLambda(ctx.lambda)
    } else if (ctx.literal != null) {
      getLiteral(ctx.literal)
    } else if (ctx.expr != null) {
      getExpr(ctx.expr)
    } else {
      throw impossible
    }
  }

  def getLiteral(ctx: LiteralContext): Tree = {
    if (ctx.vInt != null)
      getInt(ctx.vInt)
    else if (ctx.vFlt != null)
      getFlt(ctx.vFlt)
    else if (ctx.vStr != null)
      getStr(ctx.vStr)
    else if (ctx.array != null)
      getArray(ctx.array)
    else
      throw impossible
  }

  def getPatt(ctx: PattContext): Tree = {
    mkNode(ctx, Tag.TupMatch, ctx.pattPrim.map(getPattPrim))
  }

  def getPattPrim(ctx: PattPrimContext): Tree = {
    if (ctx.text == "_") {
      mkNode(ctx.atom, Tag.AnyMatch, Leaf(Tag.Atom, "_") :: Nil)
    } else if (ctx.atom != null) {
      mkNode(ctx, Tag.VarMatch, getAtom(ctx.atom) :: Nil)
    } else if (ctx.patt != null) {
      getPatt (ctx.patt)
    } else {
      throw impossible
    }
  }

  def getFun(ctx: FunExprContext): Tree = {
    val name = getAtom(ctx.atom)
    val typ = if(ctx.`type` != null) getType(ctx.`type`) else mkNode(ctx, Tag.ConType, Leaf(Tag.Atom, "Void") :: Nil)
    val body = getChunk(ctx.chunk)
    val par = ctx.parList.parItem.map(getParItem)
    val gen = ctx.genList.genItem.map(getGenItem)
    mkNode(ctx, Tag.Fun, name :: body :: typ :: par ++ gen)
  }

  def getGenItem(ctx: GenItemContext): Tree = {
    if (ctx.atom != null) {
      getAtom(ctx.atom)
    } else {
      throw impossible
    }
  }

  def getParItem(ctx: ParItemContext): Tree = {
    val name = getAtom(ctx.atom)
    val expr = if(ctx.expr != null) getExpr(ctx.expr) else Zero
    val typ = getType(ctx.parType.`type`)
    if (ctx.parType.text.endsWith("...")) typ.meta += Meta.Rest -> true
    mkNode(ctx, Tag.Param, name :: typ :: expr :: Nil)
  }

  def getType(ctx: TypeContext): Tree = {
    if (ctx.text == "()") {
      return mkNode(ctx, Tag.ConType, Leaf(Tag.Atom, "()") :: Nil)
    }

    val args = ctx.`type`.map(getType)
    if (ctx.atom != null) {
      val name = getAtom(ctx.atom)
      mkNode(ctx, Tag.ConType, name :: args)
    } else if (args.length == 2) {
      mkNode(ctx, Tag.FunType, args)
    } else if (args.length == 1) {
      args(0)
    } else {
      throw impossible
    }
  }

  def getArg(ctx: ArgItemContext): Tree = {
    val name = if (ctx.atom != null) getAtom(ctx.atom) else Zero
    val value = getExpr(ctx.expr)
    mkNode(ctx, Tag.Arg, value :: name :: Nil)
  }

  def getLambda(ctx: LambdaContext): Tree = {
    val patt = if (ctx.patt != null) getPatt(ctx.patt) else Zero
    mkNode(ctx, Tag.Lambda, patt :: getChunk(ctx.chunk) :: Nil)
  }

  def getAtom(ctx: AtomContext): Leaf = {
    var (meta, text) = (ctx.meta, ctx.text)
    if (text.startsWith("`") && text.endsWith("`")) {
      text = text.stripPrefix("`").stripSuffix("`")
      meta += Meta.Escaped -> true
    }
    Leaf(Tag.Atom, text, meta)
  }

  def getArray(ctx: ArrayContext): Node = mkNode(ctx, Tag.Array, ctx.expr.map(getExpr))

  def getStr(ctx: VStrContext): Leaf = mkLeaf(ctx, Tag.String, ctx.text.stripPrefix("\"").stripSuffix("\""))

  def getInt(ctx: VIntContext): Leaf = mkLeaf(ctx, Tag.Int, ctx.text.toInt)

  def getFlt(ctx: VFltContext): Leaf = mkLeaf(ctx, Tag.Real, ctx.text.toDouble)

}

