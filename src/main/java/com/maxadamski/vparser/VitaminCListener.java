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
	 * Enter a parse tree produced by {@link VitaminCParser#primary}.
	 * @param ctx the parse tree
	 */
	void enterPrimary(VitaminCParser.PrimaryContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#primary}.
	 * @param ctx the parse tree
	 */
	void exitPrimary(VitaminCParser.PrimaryContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#ifexpr}.
	 * @param ctx the parse tree
	 */
	void enterIfexpr(VitaminCParser.IfexprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#ifexpr}.
	 * @param ctx the parse tree
	 */
	void exitIfexpr(VitaminCParser.IfexprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#whexpr}.
	 * @param ctx the parse tree
	 */
	void enterWhexpr(VitaminCParser.WhexprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#whexpr}.
	 * @param ctx the parse tree
	 */
	void exitWhexpr(VitaminCParser.WhexprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#fun}.
	 * @param ctx the parse tree
	 */
	void enterFun(VitaminCParser.FunContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#fun}.
	 * @param ctx the parse tree
	 */
	void exitFun(VitaminCParser.FunContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#call}.
	 * @param ctx the parse tree
	 */
	void enterCall(VitaminCParser.CallContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#call}.
	 * @param ctx the parse tree
	 */
	void exitCall(VitaminCParser.CallContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#callArg}.
	 * @param ctx the parse tree
	 */
	void enterCallArg(VitaminCParser.CallArgContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#callArg}.
	 * @param ctx the parse tree
	 */
	void exitCallArg(VitaminCParser.CallArgContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#pragma}.
	 * @param ctx the parse tree
	 */
	void enterPragma(VitaminCParser.PragmaContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#pragma}.
	 * @param ctx the parse tree
	 */
	void exitPragma(VitaminCParser.PragmaContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#constant}.
	 * @param ctx the parse tree
	 */
	void enterConstant(VitaminCParser.ConstantContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#constant}.
	 * @param ctx the parse tree
	 */
	void exitConstant(VitaminCParser.ConstantContext ctx);
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
	 * Enter a parse tree produced by {@link VitaminCParser#intn}.
	 * @param ctx the parse tree
	 */
	void enterIntn(VitaminCParser.IntnContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#intn}.
	 * @param ctx the parse tree
	 */
	void exitIntn(VitaminCParser.IntnContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#real}.
	 * @param ctx the parse tree
	 */
	void enterReal(VitaminCParser.RealContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#real}.
	 * @param ctx the parse tree
	 */
	void exitReal(VitaminCParser.RealContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminCParser#string}.
	 * @param ctx the parse tree
	 */
	void enterString(VitaminCParser.StringContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminCParser#string}.
	 * @param ctx the parse tree
	 */
	void exitString(VitaminCParser.StringContext ctx);
}