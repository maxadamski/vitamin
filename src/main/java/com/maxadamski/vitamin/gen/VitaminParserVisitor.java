// Generated from C:/Users/Max/Desktop/vitamin/src/main/scala/com/maxadamski/vitamin/parser\VitaminParser.g4 by ANTLR 4.7.2
package com.maxadamski.vitamin.gen;
import org.antlr.v4.runtime.tree.ParseTreeVisitor;

/**
 * This interface defines a complete generic visitor for a parse tree produced
 * by {@link VitaminParser}.
 *
 * @param <T> The return type of the visit operation. Use {@link Void} for
 * operations with no return type.
 */
public interface VitaminParserVisitor<T> extends ParseTreeVisitor<T> {
	/**
	 * Visit a parse tree produced by {@link VitaminParser#file}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitFile(VitaminParser.FileContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#body}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitBody(VitaminParser.BodyContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#expr}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitExpr(VitaminParser.ExprContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#prim}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitPrim(VitaminParser.PrimContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#call}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitCall(VitaminParser.CallContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#list}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitList(VitaminParser.ListContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#func}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitFunc(VitaminParser.FuncContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#atom}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitAtom(VitaminParser.AtomContext ctx);
	/**
	 * Visit a parse tree produced by {@link VitaminParser#lite}.
	 * @param ctx the parse tree
	 * @return the visitor result
	 */
	T visitLite(VitaminParser.LiteContext ctx);
}