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
		ShebangLine=10, WS=11, NL=12, Real=13, Int=14, String=15, Comment=16, 
		Name=17, LANGLE=18, RANGLE=19, QUOTE=20, EQUAL=21, COLON=22, SEMI=23, 
		PIPE=24, Symbol=25;
	public static final int
		RULE_program = 0, RULE_chunk = 1, RULE_expr = 2, RULE_primary = 3, RULE_ifexpr = 4, 
		RULE_fun = 5, RULE_call = 6, RULE_callArg = 7, RULE_pragma = 8, RULE_constant = 9, 
		RULE_atom = 10, RULE_intn = 11, RULE_real = 12, RULE_string = 13;
	public static final String[] ruleNames = {
		"program", "chunk", "expr", "primary", "ifexpr", "fun", "call", "callArg", 
		"pragma", "constant", "atom", "intn", "real", "string"
	};

	private static final String[] _LITERAL_NAMES = {
		null, "'('", "')'", "'if'", "'else'", "'{'", "','", "'}'", "'#'", "'`'", 
		null, null, null, null, null, null, null, null, "'<'", "'>'", "'''", "'='", 
		"':'", "';'", "'|'"
	};
	private static final String[] _SYMBOLIC_NAMES = {
		null, null, null, null, null, null, null, null, null, null, "ShebangLine", 
		"WS", "NL", "Real", "Int", "String", "Comment", "Name", "LANGLE", "RANGLE", 
		"QUOTE", "EQUAL", "COLON", "SEMI", "PIPE", "Symbol"
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
			setState(28);
			chunk();
			setState(29);
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
			setState(34);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,0,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(31);
					match(NL);
					}
					} 
				}
				setState(36);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,0,_ctx);
			}
			setState(38);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << T__0) | (1L << T__2) | (1L << T__4) | (1L << T__7) | (1L << T__8) | (1L << Real) | (1L << Int) | (1L << String) | (1L << Name) | (1L << LANGLE) | (1L << RANGLE) | (1L << QUOTE) | (1L << EQUAL) | (1L << COLON) | (1L << PIPE) | (1L << Symbol))) != 0)) {
				{
				setState(37);
				expr();
				}
			}

			setState(57);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,5,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(52);
					_errHandler.sync(this);
					switch (_input.LA(1)) {
					case SEMI:
						{
						setState(40);
						match(SEMI);
						setState(44);
						_errHandler.sync(this);
						_la = _input.LA(1);
						while (_la==NL) {
							{
							{
							setState(41);
							match(NL);
							}
							}
							setState(46);
							_errHandler.sync(this);
							_la = _input.LA(1);
						}
						}
						break;
					case NL:
						{
						setState(48); 
						_errHandler.sync(this);
						_la = _input.LA(1);
						do {
							{
							{
							setState(47);
							match(NL);
							}
							}
							setState(50); 
							_errHandler.sync(this);
							_la = _input.LA(1);
						} while ( _la==NL );
						}
						break;
					default:
						throw new NoViableAltException(this);
					}
					setState(54);
					expr();
					}
					} 
				}
				setState(59);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,5,_ctx);
			}
			setState(63);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(60);
				match(NL);
				}
				}
				setState(65);
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
			setState(67); 
			_errHandler.sync(this);
			_alt = 1;
			do {
				switch (_alt) {
				case 1:
					{
					{
					setState(66);
					primary();
					}
					}
					break;
				default:
					throw new NoViableAltException(this);
				}
				setState(69); 
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,7,_ctx);
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
		public ConstantContext constant() {
			return getRuleContext(ConstantContext.class,0);
		}
		public PragmaContext pragma() {
			return getRuleContext(PragmaContext.class,0);
		}
		public IfexprContext ifexpr() {
			return getRuleContext(IfexprContext.class,0);
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
			setState(92);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,10,_ctx) ) {
			case 1:
				enterOuterAlt(_localctx, 1);
				{
				setState(71);
				call();
				}
				break;
			case 2:
				enterOuterAlt(_localctx, 2);
				{
				setState(72);
				constant();
				}
				break;
			case 3:
				enterOuterAlt(_localctx, 3);
				{
				setState(73);
				pragma();
				}
				break;
			case 4:
				enterOuterAlt(_localctx, 4);
				{
				setState(74);
				ifexpr();
				}
				break;
			case 5:
				enterOuterAlt(_localctx, 5);
				{
				setState(75);
				fun();
				}
				break;
			case 6:
				enterOuterAlt(_localctx, 6);
				{
				setState(76);
				match(T__0);
				setState(80);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(77);
					match(NL);
					}
					}
					setState(82);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(83);
				expr();
				setState(87);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(84);
					match(NL);
					}
					}
					setState(89);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(90);
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
			setState(94);
			match(T__2);
			setState(95);
			match(T__0);
			setState(99);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(96);
				match(NL);
				}
				}
				setState(101);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(102);
			expr();
			setState(106);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(103);
				match(NL);
				}
				}
				setState(108);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(109);
			match(T__1);
			setState(113);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(110);
				match(NL);
				}
				}
				setState(115);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(116);
			expr();
			setState(120);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,14,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(117);
					match(NL);
					}
					} 
				}
				setState(122);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,14,_ctx);
			}
			setState(131);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,16,_ctx) ) {
			case 1:
				{
				setState(123);
				match(T__3);
				setState(127);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(124);
					match(NL);
					}
					}
					setState(129);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(130);
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

	public static class FunContext extends ParserRuleContext {
		public ChunkContext chunk() {
			return getRuleContext(ChunkContext.class,0);
		}
		public TerminalNode PIPE() { return getToken(VitaminCParser.PIPE, 0); }
		public List<AtomContext> atom() {
			return getRuleContexts(AtomContext.class);
		}
		public AtomContext atom(int i) {
			return getRuleContext(AtomContext.class,i);
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
		enterRule(_localctx, 10, RULE_fun);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(133);
			match(T__4);
			setState(145);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,19,_ctx) ) {
			case 1:
				{
				setState(135);
				_errHandler.sync(this);
				switch ( getInterpreter().adaptivePredict(_input,17,_ctx) ) {
				case 1:
					{
					setState(134);
					atom();
					}
					break;
				}
				setState(141);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==T__5) {
					{
					{
					setState(137);
					match(T__5);
					setState(138);
					atom();
					}
					}
					setState(143);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(144);
				match(PIPE);
				}
				break;
			}
			setState(147);
			chunk();
			setState(148);
			match(T__6);
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
		enterRule(_localctx, 12, RULE_call);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(150);
			atom();
			setState(151);
			match(T__0);
			setState(153);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << T__0) | (1L << T__2) | (1L << T__4) | (1L << T__7) | (1L << T__8) | (1L << Real) | (1L << Int) | (1L << String) | (1L << Name) | (1L << LANGLE) | (1L << RANGLE) | (1L << QUOTE) | (1L << EQUAL) | (1L << COLON) | (1L << PIPE) | (1L << Symbol))) != 0)) {
				{
				setState(152);
				callArg();
				}
			}

			setState(159);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==T__5) {
				{
				{
				setState(155);
				match(T__5);
				setState(156);
				callArg();
				}
				}
				setState(161);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(162);
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
		enterRule(_localctx, 14, RULE_callArg);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(167);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,22,_ctx) ) {
			case 1:
				{
				setState(164);
				atom();
				setState(165);
				match(COLON);
				}
				break;
			}
			setState(169);
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
		enterRule(_localctx, 16, RULE_pragma);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(171);
			match(T__7);
			setState(174);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,23,_ctx) ) {
			case 1:
				{
				setState(172);
				atom();
				}
				break;
			case 2:
				{
				setState(173);
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
		enterRule(_localctx, 18, RULE_constant);
		try {
			setState(180);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__8:
			case Name:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case COLON:
			case PIPE:
			case Symbol:
				enterOuterAlt(_localctx, 1);
				{
				setState(176);
				atom();
				}
				break;
			case Int:
				enterOuterAlt(_localctx, 2);
				{
				setState(177);
				intn();
				}
				break;
			case Real:
				enterOuterAlt(_localctx, 3);
				{
				setState(178);
				real();
				}
				break;
			case String:
				enterOuterAlt(_localctx, 4);
				{
				setState(179);
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

	public static class AtomContext extends ParserRuleContext {
		public TerminalNode Name() { return getToken(VitaminCParser.Name, 0); }
		public TerminalNode Symbol() { return getToken(VitaminCParser.Symbol, 0); }
		public TerminalNode PIPE() { return getToken(VitaminCParser.PIPE, 0); }
		public TerminalNode QUOTE() { return getToken(VitaminCParser.QUOTE, 0); }
		public TerminalNode COLON() { return getToken(VitaminCParser.COLON, 0); }
		public TerminalNode EQUAL() { return getToken(VitaminCParser.EQUAL, 0); }
		public TerminalNode LANGLE() { return getToken(VitaminCParser.LANGLE, 0); }
		public TerminalNode RANGLE() { return getToken(VitaminCParser.RANGLE, 0); }
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
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
		enterRule(_localctx, 20, RULE_atom);
		try {
			setState(194);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case Name:
				enterOuterAlt(_localctx, 1);
				{
				setState(182);
				match(Name);
				}
				break;
			case Symbol:
				enterOuterAlt(_localctx, 2);
				{
				setState(183);
				match(Symbol);
				}
				break;
			case PIPE:
				enterOuterAlt(_localctx, 3);
				{
				setState(184);
				match(PIPE);
				}
				break;
			case QUOTE:
				enterOuterAlt(_localctx, 4);
				{
				setState(185);
				match(QUOTE);
				}
				break;
			case COLON:
				enterOuterAlt(_localctx, 5);
				{
				setState(186);
				match(COLON);
				}
				break;
			case EQUAL:
				enterOuterAlt(_localctx, 6);
				{
				setState(187);
				match(EQUAL);
				}
				break;
			case LANGLE:
				enterOuterAlt(_localctx, 7);
				{
				setState(188);
				match(LANGLE);
				}
				break;
			case RANGLE:
				enterOuterAlt(_localctx, 8);
				{
				setState(189);
				match(RANGLE);
				}
				break;
			case T__8:
				enterOuterAlt(_localctx, 9);
				{
				setState(190);
				match(T__8);
				setState(191);
				atom();
				setState(192);
				match(T__8);
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
		enterRule(_localctx, 22, RULE_intn);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(196);
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
		enterRule(_localctx, 24, RULE_real);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(198);
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
		enterRule(_localctx, 26, RULE_string);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(200);
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

	public static final String _serializedATN =
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\3\33\u00cd\4\2\t\2"+
		"\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4\13"+
		"\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\3\2\3\2\3\2\3\3\7\3#\n\3\f\3"+
		"\16\3&\13\3\3\3\5\3)\n\3\3\3\3\3\7\3-\n\3\f\3\16\3\60\13\3\3\3\6\3\63"+
		"\n\3\r\3\16\3\64\5\3\67\n\3\3\3\7\3:\n\3\f\3\16\3=\13\3\3\3\7\3@\n\3\f"+
		"\3\16\3C\13\3\3\4\6\4F\n\4\r\4\16\4G\3\5\3\5\3\5\3\5\3\5\3\5\3\5\7\5Q"+
		"\n\5\f\5\16\5T\13\5\3\5\3\5\7\5X\n\5\f\5\16\5[\13\5\3\5\3\5\5\5_\n\5\3"+
		"\6\3\6\3\6\7\6d\n\6\f\6\16\6g\13\6\3\6\3\6\7\6k\n\6\f\6\16\6n\13\6\3\6"+
		"\3\6\7\6r\n\6\f\6\16\6u\13\6\3\6\3\6\7\6y\n\6\f\6\16\6|\13\6\3\6\3\6\7"+
		"\6\u0080\n\6\f\6\16\6\u0083\13\6\3\6\5\6\u0086\n\6\3\7\3\7\5\7\u008a\n"+
		"\7\3\7\3\7\7\7\u008e\n\7\f\7\16\7\u0091\13\7\3\7\5\7\u0094\n\7\3\7\3\7"+
		"\3\7\3\b\3\b\3\b\5\b\u009c\n\b\3\b\3\b\7\b\u00a0\n\b\f\b\16\b\u00a3\13"+
		"\b\3\b\3\b\3\t\3\t\3\t\5\t\u00aa\n\t\3\t\3\t\3\n\3\n\3\n\5\n\u00b1\n\n"+
		"\3\13\3\13\3\13\3\13\5\13\u00b7\n\13\3\f\3\f\3\f\3\f\3\f\3\f\3\f\3\f\3"+
		"\f\3\f\3\f\3\f\5\f\u00c5\n\f\3\r\3\r\3\16\3\16\3\17\3\17\3\17\2\2\20\2"+
		"\4\6\b\n\f\16\20\22\24\26\30\32\34\2\2\2\u00e5\2\36\3\2\2\2\4$\3\2\2\2"+
		"\6E\3\2\2\2\b^\3\2\2\2\n`\3\2\2\2\f\u0087\3\2\2\2\16\u0098\3\2\2\2\20"+
		"\u00a9\3\2\2\2\22\u00ad\3\2\2\2\24\u00b6\3\2\2\2\26\u00c4\3\2\2\2\30\u00c6"+
		"\3\2\2\2\32\u00c8\3\2\2\2\34\u00ca\3\2\2\2\36\37\5\4\3\2\37 \7\2\2\3 "+
		"\3\3\2\2\2!#\7\16\2\2\"!\3\2\2\2#&\3\2\2\2$\"\3\2\2\2$%\3\2\2\2%(\3\2"+
		"\2\2&$\3\2\2\2\')\5\6\4\2(\'\3\2\2\2()\3\2\2\2);\3\2\2\2*.\7\31\2\2+-"+
		"\7\16\2\2,+\3\2\2\2-\60\3\2\2\2.,\3\2\2\2./\3\2\2\2/\67\3\2\2\2\60.\3"+
		"\2\2\2\61\63\7\16\2\2\62\61\3\2\2\2\63\64\3\2\2\2\64\62\3\2\2\2\64\65"+
		"\3\2\2\2\65\67\3\2\2\2\66*\3\2\2\2\66\62\3\2\2\2\678\3\2\2\28:\5\6\4\2"+
		"9\66\3\2\2\2:=\3\2\2\2;9\3\2\2\2;<\3\2\2\2<A\3\2\2\2=;\3\2\2\2>@\7\16"+
		"\2\2?>\3\2\2\2@C\3\2\2\2A?\3\2\2\2AB\3\2\2\2B\5\3\2\2\2CA\3\2\2\2DF\5"+
		"\b\5\2ED\3\2\2\2FG\3\2\2\2GE\3\2\2\2GH\3\2\2\2H\7\3\2\2\2I_\5\16\b\2J"+
		"_\5\24\13\2K_\5\22\n\2L_\5\n\6\2M_\5\f\7\2NR\7\3\2\2OQ\7\16\2\2PO\3\2"+
		"\2\2QT\3\2\2\2RP\3\2\2\2RS\3\2\2\2SU\3\2\2\2TR\3\2\2\2UY\5\6\4\2VX\7\16"+
		"\2\2WV\3\2\2\2X[\3\2\2\2YW\3\2\2\2YZ\3\2\2\2Z\\\3\2\2\2[Y\3\2\2\2\\]\7"+
		"\4\2\2]_\3\2\2\2^I\3\2\2\2^J\3\2\2\2^K\3\2\2\2^L\3\2\2\2^M\3\2\2\2^N\3"+
		"\2\2\2_\t\3\2\2\2`a\7\5\2\2ae\7\3\2\2bd\7\16\2\2cb\3\2\2\2dg\3\2\2\2e"+
		"c\3\2\2\2ef\3\2\2\2fh\3\2\2\2ge\3\2\2\2hl\5\6\4\2ik\7\16\2\2ji\3\2\2\2"+
		"kn\3\2\2\2lj\3\2\2\2lm\3\2\2\2mo\3\2\2\2nl\3\2\2\2os\7\4\2\2pr\7\16\2"+
		"\2qp\3\2\2\2ru\3\2\2\2sq\3\2\2\2st\3\2\2\2tv\3\2\2\2us\3\2\2\2vz\5\6\4"+
		"\2wy\7\16\2\2xw\3\2\2\2y|\3\2\2\2zx\3\2\2\2z{\3\2\2\2{\u0085\3\2\2\2|"+
		"z\3\2\2\2}\u0081\7\6\2\2~\u0080\7\16\2\2\177~\3\2\2\2\u0080\u0083\3\2"+
		"\2\2\u0081\177\3\2\2\2\u0081\u0082\3\2\2\2\u0082\u0084\3\2\2\2\u0083\u0081"+
		"\3\2\2\2\u0084\u0086\5\6\4\2\u0085}\3\2\2\2\u0085\u0086\3\2\2\2\u0086"+
		"\13\3\2\2\2\u0087\u0093\7\7\2\2\u0088\u008a\5\26\f\2\u0089\u0088\3\2\2"+
		"\2\u0089\u008a\3\2\2\2\u008a\u008f\3\2\2\2\u008b\u008c\7\b\2\2\u008c\u008e"+
		"\5\26\f\2\u008d\u008b\3\2\2\2\u008e\u0091\3\2\2\2\u008f\u008d\3\2\2\2"+
		"\u008f\u0090\3\2\2\2\u0090\u0092\3\2\2\2\u0091\u008f\3\2\2\2\u0092\u0094"+
		"\7\32\2\2\u0093\u0089\3\2\2\2\u0093\u0094\3\2\2\2\u0094\u0095\3\2\2\2"+
		"\u0095\u0096\5\4\3\2\u0096\u0097\7\t\2\2\u0097\r\3\2\2\2\u0098\u0099\5"+
		"\26\f\2\u0099\u009b\7\3\2\2\u009a\u009c\5\20\t\2\u009b\u009a\3\2\2\2\u009b"+
		"\u009c\3\2\2\2\u009c\u00a1\3\2\2\2\u009d\u009e\7\b\2\2\u009e\u00a0\5\20"+
		"\t\2\u009f\u009d\3\2\2\2\u00a0\u00a3\3\2\2\2\u00a1\u009f\3\2\2\2\u00a1"+
		"\u00a2\3\2\2\2\u00a2\u00a4\3\2\2\2\u00a3\u00a1\3\2\2\2\u00a4\u00a5\7\4"+
		"\2\2\u00a5\17\3\2\2\2\u00a6\u00a7\5\26\f\2\u00a7\u00a8\7\30\2\2\u00a8"+
		"\u00aa\3\2\2\2\u00a9\u00a6\3\2\2\2\u00a9\u00aa\3\2\2\2\u00aa\u00ab\3\2"+
		"\2\2\u00ab\u00ac\5\6\4\2\u00ac\21\3\2\2\2\u00ad\u00b0\7\n\2\2\u00ae\u00b1"+
		"\5\26\f\2\u00af\u00b1\5\16\b\2\u00b0\u00ae\3\2\2\2\u00b0\u00af\3\2\2\2"+
		"\u00b1\23\3\2\2\2\u00b2\u00b7\5\26\f\2\u00b3\u00b7\5\30\r\2\u00b4\u00b7"+
		"\5\32\16\2\u00b5\u00b7\5\34\17\2\u00b6\u00b2\3\2\2\2\u00b6\u00b3\3\2\2"+
		"\2\u00b6\u00b4\3\2\2\2\u00b6\u00b5\3\2\2\2\u00b7\25\3\2\2\2\u00b8\u00c5"+
		"\7\23\2\2\u00b9\u00c5\7\33\2\2\u00ba\u00c5\7\32\2\2\u00bb\u00c5\7\26\2"+
		"\2\u00bc\u00c5\7\30\2\2\u00bd\u00c5\7\27\2\2\u00be\u00c5\7\24\2\2\u00bf"+
		"\u00c5\7\25\2\2\u00c0\u00c1\7\13\2\2\u00c1\u00c2\5\26\f\2\u00c2\u00c3"+
		"\7\13\2\2\u00c3\u00c5\3\2\2\2\u00c4\u00b8\3\2\2\2\u00c4\u00b9\3\2\2\2"+
		"\u00c4\u00ba\3\2\2\2\u00c4\u00bb\3\2\2\2\u00c4\u00bc\3\2\2\2\u00c4\u00bd"+
		"\3\2\2\2\u00c4\u00be\3\2\2\2\u00c4\u00bf\3\2\2\2\u00c4\u00c0\3\2\2\2\u00c5"+
		"\27\3\2\2\2\u00c6\u00c7\7\20\2\2\u00c7\31\3\2\2\2\u00c8\u00c9\7\17\2\2"+
		"\u00c9\33\3\2\2\2\u00ca\u00cb\7\21\2\2\u00cb\35\3\2\2\2\34$(.\64\66;A"+
		"GRY^elsz\u0081\u0085\u0089\u008f\u0093\u009b\u00a1\u00a9\u00b0\u00b6\u00c4";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}