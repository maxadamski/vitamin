// Generated from /home/max/Documents/vitamin/res/VitaminC.g4 by ANTLR 4.7
package com.maxadamski.vparser;
import org.antlr.v4.runtime.atn.*;
import org.antlr.v4.runtime.dfa.DFA;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.misc.*;
import org.antlr.v4.runtime.tree.*;
import java.util.List;
import java.util.Iterator;
import java.util.ArrayList;

@SuppressWarnings({"all", "warnings", "unchecked", "unused", "cast"})
public class VitaminCParser extends Parser {
	static { RuntimeMetaData.checkVersion("4.7", RuntimeMetaData.VERSION); }

	protected static final DFA[] _decisionToDFA;
	protected static final PredictionContextCache _sharedContextCache =
		new PredictionContextCache();
	public static final int
		T__0=1, T__1=2, T__2=3, T__3=4, T__4=5, T__5=6, T__6=7, T__7=8, T__8=9, 
		T__9=10, T__10=11, T__11=12, ShebangLine=13, WS=14, NL=15, Real=16, Int=17, 
		String=18, Comment=19, Name=20, MINUS=21, LANGLE=22, RANGLE=23, QUOTE=24, 
		EQUAL=25, COLON=26, SEMI=27, PIPE=28, Symbol=29;
	public static final int
		RULE_program = 0, RULE_chunk = 1, RULE_expr = 2, RULE_primary = 3, RULE_ifexpr = 4, 
		RULE_whexpr = 5, RULE_typ = 6, RULE_par = 7, RULE_fun = 8, RULE_call = 9, 
		RULE_callArg = 10, RULE_pragma = 11, RULE_constant = 12, RULE_intn = 13, 
		RULE_real = 14, RULE_string = 15, RULE_atom = 16;
	public static final String[] ruleNames = {
		"program", "chunk", "expr", "primary", "ifexpr", "whexpr", "typ", "par", 
		"fun", "call", "callArg", "pragma", "constant", "intn", "real", "string", 
		"atom"
	};

	private static final String[] _LITERAL_NAMES = {
		null, "'('", "')'", "'if'", "'else'", "'while'", "'{'", "','", "'->'", 
		"'in'", "'}'", "'#'", "'`'", null, null, null, null, null, null, null, 
		null, "'-'", "'<'", "'>'", "'''", "'='", "':'", "';'", "'|'"
	};
	private static final String[] _SYMBOLIC_NAMES = {
		null, null, null, null, null, null, null, null, null, null, null, null, 
		null, "ShebangLine", "WS", "NL", "Real", "Int", "String", "Comment", "Name", 
		"MINUS", "LANGLE", "RANGLE", "QUOTE", "EQUAL", "COLON", "SEMI", "PIPE", 
		"Symbol"
	};
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
	public String getGrammarFileName() { return "VitaminC.g4"; }

	@Override
	public String[] getRuleNames() { return ruleNames; }

	@Override
	public String getSerializedATN() { return _serializedATN; }

	@Override
	public ATN getATN() { return _ATN; }

	public VitaminCParser(TokenStream input) {
		super(input);
		_interp = new ParserATNSimulator(this,_ATN,_decisionToDFA,_sharedContextCache);
	}
	public static class ProgramContext extends ParserRuleContext {
		public ChunkContext chunk() {
			return getRuleContext(ChunkContext.class,0);
		}
		public TerminalNode EOF() { return getToken(VitaminCParser.EOF, 0); }
		public ProgramContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_program; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterProgram(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitProgram(this);
		}
	}

	public final ProgramContext program() throws RecognitionException {
		ProgramContext _localctx = new ProgramContext(_ctx, getState());
		enterRule(_localctx, 0, RULE_program);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(34);
			chunk();
			setState(35);
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

	public static class ChunkContext extends ParserRuleContext {
		public List<TerminalNode> NL() { return getTokens(VitaminCParser.NL); }
		public TerminalNode NL(int i) {
			return getToken(VitaminCParser.NL, i);
		}
		public List<ExprContext> expr() {
			return getRuleContexts(ExprContext.class);
		}
		public ExprContext expr(int i) {
			return getRuleContext(ExprContext.class,i);
		}
		public List<TerminalNode> SEMI() { return getTokens(VitaminCParser.SEMI); }
		public TerminalNode SEMI(int i) {
			return getToken(VitaminCParser.SEMI, i);
		}
		public ChunkContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_chunk; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterChunk(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitChunk(this);
		}
	}

	public final ChunkContext chunk() throws RecognitionException {
		ChunkContext _localctx = new ChunkContext(_ctx, getState());
		enterRule(_localctx, 2, RULE_chunk);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(40);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,0,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(37);
					match(NL);
					}
					} 
				}
				setState(42);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,0,_ctx);
			}
			setState(53);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << T__0) | (1L << T__2) | (1L << T__4) | (1L << T__5) | (1L << T__10) | (1L << T__11) | (1L << Real) | (1L << Int) | (1L << String) | (1L << Name) | (1L << MINUS) | (1L << LANGLE) | (1L << RANGLE) | (1L << QUOTE) | (1L << EQUAL) | (1L << COLON) | (1L << Symbol))) != 0)) {
				{
				{
				setState(43);
				expr();
				setState(44);
				_la = _input.LA(1);
				if ( !(_la==NL || _la==SEMI) ) {
				_errHandler.recoverInline(this);
				}
				else {
					if ( _input.LA(1)==Token.EOF ) matchedEOF = true;
					_errHandler.reportMatch(this);
					consume();
				}
				setState(48);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,1,_ctx);
				while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
					if ( _alt==1 ) {
						{
						{
						setState(45);
						match(NL);
						}
						} 
					}
					setState(50);
					_errHandler.sync(this);
					_alt = getInterpreter().adaptivePredict(_input,1,_ctx);
				}
				}
				}
				setState(55);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(59);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(56);
				match(NL);
				}
				}
				setState(61);
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
		public List<PrimaryContext> primary() {
			return getRuleContexts(PrimaryContext.class);
		}
		public PrimaryContext primary(int i) {
			return getRuleContext(PrimaryContext.class,i);
		}
		public ExprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_expr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterExpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitExpr(this);
		}
	}

	public final ExprContext expr() throws RecognitionException {
		ExprContext _localctx = new ExprContext(_ctx, getState());
		enterRule(_localctx, 4, RULE_expr);
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(63); 
			_errHandler.sync(this);
			_alt = 1;
			do {
				switch (_alt) {
				case 1:
					{
					{
					setState(62);
					primary();
					}
					}
					break;
				default:
					throw new NoViableAltException(this);
				}
				setState(65); 
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,4,_ctx);
			} while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER );
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

	public static class PrimaryContext extends ParserRuleContext {
		public CallContext call() {
			return getRuleContext(CallContext.class,0);
		}
		public PragmaContext pragma() {
			return getRuleContext(PragmaContext.class,0);
		}
		public ConstantContext constant() {
			return getRuleContext(ConstantContext.class,0);
		}
		public IfexprContext ifexpr() {
			return getRuleContext(IfexprContext.class,0);
		}
		public WhexprContext whexpr() {
			return getRuleContext(WhexprContext.class,0);
		}
		public FunContext fun() {
			return getRuleContext(FunContext.class,0);
		}
		public ExprContext expr() {
			return getRuleContext(ExprContext.class,0);
		}
		public List<TerminalNode> NL() { return getTokens(VitaminCParser.NL); }
		public TerminalNode NL(int i) {
			return getToken(VitaminCParser.NL, i);
		}
		public PrimaryContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_primary; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterPrimary(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitPrimary(this);
		}
	}

	public final PrimaryContext primary() throws RecognitionException {
		PrimaryContext _localctx = new PrimaryContext(_ctx, getState());
		enterRule(_localctx, 6, RULE_primary);
		int _la;
		try {
			setState(89);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,7,_ctx) ) {
			case 1:
				enterOuterAlt(_localctx, 1);
				{
				setState(67);
				call();
				}
				break;
			case 2:
				enterOuterAlt(_localctx, 2);
				{
				setState(68);
				pragma();
				}
				break;
			case 3:
				enterOuterAlt(_localctx, 3);
				{
				setState(69);
				constant();
				}
				break;
			case 4:
				enterOuterAlt(_localctx, 4);
				{
				setState(70);
				ifexpr();
				}
				break;
			case 5:
				enterOuterAlt(_localctx, 5);
				{
				setState(71);
				whexpr();
				}
				break;
			case 6:
				enterOuterAlt(_localctx, 6);
				{
				setState(72);
				fun();
				}
				break;
			case 7:
				enterOuterAlt(_localctx, 7);
				{
				setState(73);
				match(T__0);
				setState(77);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(74);
					match(NL);
					}
					}
					setState(79);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(80);
				expr();
				setState(84);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(81);
					match(NL);
					}
					}
					setState(86);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(87);
				match(T__1);
				}
				break;
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

	public static class IfexprContext extends ParserRuleContext {
		public List<ExprContext> expr() {
			return getRuleContexts(ExprContext.class);
		}
		public ExprContext expr(int i) {
			return getRuleContext(ExprContext.class,i);
		}
		public List<TerminalNode> NL() { return getTokens(VitaminCParser.NL); }
		public TerminalNode NL(int i) {
			return getToken(VitaminCParser.NL, i);
		}
		public IfexprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_ifexpr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterIfexpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitIfexpr(this);
		}
	}

	public final IfexprContext ifexpr() throws RecognitionException {
		IfexprContext _localctx = new IfexprContext(_ctx, getState());
		enterRule(_localctx, 8, RULE_ifexpr);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(91);
			match(T__2);
			setState(92);
			match(T__0);
			setState(96);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(93);
				match(NL);
				}
				}
				setState(98);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(99);
			expr();
			setState(103);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(100);
				match(NL);
				}
				}
				setState(105);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(106);
			match(T__1);
			setState(110);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(107);
				match(NL);
				}
				}
				setState(112);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(113);
			expr();
			setState(117);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,11,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(114);
					match(NL);
					}
					} 
				}
				setState(119);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,11,_ctx);
			}
			setState(128);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,13,_ctx) ) {
			case 1:
				{
				setState(120);
				match(T__3);
				setState(124);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(121);
					match(NL);
					}
					}
					setState(126);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(127);
				expr();
				}
				break;
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

	public static class WhexprContext extends ParserRuleContext {
		public List<ExprContext> expr() {
			return getRuleContexts(ExprContext.class);
		}
		public ExprContext expr(int i) {
			return getRuleContext(ExprContext.class,i);
		}
		public List<TerminalNode> NL() { return getTokens(VitaminCParser.NL); }
		public TerminalNode NL(int i) {
			return getToken(VitaminCParser.NL, i);
		}
		public WhexprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_whexpr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterWhexpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitWhexpr(this);
		}
	}

	public final WhexprContext whexpr() throws RecognitionException {
		WhexprContext _localctx = new WhexprContext(_ctx, getState());
		enterRule(_localctx, 10, RULE_whexpr);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(130);
			match(T__4);
			setState(131);
			match(T__0);
			setState(135);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(132);
				match(NL);
				}
				}
				setState(137);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(138);
			expr();
			setState(142);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(139);
				match(NL);
				}
				}
				setState(144);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(145);
			match(T__1);
			setState(149);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(146);
				match(NL);
				}
				}
				setState(151);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(152);
			expr();
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

	public static class TypContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public TypContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_typ; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterTyp(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitTyp(this);
		}
	}

	public final TypContext typ() throws RecognitionException {
		TypContext _localctx = new TypContext(_ctx, getState());
		enterRule(_localctx, 12, RULE_typ);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(154);
			atom();
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

	public static class ParContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public TerminalNode COLON() { return getToken(VitaminCParser.COLON, 0); }
		public TypContext typ() {
			return getRuleContext(TypContext.class,0);
		}
		public ParContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_par; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterPar(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitPar(this);
		}
	}

	public final ParContext par() throws RecognitionException {
		ParContext _localctx = new ParContext(_ctx, getState());
		enterRule(_localctx, 14, RULE_par);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(156);
			atom();
			setState(157);
			match(COLON);
			setState(158);
			typ();
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

	public static class FunContext extends ParserRuleContext {
		public ChunkContext chunk() {
			return getRuleContext(ChunkContext.class,0);
		}
		public List<ParContext> par() {
			return getRuleContexts(ParContext.class);
		}
		public ParContext par(int i) {
			return getRuleContext(ParContext.class,i);
		}
		public TypContext typ() {
			return getRuleContext(TypContext.class,0);
		}
		public FunContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_fun; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterFun(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitFun(this);
		}
	}

	public final FunContext fun() throws RecognitionException {
		FunContext _localctx = new FunContext(_ctx, getState());
		enterRule(_localctx, 16, RULE_fun);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(160);
			match(T__5);
			setState(177);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,19,_ctx) ) {
			case 1:
				{
				setState(161);
				match(T__0);
				setState(162);
				par();
				setState(167);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==T__6) {
					{
					{
					setState(163);
					match(T__6);
					setState(164);
					par();
					}
					}
					setState(169);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(170);
				match(T__1);
				setState(173);
				_errHandler.sync(this);
				_la = _input.LA(1);
				if (_la==T__7) {
					{
					setState(171);
					match(T__7);
					setState(172);
					typ();
					}
				}

				setState(175);
				match(T__8);
				}
				break;
			}
			setState(179);
			chunk();
			setState(180);
			match(T__9);
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
		public FunContext fun() {
			return getRuleContext(FunContext.class,0);
		}
		public List<CallArgContext> callArg() {
			return getRuleContexts(CallArgContext.class);
		}
		public CallArgContext callArg(int i) {
			return getRuleContext(CallArgContext.class,i);
		}
		public CallContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_call; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterCall(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitCall(this);
		}
	}

	public final CallContext call() throws RecognitionException {
		CallContext _localctx = new CallContext(_ctx, getState());
		enterRule(_localctx, 18, RULE_call);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(184);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__11:
			case Name:
			case MINUS:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case COLON:
			case Symbol:
				{
				setState(182);
				atom();
				}
				break;
			case T__5:
				{
				setState(183);
				fun();
				}
				break;
			default:
				throw new NoViableAltException(this);
			}
			setState(186);
			match(T__0);
			setState(195);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << T__0) | (1L << T__2) | (1L << T__4) | (1L << T__5) | (1L << T__10) | (1L << T__11) | (1L << Real) | (1L << Int) | (1L << String) | (1L << Name) | (1L << MINUS) | (1L << LANGLE) | (1L << RANGLE) | (1L << QUOTE) | (1L << EQUAL) | (1L << COLON) | (1L << Symbol))) != 0)) {
				{
				setState(187);
				callArg();
				setState(192);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==T__6) {
					{
					{
					setState(188);
					match(T__6);
					setState(189);
					callArg();
					}
					}
					setState(194);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				}
			}

			setState(197);
			match(T__1);
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

	public static class CallArgContext extends ParserRuleContext {
		public ExprContext expr() {
			return getRuleContext(ExprContext.class,0);
		}
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public TerminalNode COLON() { return getToken(VitaminCParser.COLON, 0); }
		public CallArgContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_callArg; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterCallArg(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitCallArg(this);
		}
	}

	public final CallArgContext callArg() throws RecognitionException {
		CallArgContext _localctx = new CallArgContext(_ctx, getState());
		enterRule(_localctx, 20, RULE_callArg);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(202);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,23,_ctx) ) {
			case 1:
				{
				setState(199);
				atom();
				setState(200);
				match(COLON);
				}
				break;
			}
			setState(204);
			expr();
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

	public static class PragmaContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public CallContext call() {
			return getRuleContext(CallContext.class,0);
		}
		public PragmaContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_pragma; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterPragma(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitPragma(this);
		}
	}

	public final PragmaContext pragma() throws RecognitionException {
		PragmaContext _localctx = new PragmaContext(_ctx, getState());
		enterRule(_localctx, 22, RULE_pragma);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(206);
			match(T__10);
			setState(209);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,24,_ctx) ) {
			case 1:
				{
				setState(207);
				atom();
				}
				break;
			case 2:
				{
				setState(208);
				call();
				}
				break;
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

	public static class ConstantContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public IntnContext intn() {
			return getRuleContext(IntnContext.class,0);
		}
		public RealContext real() {
			return getRuleContext(RealContext.class,0);
		}
		public StringContext string() {
			return getRuleContext(StringContext.class,0);
		}
		public ConstantContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_constant; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterConstant(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitConstant(this);
		}
	}

	public final ConstantContext constant() throws RecognitionException {
		ConstantContext _localctx = new ConstantContext(_ctx, getState());
		enterRule(_localctx, 24, RULE_constant);
		try {
			setState(215);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__11:
			case Name:
			case MINUS:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case COLON:
			case Symbol:
				enterOuterAlt(_localctx, 1);
				{
				setState(211);
				atom();
				}
				break;
			case Int:
				enterOuterAlt(_localctx, 2);
				{
				setState(212);
				intn();
				}
				break;
			case Real:
				enterOuterAlt(_localctx, 3);
				{
				setState(213);
				real();
				}
				break;
			case String:
				enterOuterAlt(_localctx, 4);
				{
				setState(214);
				string();
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

	public static class IntnContext extends ParserRuleContext {
		public TerminalNode Int() { return getToken(VitaminCParser.Int, 0); }
		public IntnContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_intn; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterIntn(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitIntn(this);
		}
	}

	public final IntnContext intn() throws RecognitionException {
		IntnContext _localctx = new IntnContext(_ctx, getState());
		enterRule(_localctx, 26, RULE_intn);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(217);
			match(Int);
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

	public static class RealContext extends ParserRuleContext {
		public TerminalNode Real() { return getToken(VitaminCParser.Real, 0); }
		public RealContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_real; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterReal(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitReal(this);
		}
	}

	public final RealContext real() throws RecognitionException {
		RealContext _localctx = new RealContext(_ctx, getState());
		enterRule(_localctx, 28, RULE_real);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(219);
			match(Real);
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

	public static class StringContext extends ParserRuleContext {
		public TerminalNode String() { return getToken(VitaminCParser.String, 0); }
		public StringContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_string; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterString(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitString(this);
		}
	}

	public final StringContext string() throws RecognitionException {
		StringContext _localctx = new StringContext(_ctx, getState());
		enterRule(_localctx, 30, RULE_string);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(221);
			match(String);
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
		public TerminalNode Name() { return getToken(VitaminCParser.Name, 0); }
		public TerminalNode Symbol() { return getToken(VitaminCParser.Symbol, 0); }
		public ConstantContext constant() {
			return getRuleContext(ConstantContext.class,0);
		}
		public TerminalNode COLON() { return getToken(VitaminCParser.COLON, 0); }
		public TerminalNode LANGLE() { return getToken(VitaminCParser.LANGLE, 0); }
		public TerminalNode RANGLE() { return getToken(VitaminCParser.RANGLE, 0); }
		public TerminalNode EQUAL() { return getToken(VitaminCParser.EQUAL, 0); }
		public TerminalNode MINUS() { return getToken(VitaminCParser.MINUS, 0); }
		public TerminalNode QUOTE() { return getToken(VitaminCParser.QUOTE, 0); }
		public AtomContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_atom; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterAtom(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitAtom(this);
		}
	}

	public final AtomContext atom() throws RecognitionException {
		AtomContext _localctx = new AtomContext(_ctx, getState());
		enterRule(_localctx, 32, RULE_atom);
		try {
			setState(235);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case Name:
				enterOuterAlt(_localctx, 1);
				{
				setState(223);
				match(Name);
				}
				break;
			case Symbol:
				enterOuterAlt(_localctx, 2);
				{
				setState(224);
				match(Symbol);
				}
				break;
			case T__11:
				enterOuterAlt(_localctx, 3);
				{
				setState(225);
				match(T__11);
				setState(226);
				constant();
				setState(227);
				match(T__11);
				}
				break;
			case COLON:
				enterOuterAlt(_localctx, 4);
				{
				setState(229);
				match(COLON);
				}
				break;
			case LANGLE:
				enterOuterAlt(_localctx, 5);
				{
				setState(230);
				match(LANGLE);
				}
				break;
			case RANGLE:
				enterOuterAlt(_localctx, 6);
				{
				setState(231);
				match(RANGLE);
				}
				break;
			case EQUAL:
				enterOuterAlt(_localctx, 7);
				{
				setState(232);
				match(EQUAL);
				}
				break;
			case MINUS:
				enterOuterAlt(_localctx, 8);
				{
				setState(233);
				match(MINUS);
				}
				break;
			case QUOTE:
				enterOuterAlt(_localctx, 9);
				{
				setState(234);
				match(QUOTE);
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

	public static final String _serializedATN =
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\3\37\u00f0\4\2\t\2"+
		"\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4\13"+
		"\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22\t\22"+
		"\3\2\3\2\3\2\3\3\7\3)\n\3\f\3\16\3,\13\3\3\3\3\3\3\3\7\3\61\n\3\f\3\16"+
		"\3\64\13\3\7\3\66\n\3\f\3\16\39\13\3\3\3\7\3<\n\3\f\3\16\3?\13\3\3\4\6"+
		"\4B\n\4\r\4\16\4C\3\5\3\5\3\5\3\5\3\5\3\5\3\5\3\5\7\5N\n\5\f\5\16\5Q\13"+
		"\5\3\5\3\5\7\5U\n\5\f\5\16\5X\13\5\3\5\3\5\5\5\\\n\5\3\6\3\6\3\6\7\6a"+
		"\n\6\f\6\16\6d\13\6\3\6\3\6\7\6h\n\6\f\6\16\6k\13\6\3\6\3\6\7\6o\n\6\f"+
		"\6\16\6r\13\6\3\6\3\6\7\6v\n\6\f\6\16\6y\13\6\3\6\3\6\7\6}\n\6\f\6\16"+
		"\6\u0080\13\6\3\6\5\6\u0083\n\6\3\7\3\7\3\7\7\7\u0088\n\7\f\7\16\7\u008b"+
		"\13\7\3\7\3\7\7\7\u008f\n\7\f\7\16\7\u0092\13\7\3\7\3\7\7\7\u0096\n\7"+
		"\f\7\16\7\u0099\13\7\3\7\3\7\3\b\3\b\3\t\3\t\3\t\3\t\3\n\3\n\3\n\3\n\3"+
		"\n\7\n\u00a8\n\n\f\n\16\n\u00ab\13\n\3\n\3\n\3\n\5\n\u00b0\n\n\3\n\3\n"+
		"\5\n\u00b4\n\n\3\n\3\n\3\n\3\13\3\13\5\13\u00bb\n\13\3\13\3\13\3\13\3"+
		"\13\7\13\u00c1\n\13\f\13\16\13\u00c4\13\13\5\13\u00c6\n\13\3\13\3\13\3"+
		"\f\3\f\3\f\5\f\u00cd\n\f\3\f\3\f\3\r\3\r\3\r\5\r\u00d4\n\r\3\16\3\16\3"+
		"\16\3\16\5\16\u00da\n\16\3\17\3\17\3\20\3\20\3\21\3\21\3\22\3\22\3\22"+
		"\3\22\3\22\3\22\3\22\3\22\3\22\3\22\3\22\3\22\5\22\u00ee\n\22\3\22\2\2"+
		"\23\2\4\6\b\n\f\16\20\22\24\26\30\32\34\36 \"\2\3\4\2\21\21\35\35\2\u0107"+
		"\2$\3\2\2\2\4*\3\2\2\2\6A\3\2\2\2\b[\3\2\2\2\n]\3\2\2\2\f\u0084\3\2\2"+
		"\2\16\u009c\3\2\2\2\20\u009e\3\2\2\2\22\u00a2\3\2\2\2\24\u00ba\3\2\2\2"+
		"\26\u00cc\3\2\2\2\30\u00d0\3\2\2\2\32\u00d9\3\2\2\2\34\u00db\3\2\2\2\36"+
		"\u00dd\3\2\2\2 \u00df\3\2\2\2\"\u00ed\3\2\2\2$%\5\4\3\2%&\7\2\2\3&\3\3"+
		"\2\2\2\')\7\21\2\2(\'\3\2\2\2),\3\2\2\2*(\3\2\2\2*+\3\2\2\2+\67\3\2\2"+
		"\2,*\3\2\2\2-.\5\6\4\2.\62\t\2\2\2/\61\7\21\2\2\60/\3\2\2\2\61\64\3\2"+
		"\2\2\62\60\3\2\2\2\62\63\3\2\2\2\63\66\3\2\2\2\64\62\3\2\2\2\65-\3\2\2"+
		"\2\669\3\2\2\2\67\65\3\2\2\2\678\3\2\2\28=\3\2\2\29\67\3\2\2\2:<\7\21"+
		"\2\2;:\3\2\2\2<?\3\2\2\2=;\3\2\2\2=>\3\2\2\2>\5\3\2\2\2?=\3\2\2\2@B\5"+
		"\b\5\2A@\3\2\2\2BC\3\2\2\2CA\3\2\2\2CD\3\2\2\2D\7\3\2\2\2E\\\5\24\13\2"+
		"F\\\5\30\r\2G\\\5\32\16\2H\\\5\n\6\2I\\\5\f\7\2J\\\5\22\n\2KO\7\3\2\2"+
		"LN\7\21\2\2ML\3\2\2\2NQ\3\2\2\2OM\3\2\2\2OP\3\2\2\2PR\3\2\2\2QO\3\2\2"+
		"\2RV\5\6\4\2SU\7\21\2\2TS\3\2\2\2UX\3\2\2\2VT\3\2\2\2VW\3\2\2\2WY\3\2"+
		"\2\2XV\3\2\2\2YZ\7\4\2\2Z\\\3\2\2\2[E\3\2\2\2[F\3\2\2\2[G\3\2\2\2[H\3"+
		"\2\2\2[I\3\2\2\2[J\3\2\2\2[K\3\2\2\2\\\t\3\2\2\2]^\7\5\2\2^b\7\3\2\2_"+
		"a\7\21\2\2`_\3\2\2\2ad\3\2\2\2b`\3\2\2\2bc\3\2\2\2ce\3\2\2\2db\3\2\2\2"+
		"ei\5\6\4\2fh\7\21\2\2gf\3\2\2\2hk\3\2\2\2ig\3\2\2\2ij\3\2\2\2jl\3\2\2"+
		"\2ki\3\2\2\2lp\7\4\2\2mo\7\21\2\2nm\3\2\2\2or\3\2\2\2pn\3\2\2\2pq\3\2"+
		"\2\2qs\3\2\2\2rp\3\2\2\2sw\5\6\4\2tv\7\21\2\2ut\3\2\2\2vy\3\2\2\2wu\3"+
		"\2\2\2wx\3\2\2\2x\u0082\3\2\2\2yw\3\2\2\2z~\7\6\2\2{}\7\21\2\2|{\3\2\2"+
		"\2}\u0080\3\2\2\2~|\3\2\2\2~\177\3\2\2\2\177\u0081\3\2\2\2\u0080~\3\2"+
		"\2\2\u0081\u0083\5\6\4\2\u0082z\3\2\2\2\u0082\u0083\3\2\2\2\u0083\13\3"+
		"\2\2\2\u0084\u0085\7\7\2\2\u0085\u0089\7\3\2\2\u0086\u0088\7\21\2\2\u0087"+
		"\u0086\3\2\2\2\u0088\u008b\3\2\2\2\u0089\u0087\3\2\2\2\u0089\u008a\3\2"+
		"\2\2\u008a\u008c\3\2\2\2\u008b\u0089\3\2\2\2\u008c\u0090\5\6\4\2\u008d"+
		"\u008f\7\21\2\2\u008e\u008d\3\2\2\2\u008f\u0092\3\2\2\2\u0090\u008e\3"+
		"\2\2\2\u0090\u0091\3\2\2\2\u0091\u0093\3\2\2\2\u0092\u0090\3\2\2\2\u0093"+
		"\u0097\7\4\2\2\u0094\u0096\7\21\2\2\u0095\u0094\3\2\2\2\u0096\u0099\3"+
		"\2\2\2\u0097\u0095\3\2\2\2\u0097\u0098\3\2\2\2\u0098\u009a\3\2\2\2\u0099"+
		"\u0097\3\2\2\2\u009a\u009b\5\6\4\2\u009b\r\3\2\2\2\u009c\u009d\5\"\22"+
		"\2\u009d\17\3\2\2\2\u009e\u009f\5\"\22\2\u009f\u00a0\7\34\2\2\u00a0\u00a1"+
		"\5\16\b\2\u00a1\21\3\2\2\2\u00a2\u00b3\7\b\2\2\u00a3\u00a4\7\3\2\2\u00a4"+
		"\u00a9\5\20\t\2\u00a5\u00a6\7\t\2\2\u00a6\u00a8\5\20\t\2\u00a7\u00a5\3"+
		"\2\2\2\u00a8\u00ab\3\2\2\2\u00a9\u00a7\3\2\2\2\u00a9\u00aa\3\2\2\2\u00aa"+
		"\u00ac\3\2\2\2\u00ab\u00a9\3\2\2\2\u00ac\u00af\7\4\2\2\u00ad\u00ae\7\n"+
		"\2\2\u00ae\u00b0\5\16\b\2\u00af\u00ad\3\2\2\2\u00af\u00b0\3\2\2\2\u00b0"+
		"\u00b1\3\2\2\2\u00b1\u00b2\7\13\2\2\u00b2\u00b4\3\2\2\2\u00b3\u00a3\3"+
		"\2\2\2\u00b3\u00b4\3\2\2\2\u00b4\u00b5\3\2\2\2\u00b5\u00b6\5\4\3\2\u00b6"+
		"\u00b7\7\f\2\2\u00b7\23\3\2\2\2\u00b8\u00bb\5\"\22\2\u00b9\u00bb\5\22"+
		"\n\2\u00ba\u00b8\3\2\2\2\u00ba\u00b9\3\2\2\2\u00bb\u00bc\3\2\2\2\u00bc"+
		"\u00c5\7\3\2\2\u00bd\u00c2\5\26\f\2\u00be\u00bf\7\t\2\2\u00bf\u00c1\5"+
		"\26\f\2\u00c0\u00be\3\2\2\2\u00c1\u00c4\3\2\2\2\u00c2\u00c0\3\2\2\2\u00c2"+
		"\u00c3\3\2\2\2\u00c3\u00c6\3\2\2\2\u00c4\u00c2\3\2\2\2\u00c5\u00bd\3\2"+
		"\2\2\u00c5\u00c6\3\2\2\2\u00c6\u00c7\3\2\2\2\u00c7\u00c8\7\4\2\2\u00c8"+
		"\25\3\2\2\2\u00c9\u00ca\5\"\22\2\u00ca\u00cb\7\34\2\2\u00cb\u00cd\3\2"+
		"\2\2\u00cc\u00c9\3\2\2\2\u00cc\u00cd\3\2\2\2\u00cd\u00ce\3\2\2\2\u00ce"+
		"\u00cf\5\6\4\2\u00cf\27\3\2\2\2\u00d0\u00d3\7\r\2\2\u00d1\u00d4\5\"\22"+
		"\2\u00d2\u00d4\5\24\13\2\u00d3\u00d1\3\2\2\2\u00d3\u00d2\3\2\2\2\u00d4"+
		"\31\3\2\2\2\u00d5\u00da\5\"\22\2\u00d6\u00da\5\34\17\2\u00d7\u00da\5\36"+
		"\20\2\u00d8\u00da\5 \21\2\u00d9\u00d5\3\2\2\2\u00d9\u00d6\3\2\2\2\u00d9"+
		"\u00d7\3\2\2\2\u00d9\u00d8\3\2\2\2\u00da\33\3\2\2\2\u00db\u00dc\7\23\2"+
		"\2\u00dc\35\3\2\2\2\u00dd\u00de\7\22\2\2\u00de\37\3\2\2\2\u00df\u00e0"+
		"\7\24\2\2\u00e0!\3\2\2\2\u00e1\u00ee\7\26\2\2\u00e2\u00ee\7\37\2\2\u00e3"+
		"\u00e4\7\16\2\2\u00e4\u00e5\5\32\16\2\u00e5\u00e6\7\16\2\2\u00e6\u00ee"+
		"\3\2\2\2\u00e7\u00ee\7\34\2\2\u00e8\u00ee\7\30\2\2\u00e9\u00ee\7\31\2"+
		"\2\u00ea\u00ee\7\33\2\2\u00eb\u00ee\7\27\2\2\u00ec\u00ee\7\32\2\2\u00ed"+
		"\u00e1\3\2\2\2\u00ed\u00e2\3\2\2\2\u00ed\u00e3\3\2\2\2\u00ed\u00e7\3\2"+
		"\2\2\u00ed\u00e8\3\2\2\2\u00ed\u00e9\3\2\2\2\u00ed\u00ea\3\2\2\2\u00ed"+
		"\u00eb\3\2\2\2\u00ed\u00ec\3\2\2\2\u00ee#\3\2\2\2\35*\62\67=COV[bipw~"+
		"\u0082\u0089\u0090\u0097\u00a9\u00af\u00b3\u00ba\u00c2\u00c5\u00cc\u00d3"+
		"\u00d9\u00ed";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}