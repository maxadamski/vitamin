// Generated from /home/max/Documents/vitamin/res/VitaminC.g4 by ANTLR 4.7
package com.maxadamski.vparser;
import org.antlr.v4.runtime.tree.ParseTreeListener;

/**
 * This interface defines a complete listener for a parse tree produced by
 * {@link VitaminCParser}.
 */
public interface VitaminCListener extends ParseTreeListener {
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#program}.
	 * @param ctx the parse tree
	 */
	void enterProgram(VitaminCParser.ProgramContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#program}.
	 * @param ctx the parse tree
	 */
	void exitProgram(VitaminCParser.ProgramContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#chunk}.
	 * @param ctx the parse tree
	 */
	void enterChunk(VitaminCParser.ChunkContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#chunk}.
	 * @param ctx the parse tree
	 */
	void exitChunk(VitaminCParser.ChunkContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void enterExpr(VitaminCParser.ExprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void exitExpr(VitaminCParser.ExprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#prim}.
	 * @param ctx the parse tree
	 */
	void enterPrim(VitaminCParser.PrimContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#prim}.
	 * @param ctx the parse tree
	 */
	void exitPrim(VitaminCParser.PrimContext ctx);
	/**
	 * Enter a parse tree produced by the {@code lambdaType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void enterLambdaType(VitaminCParser.LambdaTypeContext ctx);
	/**
	 * Exit a parse tree produced by the {@code lambdaType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void exitLambdaType(VitaminCParser.LambdaTypeContext ctx);
	/**
	 * Enter a parse tree produced by the {@code naryType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void enterNaryType(VitaminCParser.NaryTypeContext ctx);
	/**
	 * Exit a parse tree produced by the {@code naryType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void exitNaryType(VitaminCParser.NaryTypeContext ctx);
	/**
	 * Enter a parse tree produced by the {@code tupleType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void enterTupleType(VitaminCParser.TupleTypeContext ctx);
	/**
	 * Exit a parse tree produced by the {@code tupleType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void exitTupleType(VitaminCParser.TupleTypeContext ctx);
	/**
	 * Enter a parse tree produced by the {@code parenthesisType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void enterParenthesisType(VitaminCParser.ParenthesisTypeContext ctx);
	/**
	 * Exit a parse tree produced by the {@code parenthesisType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void exitParenthesisType(VitaminCParser.ParenthesisTypeContext ctx);
	/**
	 * Enter a parse tree produced by the {@code nullType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void enterNullType(VitaminCParser.NullTypeContext ctx);
	/**
	 * Exit a parse tree produced by the {@code nullType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 */
	void exitNullType(VitaminCParser.NullTypeContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#patt}.
	 * @param ctx the parse tree
	 */
	void enterPatt(VitaminCParser.PattContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#patt}.
	 * @param ctx the parse tree
	 */
	void exitPatt(VitaminCParser.PattContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#pattPrim}.
	 * @param ctx the parse tree
	 */
	void enterPattPrim(VitaminCParser.PattPrimContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#pattPrim}.
	 * @param ctx the parse tree
	 */
	void exitPattPrim(VitaminCParser.PattPrimContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#letExpr}.
	 * @param ctx the parse tree
	 */
	void enterLetExpr(VitaminCParser.LetExprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#letExpr}.
	 * @param ctx the parse tree
	 */
	void exitLetExpr(VitaminCParser.LetExprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#ifExpr}.
	 * @param ctx the parse tree
	 */
	void enterIfExpr(VitaminCParser.IfExprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#ifExpr}.
	 * @param ctx the parse tree
	 */
	void exitIfExpr(VitaminCParser.IfExprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#whileExpr}.
	 * @param ctx the parse tree
	 */
	void enterWhileExpr(VitaminCParser.WhileExprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#whileExpr}.
	 * @param ctx the parse tree
	 */
	void exitWhileExpr(VitaminCParser.WhileExprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#genItem}.
	 * @param ctx the parse tree
	 */
	void enterGenItem(VitaminCParser.GenItemContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#genItem}.
	 * @param ctx the parse tree
	 */
	void exitGenItem(VitaminCParser.GenItemContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#genList}.
	 * @param ctx the parse tree
	 */
	void enterGenList(VitaminCParser.GenListContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#genList}.
	 * @param ctx the parse tree
	 */
	void exitGenList(VitaminCParser.GenListContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#parType}.
	 * @param ctx the parse tree
	 */
	void enterParType(VitaminCParser.ParTypeContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#parType}.
	 * @param ctx the parse tree
	 */
	void exitParType(VitaminCParser.ParTypeContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#parItem}.
	 * @param ctx the parse tree
	 */
	void enterParItem(VitaminCParser.ParItemContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#parItem}.
	 * @param ctx the parse tree
	 */
	void exitParItem(VitaminCParser.ParItemContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#parList}.
	 * @param ctx the parse tree
	 */
	void enterParList(VitaminCParser.ParListContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#parList}.
	 * @param ctx the parse tree
	 */
	void exitParList(VitaminCParser.ParListContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#funExpr}.
	 * @param ctx the parse tree
	 */
	void enterFunExpr(VitaminCParser.FunExprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#funExpr}.
	 * @param ctx the parse tree
	 */
	void exitFunExpr(VitaminCParser.FunExprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#argItem}.
	 * @param ctx the parse tree
	 */
	void enterArgItem(VitaminCParser.ArgItemContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#argItem}.
	 * @param ctx the parse tree
	 */
	void exitArgItem(VitaminCParser.ArgItemContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#argList}.
	 * @param ctx the parse tree
	 */
	void enterArgList(VitaminCParser.ArgListContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#argList}.
	 * @param ctx the parse tree
	 */
	void exitArgList(VitaminCParser.ArgListContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#lambda}.
	 * @param ctx the parse tree
	 */
	void enterLambda(VitaminCParser.LambdaContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#lambda}.
	 * @param ctx the parse tree
	 */
	void exitLambda(VitaminCParser.LambdaContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#array}.
	 * @param ctx the parse tree
	 */
	void enterArray(VitaminCParser.ArrayContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#array}.
	 * @param ctx the parse tree
	 */
	void exitArray(VitaminCParser.ArrayContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#literal}.
	 * @param ctx the parse tree
	 */
	void enterLiteral(VitaminCParser.LiteralContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#literal}.
	 * @param ctx the parse tree
	 */
	void exitLiteral(VitaminCParser.LiteralContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#vInt}.
	 * @param ctx the parse tree
	 */
	void enterVInt(VitaminCParser.VIntContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#vInt}.
	 * @param ctx the parse tree
	 */
	void exitVInt(VitaminCParser.VIntContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#vStr}.
	 * @param ctx the parse tree
	 */
	void enterVStr(VitaminCParser.VStrContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#vStr}.
	 * @param ctx the parse tree
	 */
	void exitVStr(VitaminCParser.VStrContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#vFlt}.
	 * @param ctx the parse tree
	 */
	void enterVFlt(VitaminCParser.VFltContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#vFlt}.
	 * @param ctx the parse tree
	 */
	void exitVFlt(VitaminCParser.VFltContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#atom}.
	 * @param ctx the parse tree
	 */
	void enterAtom(VitaminCParser.AtomContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#atom}.
	 * @param ctx the parse tree
	 */
	void exitAtom(VitaminCParser.AtomContext ctx);
}