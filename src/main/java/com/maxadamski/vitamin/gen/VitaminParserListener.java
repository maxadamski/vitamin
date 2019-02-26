// Generated from C:/Users/Max/Desktop/vitamin/src/main/scala/com/maxadamski/vitamin/parser\VitaminParser.g4 by ANTLR 4.7.2
package com.maxadamski.vitamin.gen;
import org.antlr.v4.runtime.tree.ParseTreeListener;

/**
 * This interface defines a complete listener for a parse tree produced by
 * {@link VitaminParser}.
 */
public interface VitaminParserListener extends ParseTreeListener {
	/**
	 * Enter a parse tree produced by {@link VitaminParser#file}.
	 * @param ctx the parse tree
	 */
	void enterFile(VitaminParser.FileContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#file}.
	 * @param ctx the parse tree
	 */
	void exitFile(VitaminParser.FileContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#body}.
	 * @param ctx the parse tree
	 */
	void enterBody(VitaminParser.BodyContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#body}.
	 * @param ctx the parse tree
	 */
	void exitBody(VitaminParser.BodyContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#expr}.
	 * @param ctx the parse tree
	 */
	void enterExpr(VitaminParser.ExprContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#expr}.
	 * @param ctx the parse tree
	 */
	void exitExpr(VitaminParser.ExprContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#prim}.
	 * @param ctx the parse tree
	 */
	void enterPrim(VitaminParser.PrimContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#prim}.
	 * @param ctx the parse tree
	 */
	void exitPrim(VitaminParser.PrimContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#call}.
	 * @param ctx the parse tree
	 */
	void enterCall(VitaminParser.CallContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#call}.
	 * @param ctx the parse tree
	 */
	void exitCall(VitaminParser.CallContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#list}.
	 * @param ctx the parse tree
	 */
	void enterList(VitaminParser.ListContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#list}.
	 * @param ctx the parse tree
	 */
	void exitList(VitaminParser.ListContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#func}.
	 * @param ctx the parse tree
	 */
	void enterFunc(VitaminParser.FuncContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#func}.
	 * @param ctx the parse tree
	 */
	void exitFunc(VitaminParser.FuncContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#atom}.
	 * @param ctx the parse tree
	 */
	void enterAtom(VitaminParser.AtomContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#atom}.
	 * @param ctx the parse tree
	 */
	void exitAtom(VitaminParser.AtomContext ctx);
	/**
	 * Enter a parse tree produced by {@link VitaminParser#lite}.
	 * @param ctx the parse tree
	 */
	void enterLite(VitaminParser.LiteContext ctx);
	/**
	 * Exit a parse tree produced by {@link VitaminParser#lite}.
	 * @param ctx the parse tree
	 */
	void exitLite(VitaminParser.LiteContext ctx);
}