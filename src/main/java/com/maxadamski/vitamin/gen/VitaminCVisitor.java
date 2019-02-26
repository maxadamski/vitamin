// Generated from C:/Users/Max/Desktop/vitamin/src/main/scala/com/maxadamski/vitamin/parser\VitaminC.g4 by ANTLR 4.7.2
package com.maxadamski.vitamin.gen;
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
	 * Visit a parse tree produced by the {@code exprIf}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitExprIf(VitaminCParser.ExprIfContext ctx);
	/**
	 * Visit a parse tree produced by the {@code exprWhile}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitExprWhile(VitaminCParser.ExprWhileContext ctx);
	/**
	 * Visit a parse tree produced by the {@code exprFor}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitExprFor(VitaminCParser.ExprForContext ctx);
	/**
	 * Visit a parse tree produced by the {@code exprUse}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitExprUse(VitaminCParser.ExprUseContext ctx);
	/**
	 * Visit a parse tree produced by the {@code exprFlat}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitExprFlat(VitaminCParser.ExprFlatContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#prim}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPrim(VitaminCParser.PrimContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#callee}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitCallee(VitaminCParser.CalleeContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#primCall}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPrimCall(VitaminCParser.PrimCallContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#primList}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPrimList(VitaminCParser.PrimListContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#primBlock}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPrimBlock(VitaminCParser.PrimBlockContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#primLambda}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPrimLambda(VitaminCParser.PrimLambdaContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#num}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitNum(VitaminCParser.NumContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#str}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitStr(VitaminCParser.StrContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#atom}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitAtom(VitaminCParser.AtomContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminCParser#symbol}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitSymbol(VitaminCParser.SymbolContext ctx);
}