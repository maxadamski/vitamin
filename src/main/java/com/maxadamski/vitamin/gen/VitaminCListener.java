// Generated from C:/Users/Max/Desktop/vitamin/src/main/scala/com/maxadamski/vitamin/parser\VitaminC.g4 by ANTLR 4.7.2
package com.maxadamski.vitamin.gen;
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
	 * Enter a parse tree produced by the {@code exprIf}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void enterExprIf(VitaminCParser.ExprIfContext ctx);
	/**
	 * Exit a parse tree produced by the {@code exprIf}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void exitExprIf(VitaminCParser.ExprIfContext ctx);
	/**
	 * Enter a parse tree produced by the {@code exprWhile}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void enterExprWhile(VitaminCParser.ExprWhileContext ctx);
	/**
	 * Exit a parse tree produced by the {@code exprWhile}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void exitExprWhile(VitaminCParser.ExprWhileContext ctx);
	/**
	 * Enter a parse tree produced by the {@code exprFor}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void enterExprFor(VitaminCParser.ExprForContext ctx);
	/**
	 * Exit a parse tree produced by the {@code exprFor}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void exitExprFor(VitaminCParser.ExprForContext ctx);
	/**
	 * Enter a parse tree produced by the {@code exprUse}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void enterExprUse(VitaminCParser.ExprUseContext ctx);
	/**
	 * Exit a parse tree produced by the {@code exprUse}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void exitExprUse(VitaminCParser.ExprUseContext ctx);
	/**
	 * Enter a parse tree produced by the {@code exprFlat}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void enterExprFlat(VitaminCParser.ExprFlatContext ctx);
	/**
	 * Exit a parse tree produced by the {@code exprFlat}
	 * labeled alternative in {@link VitaminCParser#expr}.
	 * @param ctx the parse tree
	 */
	void exitExprFlat(VitaminCParser.ExprFlatContext ctx);
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
	 * Enter a parse tree produced by {@link VitaminCParser#callee}.
	 * @param ctx the parse tree
	 */
	void enterCallee(VitaminCParser.CalleeContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#callee}.
	 * @param ctx the parse tree
	 */
	void exitCallee(VitaminCParser.CalleeContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#primCall}.
	 * @param ctx the parse tree
	 */
	void enterPrimCall(VitaminCParser.PrimCallContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#primCall}.
	 * @param ctx the parse tree
	 */
	void exitPrimCall(VitaminCParser.PrimCallContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#primList}.
	 * @param ctx the parse tree
	 */
	void enterPrimList(VitaminCParser.PrimListContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#primList}.
	 * @param ctx the parse tree
	 */
	void exitPrimList(VitaminCParser.PrimListContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#primBlock}.
	 * @param ctx the parse tree
	 */
	void enterPrimBlock(VitaminCParser.PrimBlockContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#primBlock}.
	 * @param ctx the parse tree
	 */
	void exitPrimBlock(VitaminCParser.PrimBlockContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#primLambda}.
	 * @param ctx the parse tree
	 */
	void enterPrimLambda(VitaminCParser.PrimLambdaContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#primLambda}.
	 * @param ctx the parse tree
	 */
	void exitPrimLambda(VitaminCParser.PrimLambdaContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#num}.
	 * @param ctx the parse tree
	 */
	void enterNum(VitaminCParser.NumContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#num}.
	 * @param ctx the parse tree
	 */
	void exitNum(VitaminCParser.NumContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#str}.
	 * @param ctx the parse tree
	 */
	void enterStr(VitaminCParser.StrContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#str}.
	 * @param ctx the parse tree
	 */
	void exitStr(VitaminCParser.StrContext ctx);
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
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#symbol}.
	 * @param ctx the parse tree
	 */
	void enterSymbol(VitaminCParser.SymbolContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#symbol}.
	 * @param ctx the parse tree
	 */
	void exitSymbol(VitaminCParser.SymbolContext ctx);
}