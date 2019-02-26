// Generated from C:/Users/Max/Desktop/vitamin/src/main/scala/com/maxadamski/vitamin/parser\VitaminParser.g4 by ANTLR 4.7.2
package com.maxadamski.vitamin.gen;
import org.antlr.v4.runtime.atn.*;
import org.antlr.v4.runtime.dfa.DFA;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.misc.*;
import org.antlr.v4.runtime.tree.*;
import java.util.List;
import java.util.Iterator;
import java.util.ArrayList;

@SuppressWarnings({"all", "warnings", "unchecked", "unused", "cast"})
public class VitaminParser extends Parser {
	static { RuntimeMetaData.checkVersion("4.7.2", RuntimeMetaData.VERSION); }

	protected static final DFA[] _decisionToDFA;
	protected static final PredictionContextCache _sharedContextCache =
		new PredictionContextCache();
	public static final int
		Shebang=1, NL=2, WS=3, Num1=4, Num2=5, Str1=6, Str2=7, Comment1=8, Comment2=9, 
		Symb=10, Atom=11, IN=12, SEMI=13, COMMA=14, QUASI=15, LBRACE=16, RBRACE=17, 
		LBRACK=18, RBRACK=19, LPAREN=20, RPAREN=21;
	public static final int
		RULE_file = 0, RULE_body = 1, RULE_expr = 2, RULE_prim = 3, RULE_call = 4, 
		RULE_list = 5, RULE_func = 6, RULE_atom = 7, RULE_lite = 8;
	private static String[] makeRuleNames() {
		return new String[] {
			"file", "body", "expr", "prim", "call", "list", "func", "atom", "lite"
		};
	}
	public static final String[] ruleNames = makeRuleNames();

	private static String[] makeLiteralNames() {
		return new String[] {
			null, null, null, null, null, null, null, null, null, null, null, null, 
			"'in'", "';'", "','", "'`'", "'{'", "'}'", "'['", "']'", "'('", "')'"
		};
	}
	private static final String[] _LITERAL_NAMES = makeLiteralNames();
	private static String[] makeSymbolicNames() {
		return new String[] {
			null, "Shebang", "NL", "WS", "Num1", "Num2", "Str1", "Str2", "Comment1", 
			"Comment2", "Symb", "Atom", "IN", "SEMI", "COMMA", "QUASI", "LBRACE", 
			"RBRACE", "LBRACK", "RBRACK", "LPAREN", "RPAREN"
		};
	}
	private static final String[] _SYMBOLIC_NAMES = makeSymbolicNames();
	public static final Vocabulary VOCABULARY = new VocabularyImpl(_LITERAL_NAMES, _SYMBOLIC_NAMES);

	/**
	 * @deprecated Use {@link #VOCABULARY} instead.
	 */
	@Deprecated
	public static final String[] tokenNames;
	static {
		tokenNames = new String[_SYMBOLIC_NAMES.length];
		for (int i = 0; i < tokenNames.length; i++) {
			tokenNames[i] = VOCABULARY.getLiteralName(i);
			if (tokenNames[i] == null) {
				tokenNames[i] = VOCABULARY.getSymbolicName(i);
			}

			if (tokenNames[i] == null) {
				tokenNames[i] = "<INVALID>";
			}
		}
	}

	@Override
	@Deprecated
	public String[] getTokenNames() {
		return tokenNames;
	}

	@Override

	public Vocabulary getVocabulary() {
		return VOCABULARY;
	}

	@Override
	public String getGrammarFileName() { return "VitaminParser.g4"; }

	@Override
	public String[] getRuleNames() { return ruleNames; }

	@Override
	public String getSerializedATN() { return _serializedATN; }

	@Override
	public ATN getATN() { return _ATN; }

	public VitaminParser(TokenStream input) {
		super(input);
		_interp = new ParserATNSimulator(this,_ATN,_decisionToDFA,_sharedContextCache);
	}

	public static class FileContext extends ParserRuleContext {
		public BodyContext body() {
			return getRuleContext(BodyContext.class,0);
		}
		public TerminalNode EOF() { return getToken(VitaminParser.EOF, 0); }
		public FileContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_file; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterFile(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitFile(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitFile(this);
			else return visitor.visitChildren(this);
		}
	}

	public final FileContext file() throws RecognitionException {
		FileContext _localctx = new FileContext(_ctx, getState());
		enterRule(_localctx, 0, RULE_file);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(18);
			body();
			setState(19);
			match(EOF);
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class BodyContext extends ParserRuleContext {
		public List<ExprContext> expr() {
			return getRuleContexts(ExprContext.class);
		}
		public ExprContext expr(int i) {
			return getRuleContext(ExprContext.class,i);
		}
		public List<TerminalNode> SEMI() { return getTokens(VitaminParser.SEMI); }
		public TerminalNode SEMI(int i) {
			return getToken(VitaminParser.SEMI, i);
		}
		public BodyContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_body; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterBody(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitBody(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitBody(this);
			else return visitor.visitChildren(this);
		}
	}

	public final BodyContext body() throws RecognitionException {
		BodyContext _localctx = new BodyContext(_ctx, getState());
		enterRule(_localctx, 2, RULE_body);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(22);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << Num1) | (1L << Num2) | (1L << Str1) | (1L << Str2) | (1L << Symb) | (1L << Atom) | (1L << QUASI) | (1L << LBRACE) | (1L << LPAREN))) != 0)) {
				{
				setState(21);
				expr();
				}
			}

			setState(28);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,1,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(24);
					match(SEMI);
					setState(25);
					expr();
					}
					} 
				}
				setState(30);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,1,_ctx);
			}
			setState(34);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==SEMI) {
				{
				{
				setState(31);
				match(SEMI);
				}
				}
				setState(36);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class ExprContext extends ParserRuleContext {
		public List<PrimContext> prim() {
			return getRuleContexts(PrimContext.class);
		}
		public PrimContext prim(int i) {
			return getRuleContext(PrimContext.class,i);
		}
		public ExprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_expr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterExpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitExpr(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitExpr(this);
			else return visitor.visitChildren(this);
		}
	}

	public final ExprContext expr() throws RecognitionException {
		ExprContext _localctx = new ExprContext(_ctx, getState());
		enterRule(_localctx, 4, RULE_expr);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(38); 
			_errHandler.sync(this);
			_la = _input.LA(1);
			do {
				{
				{
				setState(37);
				prim();
				}
				}
				setState(40); 
				_errHandler.sync(this);
				_la = _input.LA(1);
			} while ( (((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << Num1) | (1L << Num2) | (1L << Str1) | (1L << Str2) | (1L << Symb) | (1L << Atom) | (1L << QUASI) | (1L << LBRACE) | (1L << LPAREN))) != 0) );
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class PrimContext extends ParserRuleContext {
		public CallContext call() {
			return getRuleContext(CallContext.class,0);
		}
		public List<ListContext> list() {
			return getRuleContexts(ListContext.class);
		}
		public ListContext list(int i) {
			return getRuleContext(ListContext.class,i);
		}
		public FuncContext func() {
			return getRuleContext(FuncContext.class,0);
		}
		public LiteContext lite() {
			return getRuleContext(LiteContext.class,0);
		}
		public PrimContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_prim; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterPrim(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitPrim(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitPrim(this);
			else return visitor.visitChildren(this);
		}
	}

	public final PrimContext prim() throws RecognitionException {
		PrimContext _localctx = new PrimContext(_ctx, getState());
		enterRule(_localctx, 6, RULE_prim);
		try {
			int _alt;
			setState(54);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case Atom:
			case QUASI:
			case LBRACE:
			case LPAREN:
				enterOuterAlt(_localctx, 1);
				{
				setState(42);
				call();
				setState(51);
				_errHandler.sync(this);
				switch ( getInterpreter().adaptivePredict(_input,6,_ctx) ) {
				case 1:
					{
					setState(44); 
					_errHandler.sync(this);
					_alt = 1;
					do {
						switch (_alt) {
						case 1:
							{
							{
							setState(43);
							list();
							}
							}
							break;
						default:
							throw new NoViableAltException(this);
						}
						setState(46); 
						_errHandler.sync(this);
						_alt = getInterpreter().adaptivePredict(_input,4,_ctx);
					} while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER );
					setState(49);
					_errHandler.sync(this);
					switch ( getInterpreter().adaptivePredict(_input,5,_ctx) ) {
					case 1:
						{
						setState(48);
						func();
						}
						break;
					}
					}
					break;
				}
				}
				break;
			case Num1:
			case Num2:
			case Str1:
			case Str2:
			case Symb:
				enterOuterAlt(_localctx, 2);
				{
				setState(53);
				lite();
				}
				break;
			default:
				throw new NoViableAltException(this);
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class CallContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public FuncContext func() {
			return getRuleContext(FuncContext.class,0);
		}
		public ListContext list() {
			return getRuleContext(ListContext.class,0);
		}
		public CallContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_call; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterCall(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitCall(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitCall(this);
			else return visitor.visitChildren(this);
		}
	}

	public final CallContext call() throws RecognitionException {
		CallContext _localctx = new CallContext(_ctx, getState());
		enterRule(_localctx, 8, RULE_call);
		try {
			setState(59);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case Atom:
			case QUASI:
				enterOuterAlt(_localctx, 1);
				{
				setState(56);
				atom();
				}
				break;
			case LBRACE:
				enterOuterAlt(_localctx, 2);
				{
				setState(57);
				func();
				}
				break;
			case LPAREN:
				enterOuterAlt(_localctx, 3);
				{
				setState(58);
				list();
				}
				break;
			default:
				throw new NoViableAltException(this);
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class ListContext extends ParserRuleContext {
		public TerminalNode LPAREN() { return getToken(VitaminParser.LPAREN, 0); }
		public TerminalNode RPAREN() { return getToken(VitaminParser.RPAREN, 0); }
		public List<ExprContext> expr() {
			return getRuleContexts(ExprContext.class);
		}
		public ExprContext expr(int i) {
			return getRuleContext(ExprContext.class,i);
		}
		public List<TerminalNode> COMMA() { return getTokens(VitaminParser.COMMA); }
		public TerminalNode COMMA(int i) {
			return getToken(VitaminParser.COMMA, i);
		}
		public ListContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_list; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterList(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitList(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitList(this);
			else return visitor.visitChildren(this);
		}
	}

	public final ListContext list() throws RecognitionException {
		ListContext _localctx = new ListContext(_ctx, getState());
		enterRule(_localctx, 10, RULE_list);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(61);
			match(LPAREN);
			setState(73);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << Num1) | (1L << Num2) | (1L << Str1) | (1L << Str2) | (1L << Symb) | (1L << Atom) | (1L << QUASI) | (1L << LBRACE) | (1L << LPAREN))) != 0)) {
				{
				setState(62);
				expr();
				setState(67);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,9,_ctx);
				while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
					if ( _alt==1 ) {
						{
						{
						setState(63);
						match(COMMA);
						setState(64);
						expr();
						}
						} 
					}
					setState(69);
					_errHandler.sync(this);
					_alt = getInterpreter().adaptivePredict(_input,9,_ctx);
				}
				setState(71);
				_errHandler.sync(this);
				_la = _input.LA(1);
				if (_la==COMMA) {
					{
					setState(70);
					match(COMMA);
					}
				}

				}
			}

			setState(75);
			match(RPAREN);
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class FuncContext extends ParserRuleContext {
		public TerminalNode LBRACE() { return getToken(VitaminParser.LBRACE, 0); }
		public BodyContext body() {
			return getRuleContext(BodyContext.class,0);
		}
		public TerminalNode RBRACE() { return getToken(VitaminParser.RBRACE, 0); }
		public ExprContext expr() {
			return getRuleContext(ExprContext.class,0);
		}
		public TerminalNode IN() { return getToken(VitaminParser.IN, 0); }
		public FuncContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_func; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterFunc(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitFunc(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitFunc(this);
			else return visitor.visitChildren(this);
		}
	}

	public final FuncContext func() throws RecognitionException {
		FuncContext _localctx = new FuncContext(_ctx, getState());
		enterRule(_localctx, 12, RULE_func);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(77);
			match(LBRACE);
			setState(81);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,12,_ctx) ) {
			case 1:
				{
				setState(78);
				expr();
				setState(79);
				match(IN);
				}
				break;
			}
			setState(83);
			body();
			setState(84);
			match(RBRACE);
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class AtomContext extends ParserRuleContext {
		public TerminalNode Atom() { return getToken(VitaminParser.Atom, 0); }
		public List<TerminalNode> QUASI() { return getTokens(VitaminParser.QUASI); }
		public TerminalNode QUASI(int i) {
			return getToken(VitaminParser.QUASI, i);
		}
		public TerminalNode Symb() { return getToken(VitaminParser.Symb, 0); }
		public AtomContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_atom; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterAtom(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitAtom(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitAtom(this);
			else return visitor.visitChildren(this);
		}
	}

	public final AtomContext atom() throws RecognitionException {
		AtomContext _localctx = new AtomContext(_ctx, getState());
		enterRule(_localctx, 14, RULE_atom);
		int _la;
		try {
			setState(90);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case Atom:
				enterOuterAlt(_localctx, 1);
				{
				setState(86);
				match(Atom);
				}
				break;
			case QUASI:
				enterOuterAlt(_localctx, 2);
				{
				setState(87);
				match(QUASI);
				setState(88);
				_la = _input.LA(1);
				if ( !(_la==Symb || _la==Atom) ) {
				_errHandler.recoverInline(this);
				}
				else {
					if ( _input.LA(1)==Token.EOF ) matchedEOF = true;
					_errHandler.reportMatch(this);
					consume();
				}
				setState(89);
				match(QUASI);
				}
				break;
			default:
				throw new NoViableAltException(this);
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static class LiteContext extends ParserRuleContext {
		public TerminalNode Symb() { return getToken(VitaminParser.Symb, 0); }
		public TerminalNode Num1() { return getToken(VitaminParser.Num1, 0); }
		public TerminalNode Num2() { return getToken(VitaminParser.Num2, 0); }
		public TerminalNode Str1() { return getToken(VitaminParser.Str1, 0); }
		public TerminalNode Str2() { return getToken(VitaminParser.Str2, 0); }
		public LiteContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_lite; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).enterLite(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminParserListener ) ((VitaminParserListener)listener).exitLite(this);
		}
		@Override
		public <T> T accept(ParseTreeVisitor<? extends T> visitor) {
			if ( visitor instanceof VitaminParserVisitor ) return ((VitaminParserVisitor<? extends T>)visitor).visitLite(this);
			else return visitor.visitChildren(this);
		}
	}

	public final LiteContext lite() throws RecognitionException {
		LiteContext _localctx = new LiteContext(_ctx, getState());
		enterRule(_localctx, 16, RULE_lite);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(92);
			_la = _input.LA(1);
			if ( !((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << Num1) | (1L << Num2) | (1L << Str1) | (1L << Str2) | (1L << Symb))) != 0)) ) {
			_errHandler.recoverInline(this);
			}
			else {
				if ( _input.LA(1)==Token.EOF ) matchedEOF = true;
				_errHandler.reportMatch(this);
				consume();
			}
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			exitRule();
		}
		return _localctx;
	}

	public static final String _serializedATN =
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\3\27a\4\2\t\2\4\3\t"+
		"\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\3\2\3\2\3\2"+
		"\3\3\5\3\31\n\3\3\3\3\3\7\3\35\n\3\f\3\16\3 \13\3\3\3\7\3#\n\3\f\3\16"+
		"\3&\13\3\3\4\6\4)\n\4\r\4\16\4*\3\5\3\5\6\5/\n\5\r\5\16\5\60\3\5\5\5\64"+
		"\n\5\5\5\66\n\5\3\5\5\59\n\5\3\6\3\6\3\6\5\6>\n\6\3\7\3\7\3\7\3\7\7\7"+
		"D\n\7\f\7\16\7G\13\7\3\7\5\7J\n\7\5\7L\n\7\3\7\3\7\3\b\3\b\3\b\3\b\5\b"+
		"T\n\b\3\b\3\b\3\b\3\t\3\t\3\t\3\t\5\t]\n\t\3\n\3\n\3\n\2\2\13\2\4\6\b"+
		"\n\f\16\20\22\2\4\3\2\f\r\4\2\6\t\f\f\2f\2\24\3\2\2\2\4\30\3\2\2\2\6("+
		"\3\2\2\2\b8\3\2\2\2\n=\3\2\2\2\f?\3\2\2\2\16O\3\2\2\2\20\\\3\2\2\2\22"+
		"^\3\2\2\2\24\25\5\4\3\2\25\26\7\2\2\3\26\3\3\2\2\2\27\31\5\6\4\2\30\27"+
		"\3\2\2\2\30\31\3\2\2\2\31\36\3\2\2\2\32\33\7\17\2\2\33\35\5\6\4\2\34\32"+
		"\3\2\2\2\35 \3\2\2\2\36\34\3\2\2\2\36\37\3\2\2\2\37$\3\2\2\2 \36\3\2\2"+
		"\2!#\7\17\2\2\"!\3\2\2\2#&\3\2\2\2$\"\3\2\2\2$%\3\2\2\2%\5\3\2\2\2&$\3"+
		"\2\2\2\')\5\b\5\2(\'\3\2\2\2)*\3\2\2\2*(\3\2\2\2*+\3\2\2\2+\7\3\2\2\2"+
		",\65\5\n\6\2-/\5\f\7\2.-\3\2\2\2/\60\3\2\2\2\60.\3\2\2\2\60\61\3\2\2\2"+
		"\61\63\3\2\2\2\62\64\5\16\b\2\63\62\3\2\2\2\63\64\3\2\2\2\64\66\3\2\2"+
		"\2\65.\3\2\2\2\65\66\3\2\2\2\669\3\2\2\2\679\5\22\n\28,\3\2\2\28\67\3"+
		"\2\2\29\t\3\2\2\2:>\5\20\t\2;>\5\16\b\2<>\5\f\7\2=:\3\2\2\2=;\3\2\2\2"+
		"=<\3\2\2\2>\13\3\2\2\2?K\7\26\2\2@E\5\6\4\2AB\7\20\2\2BD\5\6\4\2CA\3\2"+
		"\2\2DG\3\2\2\2EC\3\2\2\2EF\3\2\2\2FI\3\2\2\2GE\3\2\2\2HJ\7\20\2\2IH\3"+
		"\2\2\2IJ\3\2\2\2JL\3\2\2\2K@\3\2\2\2KL\3\2\2\2LM\3\2\2\2MN\7\27\2\2N\r"+
		"\3\2\2\2OS\7\22\2\2PQ\5\6\4\2QR\7\16\2\2RT\3\2\2\2SP\3\2\2\2ST\3\2\2\2"+
		"TU\3\2\2\2UV\5\4\3\2VW\7\23\2\2W\17\3\2\2\2X]\7\r\2\2YZ\7\21\2\2Z[\t\2"+
		"\2\2[]\7\21\2\2\\X\3\2\2\2\\Y\3\2\2\2]\21\3\2\2\2^_\t\3\2\2_\23\3\2\2"+
		"\2\20\30\36$*\60\63\658=EIKS\\";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}