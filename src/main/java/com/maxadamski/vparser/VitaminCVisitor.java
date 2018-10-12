// Generated from /home/max/Documents/vitamin/res/VitaminC.g4 by ANTLR 4.7
package com.maxadamski.vparser;
import org.antlr.v4.runtime.tree.ParseTreeVisitor;

/**
 * This interface defines a complete generic visitor for a parse tree produced
 * by {@link VitaminCParser}.
 *
 * @param <T> The return type of the visit operation. Use {@link Void} for
 * operations with no return type.
 */
public interface VitaminCVisitor<T> extends ParseTreeVisitor<T> {
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#program}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitProgram(VitaminCParser.ProgramContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#chunk}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitChunk(VitaminCParser.ChunkContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitExpr(VitaminCParser.ExprContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#prim}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPrim(VitaminCParser.PrimContext ctx);
	/**
	 * Visit a parse tree produced by the {@code lambdaType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitLambdaType(VitaminCParser.LambdaTypeContext ctx);
	/**
	 * Visit a parse tree produced by the {@code naryType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitNaryType(VitaminCParser.NaryTypeContext ctx);
	/**
	 * Visit a parse tree produced by the {@code tupleType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitTupleType(VitaminCParser.TupleTypeContext ctx);
	/**
	 * Visit a parse tree produced by the {@code parenthesisType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitParenthesisType(VitaminCParser.ParenthesisTypeContext ctx);
	/**
	 * Visit a parse tree produced by the {@code nullType}
	 * labeled alternative in {@link VitaminCParser#type}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitNullType(VitaminCParser.NullTypeContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#patt}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPatt(VitaminCParser.PattContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#pattPrim}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPattPrim(VitaminCParser.PattPrimContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#letExpr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitLetExpr(VitaminCParser.LetExprContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#ifExpr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitIfExpr(VitaminCParser.IfExprContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#whileExpr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitWhileExpr(VitaminCParser.WhileExprContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#genItem}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitGenItem(VitaminCParser.GenItemContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#genList}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitGenList(VitaminCParser.GenListContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#parType}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitParType(VitaminCParser.ParTypeContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#parItem}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitParItem(VitaminCParser.ParItemContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#parList}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitParList(VitaminCParser.ParListContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#funExpr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitFunExpr(VitaminCParser.FunExprContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#argItem}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitArgItem(VitaminCParser.ArgItemContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#argList}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitArgList(VitaminCParser.ArgListContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#lambda}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitLambda(VitaminCParser.LambdaContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#array}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitArray(VitaminCParser.ArrayContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#literal}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitLiteral(VitaminCParser.LiteralContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#vInt}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitVInt(VitaminCParser.VIntContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#vStr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitVStr(VitaminCParser.VStrContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#vFlt}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitVFlt(VitaminCParser.VFltContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#atom}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitAtom(VitaminCParser.AtomContext ctx);
}