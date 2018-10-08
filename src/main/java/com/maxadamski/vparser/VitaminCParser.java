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
		T__9=10, T__10=11, T__11=12, T__12=13, T__13=14, T__14=15, T__15=16, T__16=17, 
		T__17=18, T__18=19, T__19=20, T__20=21, ShebangLine=22, WS=23, NL=24, 
		Flt=25, Int=26, Str=27, Comment=28, Name=29, MINUS=30, LANGLE=31, RANGLE=32, 
		QUOTE=33, EQUAL=34, COLON=35, SEMI=36, PIPE=37, Symbol=38;
	public static final int
		RULE_program = 0, RULE_chunk = 1, RULE_expr = 2, RULE_prim = 3, RULE_type = 4, 
		RULE_patt = 5, RULE_pattPrim = 6, RULE_letExpr = 7, RULE_ifExpr = 8, RULE_whileExpr = 9, 
		RULE_genItem = 10, RULE_genList = 11, RULE_parType = 12, RULE_parItem = 13, 
		RULE_parList = 14, RULE_funExpr = 15, RULE_argItem = 16, RULE_argList = 17, 
		RULE_lambda = 18, RULE_array = 19, RULE_literal = 20, RULE_vInt = 21, 
		RULE_vStr = 22, RULE_vFlt = 23, RULE_atom = 24;
	public static final String[] ruleNames = {
		"program", "chunk", "expr", "prim", "type", "patt", "pattPrim", "letExpr", 
		"ifExpr", "whileExpr", "genItem", "genList", "parType", "parItem", "parList", 
		"funExpr", "argItem", "argList", "lambda", "array", "literal", "vInt", 
		"vStr", "vFlt", "atom"
	};

	private static final String[] _LITERAL_NAMES = {
		null, "'#'", "'@'", "'('", "')'", "','", "'->'", "'()'", "'_'", "'let'", 
		"'if'", "'else'", "'while'", "'...'", "'fun'", "'with'", "'{'", "'}'", 
		"'in'", "'['", "']'", "'`'", null, null, null, null, null, null, null, 
		null, "'-'", "'<'", "'>'", "'''", "'='", "':'", "';'", "'|'"
	};
	private static final String[] _SYMBOLIC_NAMES = {
		null, null, null, null, null, null, null, null, null, null, null, null, 
		null, null, null, null, null, null, null, null, null, null, "ShebangLine", 
		"WS", "NL", "Flt", "Int", "Str", "Comment", "Name", "MINUS", "LANGLE", 
		"RANGLE", "QUOTE", "EQUAL", "COLON", "SEMI", "PIPE", "Symbol"
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
			setState(50);
			chunk();
			setState(51);
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
			setState(56);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,0,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(53);
					match(NL);
					}
					} 
				}
				setState(58);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,0,_ctx);
			}
			setState(85);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,6,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(62);
					_errHandler.sync(this);
					_la = _input.LA(1);
					while (_la==NL) {
						{
						{
						setState(59);
						match(NL);
						}
						}
						setState(64);
						_errHandler.sync(this);
						_la = _input.LA(1);
					}
					setState(67);
					_errHandler.sync(this);
					switch (_input.LA(1)) {
					case T__0:
					case T__1:
					case T__2:
					case T__8:
					case T__9:
					case T__11:
					case T__13:
					case T__15:
					case T__18:
					case T__20:
					case Flt:
					case Int:
					case Str:
					case Name:
					case MINUS:
					case LANGLE:
					case RANGLE:
					case QUOTE:
					case EQUAL:
					case Symbol:
						{
						setState(65);
						expr();
						}
						break;
					case SEMI:
						{
						setState(66);
						match(SEMI);
						}
						break;
					default:
						throw new NoViableAltException(this);
					}
					setState(81);
					_errHandler.sync(this);
					switch (_input.LA(1)) {
					case SEMI:
						{
						setState(69);
						match(SEMI);
						setState(73);
						_errHandler.sync(this);
						_alt = getInterpreter().adaptivePredict(_input,3,_ctx);
						while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
							if ( _alt==1 ) {
								{
								{
								setState(70);
								match(NL);
								}
								} 
							}
							setState(75);
							_errHandler.sync(this);
							_alt = getInterpreter().adaptivePredict(_input,3,_ctx);
						}
						}
						break;
					case NL:
						{
						setState(77); 
						_errHandler.sync(this);
						_alt = 1;
						do {
							switch (_alt) {
							case 1:
								{
								{
								setState(76);
								match(NL);
								}
								}
								break;
							default:
								throw new NoViableAltException(this);
							}
							setState(79); 
							_errHandler.sync(this);
							_alt = getInterpreter().adaptivePredict(_input,4,_ctx);
						} while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER );
						}
						break;
					default:
						throw new NoViableAltException(this);
					}
					}
					} 
				}
				setState(87);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,6,_ctx);
			}
			setState(90);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__0:
			case T__1:
			case T__2:
			case T__8:
			case T__9:
			case T__11:
			case T__13:
			case T__15:
			case T__18:
			case T__20:
			case Flt:
			case Int:
			case Str:
			case Name:
			case MINUS:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case Symbol:
				{
				setState(88);
				expr();
				}
				break;
			case SEMI:
				{
				setState(89);
				match(SEMI);
				}
				break;
			case EOF:
			case T__16:
			case NL:
				break;
			default:
				break;
			}
			setState(95);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(92);
				match(NL);
				}
				}
				setState(97);
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
		public LetExprContext letExpr() {
			return getRuleContext(LetExprContext.class,0);
		}
		public FunExprContext funExpr() {
			return getRuleContext(FunExprContext.class,0);
		}
		public IfExprContext ifExpr() {
			return getRuleContext(IfExprContext.class,0);
		}
		public WhileExprContext whileExpr() {
			return getRuleContext(WhileExprContext.class,0);
		}
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
		int _la;
		try {
			setState(107);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__8:
				enterOuterAlt(_localctx, 1);
				{
				setState(98);
				letExpr();
				}
				break;
			case T__13:
				enterOuterAlt(_localctx, 2);
				{
				setState(99);
				funExpr();
				}
				break;
			case T__9:
				enterOuterAlt(_localctx, 3);
				{
				setState(100);
				ifExpr();
				}
				break;
			case T__11:
				enterOuterAlt(_localctx, 4);
				{
				setState(101);
				whileExpr();
				}
				break;
			case T__0:
			case T__1:
			case T__2:
			case T__15:
			case T__18:
			case T__20:
			case Flt:
			case Int:
			case Str:
			case Name:
			case MINUS:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case Symbol:
				enterOuterAlt(_localctx, 5);
				{
				setState(103); 
				_errHandler.sync(this);
				_la = _input.LA(1);
				do {
					{
					{
					setState(102);
					prim(0);
					}
					}
					setState(105); 
					_errHandler.sync(this);
					_la = _input.LA(1);
				} while ( (((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << T__0) | (1L << T__1) | (1L << T__2) | (1L << T__15) | (1L << T__18) | (1L << T__20) | (1L << Flt) | (1L << Int) | (1L << Str) | (1L << Name) | (1L << MINUS) | (1L << LANGLE) | (1L << RANGLE) | (1L << QUOTE) | (1L << EQUAL) | (1L << Symbol))) != 0) );
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

	public static class PrimContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public List<TerminalNode> NL() { return getTokens(VitaminCParser.NL); }
		public TerminalNode NL(int i) {
			return getToken(VitaminCParser.NL, i);
		}
		public LambdaContext lambda() {
			return getRuleContext(LambdaContext.class,0);
		}
		public LiteralContext literal() {
			return getRuleContext(LiteralContext.class,0);
		}
		public ExprContext expr() {
			return getRuleContext(ExprContext.class,0);
		}
		public PrimContext prim() {
			return getRuleContext(PrimContext.class,0);
		}
		public ArgListContext argList() {
			return getRuleContext(ArgListContext.class,0);
		}
		public PrimContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_prim; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterPrim(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitPrim(this);
		}
	}

	public final PrimContext prim() throws RecognitionException {
		return prim(0);
	}

	private PrimContext prim(int _p) throws RecognitionException {
		ParserRuleContext _parentctx = _ctx;
		int _parentState = getState();
		PrimContext _localctx = new PrimContext(_ctx, _parentState);
		PrimContext _prevctx = _localctx;
		int _startState = 6;
		enterRecursionRule(_localctx, 6, RULE_prim, _p);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(137);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__0:
			case T__20:
			case Name:
			case MINUS:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case Symbol:
				{
				setState(111);
				_errHandler.sync(this);
				_la = _input.LA(1);
				if (_la==T__0) {
					{
					setState(110);
					match(T__0);
					}
				}

				setState(113);
				atom();
				}
				break;
			case T__1:
				{
				setState(114);
				match(T__1);
				setState(115);
				atom();
				setState(117);
				_errHandler.sync(this);
				switch ( getInterpreter().adaptivePredict(_input,12,_ctx) ) {
				case 1:
					{
					setState(116);
					match(NL);
					}
					break;
				}
				}
				break;
			case T__15:
				{
				setState(119);
				lambda();
				}
				break;
			case T__18:
			case Flt:
			case Int:
			case Str:
				{
				setState(120);
				literal();
				}
				break;
			case T__2:
				{
				setState(121);
				match(T__2);
				setState(125);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(122);
					match(NL);
					}
					}
					setState(127);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(128);
				expr();
				setState(132);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(129);
					match(NL);
					}
					}
					setState(134);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(135);
				match(T__3);
				}
				break;
			default:
				throw new NoViableAltException(this);
			}
			_ctx.stop = _input.LT(-1);
			setState(143);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,16,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					if ( _parseListeners!=null ) triggerExitRuleEvent();
					_prevctx = _localctx;
					{
					{
					_localctx = new PrimContext(_parentctx, _parentState);
					pushNewRecursionContext(_localctx, _startState, RULE_prim);
					setState(139);
					if (!(precpred(_ctx, 6))) throw new FailedPredicateException(this, "precpred(_ctx, 6)");
					setState(140);
					argList();
					}
					} 
				}
				setState(145);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,16,_ctx);
			}
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			unrollRecursionContexts(_parentctx);
		}
		return _localctx;
	}

	public static class TypeContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public List<TypeContext> type() {
			return getRuleContexts(TypeContext.class);
		}
		public TypeContext type(int i) {
			return getRuleContext(TypeContext.class,i);
		}
		public TypeContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_type; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterType(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitType(this);
		}
	}

	public final TypeContext type() throws RecognitionException {
		return type(0);
	}

	private TypeContext type(int _p) throws RecognitionException {
		ParserRuleContext _parentctx = _ctx;
		int _parentState = getState();
		TypeContext _localctx = new TypeContext(_ctx, _parentState);
		TypeContext _prevctx = _localctx;
		int _startState = 8;
		enterRecursionRule(_localctx, 8, RULE_type, _p);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(162);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__20:
			case Name:
			case MINUS:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case Symbol:
				{
				setState(147);
				atom();
				setState(159);
				_errHandler.sync(this);
				switch ( getInterpreter().adaptivePredict(_input,18,_ctx) ) {
				case 1:
					{
					setState(148);
					match(T__2);
					setState(149);
					type(0);
					setState(154);
					_errHandler.sync(this);
					_la = _input.LA(1);
					while (_la==T__4) {
						{
						{
						setState(150);
						match(T__4);
						setState(151);
						type(0);
						}
						}
						setState(156);
						_errHandler.sync(this);
						_la = _input.LA(1);
					}
					setState(157);
					match(T__3);
					}
					break;
				}
				}
				break;
			case T__6:
				{
				setState(161);
				match(T__6);
				}
				break;
			default:
				throw new NoViableAltException(this);
			}
			_ctx.stop = _input.LT(-1);
			setState(169);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,20,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					if ( _parseListeners!=null ) triggerExitRuleEvent();
					_prevctx = _localctx;
					{
					{
					_localctx = new TypeContext(_parentctx, _parentState);
					pushNewRecursionContext(_localctx, _startState, RULE_type);
					setState(164);
					if (!(precpred(_ctx, 2))) throw new FailedPredicateException(this, "precpred(_ctx, 2)");
					setState(165);
					match(T__5);
					setState(166);
					type(3);
					}
					} 
				}
				setState(171);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,20,_ctx);
			}
			}
		}
		catch (RecognitionException re) {
			_localctx.exception = re;
			_errHandler.reportError(this, re);
			_errHandler.recover(this, re);
		}
		finally {
			unrollRecursionContexts(_parentctx);
		}
		return _localctx;
	}

	public static class PattContext extends ParserRuleContext {
		public List<PattPrimContext> pattPrim() {
			return getRuleContexts(PattPrimContext.class);
		}
		public PattPrimContext pattPrim(int i) {
			return getRuleContext(PattPrimContext.class,i);
		}
		public PattContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_patt; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterPatt(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitPatt(this);
		}
	}

	public final PattContext patt() throws RecognitionException {
		PattContext _localctx = new PattContext(_ctx, getState());
		enterRule(_localctx, 10, RULE_patt);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(172);
			pattPrim();
			setState(177);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==T__4) {
				{
				{
				setState(173);
				match(T__4);
				setState(174);
				pattPrim();
				}
				}
				setState(179);
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

	public static class PattPrimContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public PattContext patt() {
			return getRuleContext(PattContext.class,0);
		}
		public PattPrimContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_pattPrim; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterPattPrim(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitPattPrim(this);
		}
	}

	public final PattPrimContext pattPrim() throws RecognitionException {
		PattPrimContext _localctx = new PattPrimContext(_ctx, getState());
		enterRule(_localctx, 12, RULE_pattPrim);
		try {
			setState(186);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__7:
				enterOuterAlt(_localctx, 1);
				{
				setState(180);
				match(T__7);
				}
				break;
			case T__20:
			case Name:
			case MINUS:
			case LANGLE:
			case RANGLE:
			case QUOTE:
			case EQUAL:
			case Symbol:
				enterOuterAlt(_localctx, 2);
				{
				setState(181);
				atom();
				}
				break;
			case T__2:
				enterOuterAlt(_localctx, 3);
				{
				setState(182);
				match(T__2);
				setState(183);
				patt();
				setState(184);
				match(T__3);
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

	public static class LetExprContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public ExprContext expr() {
			return getRuleContext(ExprContext.class,0);
		}
		public TypeContext type() {
			return getRuleContext(TypeContext.class,0);
		}
		public LetExprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_letExpr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterLetExpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitLetExpr(this);
		}
	}

	public final LetExprContext letExpr() throws RecognitionException {
		LetExprContext _localctx = new LetExprContext(_ctx, getState());
		enterRule(_localctx, 14, RULE_letExpr);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(188);
			match(T__8);
			setState(189);
			atom();
			setState(192);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if (_la==COLON) {
				{
				setState(190);
				match(COLON);
				setState(191);
				type(0);
				}
			}

			setState(194);
			match(EQUAL);
			setState(195);
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

	public static class IfExprContext extends ParserRuleContext {
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
		public IfExprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_ifExpr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterIfExpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitIfExpr(this);
		}
	}

	public final IfExprContext ifExpr() throws RecognitionException {
		IfExprContext _localctx = new IfExprContext(_ctx, getState());
		enterRule(_localctx, 16, RULE_ifExpr);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(197);
			match(T__9);
			setState(198);
			match(T__2);
			setState(202);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(199);
				match(NL);
				}
				}
				setState(204);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(205);
			expr();
			setState(209);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(206);
				match(NL);
				}
				}
				setState(211);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(212);
			match(T__3);
			setState(216);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(213);
				match(NL);
				}
				}
				setState(218);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(219);
			expr();
			setState(223);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,27,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(220);
					match(NL);
					}
					} 
				}
				setState(225);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,27,_ctx);
			}
			setState(234);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,29,_ctx) ) {
			case 1:
				{
				setState(226);
				match(T__10);
				setState(230);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==NL) {
					{
					{
					setState(227);
					match(NL);
					}
					}
					setState(232);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(233);
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

	public static class WhileExprContext extends ParserRuleContext {
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
		public WhileExprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_whileExpr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterWhileExpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitWhileExpr(this);
		}
	}

	public final WhileExprContext whileExpr() throws RecognitionException {
		WhileExprContext _localctx = new WhileExprContext(_ctx, getState());
		enterRule(_localctx, 18, RULE_whileExpr);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(236);
			match(T__11);
			setState(237);
			match(T__2);
			setState(241);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(238);
				match(NL);
				}
				}
				setState(243);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(244);
			expr();
			setState(248);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(245);
				match(NL);
				}
				}
				setState(250);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(251);
			match(T__3);
			setState(255);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(252);
				match(NL);
				}
				}
				setState(257);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(258);
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

	public static class GenItemContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public GenItemContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_genItem; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterGenItem(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitGenItem(this);
		}
	}

	public final GenItemContext genItem() throws RecognitionException {
		GenItemContext _localctx = new GenItemContext(_ctx, getState());
		enterRule(_localctx, 20, RULE_genItem);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(260);
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

	public static class GenListContext extends ParserRuleContext {
		public List<GenItemContext> genItem() {
			return getRuleContexts(GenItemContext.class);
		}
		public GenItemContext genItem(int i) {
			return getRuleContext(GenItemContext.class,i);
		}
		public GenListContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_genList; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterGenList(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitGenList(this);
		}
	}

	public final GenListContext genList() throws RecognitionException {
		GenListContext _localctx = new GenListContext(_ctx, getState());
		enterRule(_localctx, 22, RULE_genList);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(262);
			match(T__2);
			setState(263);
			genItem();
			setState(268);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==T__4) {
				{
				{
				setState(264);
				match(T__4);
				setState(265);
				genItem();
				}
				}
				setState(270);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(271);
			match(T__3);
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

	public static class ParTypeContext extends ParserRuleContext {
		public TypeContext type() {
			return getRuleContext(TypeContext.class,0);
		}
		public ParTypeContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_parType; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterParType(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitParType(this);
		}
	}

	public final ParTypeContext parType() throws RecognitionException {
		ParTypeContext _localctx = new ParTypeContext(_ctx, getState());
		enterRule(_localctx, 24, RULE_parType);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(273);
			type(0);
			setState(275);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if (_la==T__12) {
				{
				setState(274);
				match(T__12);
				}
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

	public static class ParItemContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public ParTypeContext parType() {
			return getRuleContext(ParTypeContext.class,0);
		}
		public ExprContext expr() {
			return getRuleContext(ExprContext.class,0);
		}
		public ParItemContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_parItem; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterParItem(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitParItem(this);
		}
	}

	public final ParItemContext parItem() throws RecognitionException {
		ParItemContext _localctx = new ParItemContext(_ctx, getState());
		enterRule(_localctx, 26, RULE_parItem);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(277);
			atom();
			setState(278);
			match(COLON);
			setState(279);
			parType();
			setState(282);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if (_la==EQUAL) {
				{
				setState(280);
				match(EQUAL);
				setState(281);
				expr();
				}
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

	public static class ParListContext extends ParserRuleContext {
		public List<ParItemContext> parItem() {
			return getRuleContexts(ParItemContext.class);
		}
		public ParItemContext parItem(int i) {
			return getRuleContext(ParItemContext.class,i);
		}
		public ParListContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_parList; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterParList(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitParList(this);
		}
	}

	public final ParListContext parList() throws RecognitionException {
		ParListContext _localctx = new ParListContext(_ctx, getState());
		enterRule(_localctx, 28, RULE_parList);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(284);
			match(T__2);
			setState(293);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << T__20) | (1L << Name) | (1L << MINUS) | (1L << LANGLE) | (1L << RANGLE) | (1L << QUOTE) | (1L << EQUAL) | (1L << Symbol))) != 0)) {
				{
				setState(285);
				parItem();
				setState(290);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==T__4) {
					{
					{
					setState(286);
					match(T__4);
					setState(287);
					parItem();
					}
					}
					setState(292);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				}
			}

			setState(295);
			match(T__3);
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

	public static class FunExprContext extends ParserRuleContext {
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public ParListContext parList() {
			return getRuleContext(ParListContext.class,0);
		}
		public ChunkContext chunk() {
			return getRuleContext(ChunkContext.class,0);
		}
		public TypeContext type() {
			return getRuleContext(TypeContext.class,0);
		}
		public GenListContext genList() {
			return getRuleContext(GenListContext.class,0);
		}
		public FunExprContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_funExpr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterFunExpr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitFunExpr(this);
		}
	}

	public final FunExprContext funExpr() throws RecognitionException {
		FunExprContext _localctx = new FunExprContext(_ctx, getState());
		enterRule(_localctx, 30, RULE_funExpr);
		int _la;
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(297);
			match(T__13);
			setState(298);
			atom();
			setState(299);
			parList();
			setState(302);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if (_la==T__5) {
				{
				setState(300);
				match(T__5);
				setState(301);
				type(0);
				}
			}

			setState(306);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if (_la==T__14) {
				{
				setState(304);
				match(T__14);
				setState(305);
				genList();
				}
			}

			setState(308);
			match(T__15);
			setState(309);
			chunk();
			setState(310);
			match(T__16);
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

	public static class ArgItemContext extends ParserRuleContext {
		public ExprContext expr() {
			return getRuleContext(ExprContext.class,0);
		}
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public ArgItemContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_argItem; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterArgItem(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitArgItem(this);
		}
	}

	public final ArgItemContext argItem() throws RecognitionException {
		ArgItemContext _localctx = new ArgItemContext(_ctx, getState());
		enterRule(_localctx, 32, RULE_argItem);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(315);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,40,_ctx) ) {
			case 1:
				{
				setState(312);
				atom();
				setState(313);
				match(COLON);
				}
				break;
			}
			setState(317);
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

	public static class ArgListContext extends ParserRuleContext {
		public List<ArgItemContext> argItem() {
			return getRuleContexts(ArgItemContext.class);
		}
		public ArgItemContext argItem(int i) {
			return getRuleContext(ArgItemContext.class,i);
		}
		public ArgListContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_argList; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterArgList(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitArgList(this);
		}
	}

	public final ArgListContext argList() throws RecognitionException {
		ArgListContext _localctx = new ArgListContext(_ctx, getState());
		enterRule(_localctx, 34, RULE_argList);
		int _la;
		try {
			setState(331);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__6:
				enterOuterAlt(_localctx, 1);
				{
				setState(319);
				match(T__6);
				}
				break;
			case T__2:
				enterOuterAlt(_localctx, 2);
				{
				setState(320);
				match(T__2);
				setState(321);
				argItem();
				setState(326);
				_errHandler.sync(this);
				_la = _input.LA(1);
				while (_la==T__4) {
					{
					{
					setState(322);
					match(T__4);
					setState(323);
					argItem();
					}
					}
					setState(328);
					_errHandler.sync(this);
					_la = _input.LA(1);
				}
				setState(329);
				match(T__3);
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

	public static class LambdaContext extends ParserRuleContext {
		public ChunkContext chunk() {
			return getRuleContext(ChunkContext.class,0);
		}
		public PattContext patt() {
			return getRuleContext(PattContext.class,0);
		}
		public LambdaContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_lambda; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterLambda(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitLambda(this);
		}
	}

	public final LambdaContext lambda() throws RecognitionException {
		LambdaContext _localctx = new LambdaContext(_ctx, getState());
		enterRule(_localctx, 36, RULE_lambda);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(333);
			match(T__15);
			setState(337);
			_errHandler.sync(this);
			switch ( getInterpreter().adaptivePredict(_input,43,_ctx) ) {
			case 1:
				{
				setState(334);
				patt();
				setState(335);
				match(T__17);
				}
				break;
			}
			setState(339);
			chunk();
			setState(340);
			match(T__16);
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

	public static class ArrayContext extends ParserRuleContext {
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
		public ArrayContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_array; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterArray(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitArray(this);
		}
	}

	public final ArrayContext array() throws RecognitionException {
		ArrayContext _localctx = new ArrayContext(_ctx, getState());
		enterRule(_localctx, 38, RULE_array);
		int _la;
		try {
			int _alt;
			enterOuterAlt(_localctx, 1);
			{
			setState(342);
			match(T__18);
			setState(346);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,44,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(343);
					match(NL);
					}
					} 
				}
				setState(348);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,44,_ctx);
			}
			setState(350);
			_errHandler.sync(this);
			_la = _input.LA(1);
			if ((((_la) & ~0x3f) == 0 && ((1L << _la) & ((1L << T__0) | (1L << T__1) | (1L << T__2) | (1L << T__8) | (1L << T__9) | (1L << T__11) | (1L << T__13) | (1L << T__15) | (1L << T__18) | (1L << T__20) | (1L << Flt) | (1L << Int) | (1L << Str) | (1L << Name) | (1L << MINUS) | (1L << LANGLE) | (1L << RANGLE) | (1L << QUOTE) | (1L << EQUAL) | (1L << Symbol))) != 0)) {
				{
				setState(349);
				expr();
				}
			}

			setState(368);
			_errHandler.sync(this);
			_alt = getInterpreter().adaptivePredict(_input,48,_ctx);
			while ( _alt!=2 && _alt!=org.antlr.v4.runtime.atn.ATN.INVALID_ALT_NUMBER ) {
				if ( _alt==1 ) {
					{
					{
					setState(355);
					_errHandler.sync(this);
					_la = _input.LA(1);
					while (_la==NL) {
						{
						{
						setState(352);
						match(NL);
						}
						}
						setState(357);
						_errHandler.sync(this);
						_la = _input.LA(1);
					}
					setState(358);
					match(T__4);
					setState(362);
					_errHandler.sync(this);
					_la = _input.LA(1);
					while (_la==NL) {
						{
						{
						setState(359);
						match(NL);
						}
						}
						setState(364);
						_errHandler.sync(this);
						_la = _input.LA(1);
					}
					setState(365);
					expr();
					}
					} 
				}
				setState(370);
				_errHandler.sync(this);
				_alt = getInterpreter().adaptivePredict(_input,48,_ctx);
			}
			setState(374);
			_errHandler.sync(this);
			_la = _input.LA(1);
			while (_la==NL) {
				{
				{
				setState(371);
				match(NL);
				}
				}
				setState(376);
				_errHandler.sync(this);
				_la = _input.LA(1);
			}
			setState(377);
			match(T__19);
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

	public static class LiteralContext extends ParserRuleContext {
		public VIntContext vInt() {
			return getRuleContext(VIntContext.class,0);
		}
		public VFltContext vFlt() {
			return getRuleContext(VFltContext.class,0);
		}
		public VStrContext vStr() {
			return getRuleContext(VStrContext.class,0);
		}
		public ArrayContext array() {
			return getRuleContext(ArrayContext.class,0);
		}
		public LiteralContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_literal; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterLiteral(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitLiteral(this);
		}
	}

	public final LiteralContext literal() throws RecognitionException {
		LiteralContext _localctx = new LiteralContext(_ctx, getState());
		enterRule(_localctx, 40, RULE_literal);
		try {
			setState(383);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case Int:
				enterOuterAlt(_localctx, 1);
				{
				setState(379);
				vInt();
				}
				break;
			case Flt:
				enterOuterAlt(_localctx, 2);
				{
				setState(380);
				vFlt();
				}
				break;
			case Str:
				enterOuterAlt(_localctx, 3);
				{
				setState(381);
				vStr();
				}
				break;
			case T__18:
				enterOuterAlt(_localctx, 4);
				{
				setState(382);
				array();
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

	public static class VIntContext extends ParserRuleContext {
		public TerminalNode Int() { return getToken(VitaminCParser.Int, 0); }
		public VIntContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_vInt; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterVInt(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitVInt(this);
		}
	}

	public final VIntContext vInt() throws RecognitionException {
		VIntContext _localctx = new VIntContext(_ctx, getState());
		enterRule(_localctx, 42, RULE_vInt);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(385);
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

	public static class VStrContext extends ParserRuleContext {
		public TerminalNode Str() { return getToken(VitaminCParser.Str, 0); }
		public VStrContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_vStr; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterVStr(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitVStr(this);
		}
	}

	public final VStrContext vStr() throws RecognitionException {
		VStrContext _localctx = new VStrContext(_ctx, getState());
		enterRule(_localctx, 44, RULE_vStr);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(387);
			match(Str);
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

	public static class VFltContext extends ParserRuleContext {
		public TerminalNode Flt() { return getToken(VitaminCParser.Flt, 0); }
		public VFltContext(ParserRuleContext parent, int invokingState) {
			super(parent, invokingState);
		}
		@Override public int getRuleIndex() { return RULE_vFlt; }
		@Override
		public void enterRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).enterVFlt(this);
		}
		@Override
		public void exitRule(ParseTreeListener listener) {
			if ( listener instanceof VitaminCListener ) ((VitaminCListener)listener).exitVFlt(this);
		}
	}

	public final VFltContext vFlt() throws RecognitionException {
		VFltContext _localctx = new VFltContext(_ctx, getState());
		enterRule(_localctx, 46, RULE_vFlt);
		try {
			enterOuterAlt(_localctx, 1);
			{
			setState(389);
			match(Flt);
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
		public AtomContext atom() {
			return getRuleContext(AtomContext.class,0);
		}
		public TerminalNode Name() { return getToken(VitaminCParser.Name, 0); }
		public TerminalNode Symbol() { return getToken(VitaminCParser.Symbol, 0); }
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
		enterRule(_localctx, 48, RULE_atom);
		try {
			setState(402);
			_errHandler.sync(this);
			switch (_input.LA(1)) {
			case T__20:
				enterOuterAlt(_localctx, 1);
				{
				setState(391);
				match(T__20);
				setState(392);
				atom();
				setState(393);
				match(T__20);
				}
				break;
			case Name:
				enterOuterAlt(_localctx, 2);
				{
				setState(395);
				match(Name);
				}
				break;
			case Symbol:
				enterOuterAlt(_localctx, 3);
				{
				setState(396);
				match(Symbol);
				}
				break;
			case LANGLE:
				enterOuterAlt(_localctx, 4);
				{
				setState(397);
				match(LANGLE);
				}
				break;
			case RANGLE:
				enterOuterAlt(_localctx, 5);
				{
				setState(398);
				match(RANGLE);
				}
				break;
			case EQUAL:
				enterOuterAlt(_localctx, 6);
				{
				setState(399);
				match(EQUAL);
				}
				break;
			case MINUS:
				enterOuterAlt(_localctx, 7);
				{
				setState(400);
				match(MINUS);
				}
				break;
			case QUOTE:
				enterOuterAlt(_localctx, 8);
				{
				setState(401);
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

	public boolean sempred(RuleContext _localctx, int ruleIndex, int predIndex) {
		switch (ruleIndex) {
		case 3:
			return prim_sempred((PrimContext)_localctx, predIndex);
		case 4:
			return type_sempred((TypeContext)_localctx, predIndex);
		}
		return true;
	}
	private boolean prim_sempred(PrimContext _localctx, int predIndex) {
		switch (predIndex) {
		case 0:
			return precpred(_ctx, 6);
		}
		return true;
	}
	private boolean type_sempred(TypeContext _localctx, int predIndex) {
		switch (predIndex) {
		case 1:
			return precpred(_ctx, 2);
		}
		return true;
	}

	public static final String _serializedATN =
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\3(\u0197\4\2\t\2\4"+
		"\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4\13\t"+
		"\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22\t\22"+
		"\4\23\t\23\4\24\t\24\4\25\t\25\4\26\t\26\4\27\t\27\4\30\t\30\4\31\t\31"+
		"\4\32\t\32\3\2\3\2\3\2\3\3\7\39\n\3\f\3\16\3<\13\3\3\3\7\3?\n\3\f\3\16"+
		"\3B\13\3\3\3\3\3\5\3F\n\3\3\3\3\3\7\3J\n\3\f\3\16\3M\13\3\3\3\6\3P\n\3"+
		"\r\3\16\3Q\5\3T\n\3\7\3V\n\3\f\3\16\3Y\13\3\3\3\3\3\5\3]\n\3\3\3\7\3`"+
		"\n\3\f\3\16\3c\13\3\3\4\3\4\3\4\3\4\3\4\6\4j\n\4\r\4\16\4k\5\4n\n\4\3"+
		"\5\3\5\5\5r\n\5\3\5\3\5\3\5\3\5\5\5x\n\5\3\5\3\5\3\5\3\5\7\5~\n\5\f\5"+
		"\16\5\u0081\13\5\3\5\3\5\7\5\u0085\n\5\f\5\16\5\u0088\13\5\3\5\3\5\5\5"+
		"\u008c\n\5\3\5\3\5\7\5\u0090\n\5\f\5\16\5\u0093\13\5\3\6\3\6\3\6\3\6\3"+
		"\6\3\6\7\6\u009b\n\6\f\6\16\6\u009e\13\6\3\6\3\6\5\6\u00a2\n\6\3\6\5\6"+
		"\u00a5\n\6\3\6\3\6\3\6\7\6\u00aa\n\6\f\6\16\6\u00ad\13\6\3\7\3\7\3\7\7"+
		"\7\u00b2\n\7\f\7\16\7\u00b5\13\7\3\b\3\b\3\b\3\b\3\b\3\b\5\b\u00bd\n\b"+
		"\3\t\3\t\3\t\3\t\5\t\u00c3\n\t\3\t\3\t\3\t\3\n\3\n\3\n\7\n\u00cb\n\n\f"+
		"\n\16\n\u00ce\13\n\3\n\3\n\7\n\u00d2\n\n\f\n\16\n\u00d5\13\n\3\n\3\n\7"+
		"\n\u00d9\n\n\f\n\16\n\u00dc\13\n\3\n\3\n\7\n\u00e0\n\n\f\n\16\n\u00e3"+
		"\13\n\3\n\3\n\7\n\u00e7\n\n\f\n\16\n\u00ea\13\n\3\n\5\n\u00ed\n\n\3\13"+
		"\3\13\3\13\7\13\u00f2\n\13\f\13\16\13\u00f5\13\13\3\13\3\13\7\13\u00f9"+
		"\n\13\f\13\16\13\u00fc\13\13\3\13\3\13\7\13\u0100\n\13\f\13\16\13\u0103"+
		"\13\13\3\13\3\13\3\f\3\f\3\r\3\r\3\r\3\r\7\r\u010d\n\r\f\r\16\r\u0110"+
		"\13\r\3\r\3\r\3\16\3\16\5\16\u0116\n\16\3\17\3\17\3\17\3\17\3\17\5\17"+
		"\u011d\n\17\3\20\3\20\3\20\3\20\7\20\u0123\n\20\f\20\16\20\u0126\13\20"+
		"\5\20\u0128\n\20\3\20\3\20\3\21\3\21\3\21\3\21\3\21\5\21\u0131\n\21\3"+
		"\21\3\21\5\21\u0135\n\21\3\21\3\21\3\21\3\21\3\22\3\22\3\22\5\22\u013e"+
		"\n\22\3\22\3\22\3\23\3\23\3\23\3\23\3\23\7\23\u0147\n\23\f\23\16\23\u014a"+
		"\13\23\3\23\3\23\5\23\u014e\n\23\3\24\3\24\3\24\3\24\5\24\u0154\n\24\3"+
		"\24\3\24\3\24\3\25\3\25\7\25\u015b\n\25\f\25\16\25\u015e\13\25\3\25\5"+
		"\25\u0161\n\25\3\25\7\25\u0164\n\25\f\25\16\25\u0167\13\25\3\25\3\25\7"+
		"\25\u016b\n\25\f\25\16\25\u016e\13\25\3\25\7\25\u0171\n\25\f\25\16\25"+
		"\u0174\13\25\3\25\7\25\u0177\n\25\f\25\16\25\u017a\13\25\3\25\3\25\3\26"+
		"\3\26\3\26\3\26\5\26\u0182\n\26\3\27\3\27\3\30\3\30\3\31\3\31\3\32\3\32"+
		"\3\32\3\32\3\32\3\32\3\32\3\32\3\32\3\32\3\32\5\32\u0195\n\32\3\32\2\4"+
		"\b\n\33\2\4\6\b\n\f\16\20\22\24\26\30\32\34\36 \"$&(*,.\60\62\2\2\2\u01c1"+
		"\2\64\3\2\2\2\4:\3\2\2\2\6m\3\2\2\2\b\u008b\3\2\2\2\n\u00a4\3\2\2\2\f"+
		"\u00ae\3\2\2\2\16\u00bc\3\2\2\2\20\u00be\3\2\2\2\22\u00c7\3\2\2\2\24\u00ee"+
		"\3\2\2\2\26\u0106\3\2\2\2\30\u0108\3\2\2\2\32\u0113\3\2\2\2\34\u0117\3"+
		"\2\2\2\36\u011e\3\2\2\2 \u012b\3\2\2\2\"\u013d\3\2\2\2$\u014d\3\2\2\2"+
		"&\u014f\3\2\2\2(\u0158\3\2\2\2*\u0181\3\2\2\2,\u0183\3\2\2\2.\u0185\3"+
		"\2\2\2\60\u0187\3\2\2\2\62\u0194\3\2\2\2\64\65\5\4\3\2\65\66\7\2\2\3\66"+
		"\3\3\2\2\2\679\7\32\2\28\67\3\2\2\29<\3\2\2\2:8\3\2\2\2:;\3\2\2\2;W\3"+
		"\2\2\2<:\3\2\2\2=?\7\32\2\2>=\3\2\2\2?B\3\2\2\2@>\3\2\2\2@A\3\2\2\2AE"+
		"\3\2\2\2B@\3\2\2\2CF\5\6\4\2DF\7&\2\2EC\3\2\2\2ED\3\2\2\2FS\3\2\2\2GK"+
		"\7&\2\2HJ\7\32\2\2IH\3\2\2\2JM\3\2\2\2KI\3\2\2\2KL\3\2\2\2LT\3\2\2\2M"+
		"K\3\2\2\2NP\7\32\2\2ON\3\2\2\2PQ\3\2\2\2QO\3\2\2\2QR\3\2\2\2RT\3\2\2\2"+
		"SG\3\2\2\2SO\3\2\2\2TV\3\2\2\2U@\3\2\2\2VY\3\2\2\2WU\3\2\2\2WX\3\2\2\2"+
		"X\\\3\2\2\2YW\3\2\2\2Z]\5\6\4\2[]\7&\2\2\\Z\3\2\2\2\\[\3\2\2\2\\]\3\2"+
		"\2\2]a\3\2\2\2^`\7\32\2\2_^\3\2\2\2`c\3\2\2\2a_\3\2\2\2ab\3\2\2\2b\5\3"+
		"\2\2\2ca\3\2\2\2dn\5\20\t\2en\5 \21\2fn\5\22\n\2gn\5\24\13\2hj\5\b\5\2"+
		"ih\3\2\2\2jk\3\2\2\2ki\3\2\2\2kl\3\2\2\2ln\3\2\2\2md\3\2\2\2me\3\2\2\2"+
		"mf\3\2\2\2mg\3\2\2\2mi\3\2\2\2n\7\3\2\2\2oq\b\5\1\2pr\7\3\2\2qp\3\2\2"+
		"\2qr\3\2\2\2rs\3\2\2\2s\u008c\5\62\32\2tu\7\4\2\2uw\5\62\32\2vx\7\32\2"+
		"\2wv\3\2\2\2wx\3\2\2\2x\u008c\3\2\2\2y\u008c\5&\24\2z\u008c\5*\26\2{\177"+
		"\7\5\2\2|~\7\32\2\2}|\3\2\2\2~\u0081\3\2\2\2\177}\3\2\2\2\177\u0080\3"+
		"\2\2\2\u0080\u0082\3\2\2\2\u0081\177\3\2\2\2\u0082\u0086\5\6\4\2\u0083"+
		"\u0085\7\32\2\2\u0084\u0083\3\2\2\2\u0085\u0088\3\2\2\2\u0086\u0084\3"+
		"\2\2\2\u0086\u0087\3\2\2\2\u0087\u0089\3\2\2\2\u0088\u0086\3\2\2\2\u0089"+
		"\u008a\7\6\2\2\u008a\u008c\3\2\2\2\u008bo\3\2\2\2\u008bt\3\2\2\2\u008b"+
		"y\3\2\2\2\u008bz\3\2\2\2\u008b{\3\2\2\2\u008c\u0091\3\2\2\2\u008d\u008e"+
		"\f\b\2\2\u008e\u0090\5$\23\2\u008f\u008d\3\2\2\2\u0090\u0093\3\2\2\2\u0091"+
		"\u008f\3\2\2\2\u0091\u0092\3\2\2\2\u0092\t\3\2\2\2\u0093\u0091\3\2\2\2"+
		"\u0094\u0095\b\6\1\2\u0095\u00a1\5\62\32\2\u0096\u0097\7\5\2\2\u0097\u009c"+
		"\5\n\6\2\u0098\u0099\7\7\2\2\u0099\u009b\5\n\6\2\u009a\u0098\3\2\2\2\u009b"+
		"\u009e\3\2\2\2\u009c\u009a\3\2\2\2\u009c\u009d\3\2\2\2\u009d\u009f\3\2"+
		"\2\2\u009e\u009c\3\2\2\2\u009f\u00a0\7\6\2\2\u00a0\u00a2\3\2\2\2\u00a1"+
		"\u0096\3\2\2\2\u00a1\u00a2\3\2\2\2\u00a2\u00a5\3\2\2\2\u00a3\u00a5\7\t"+
		"\2\2\u00a4\u0094\3\2\2\2\u00a4\u00a3\3\2\2\2\u00a5\u00ab\3\2\2\2\u00a6"+
		"\u00a7\f\4\2\2\u00a7\u00a8\7\b\2\2\u00a8\u00aa\5\n\6\5\u00a9\u00a6\3\2"+
		"\2\2\u00aa\u00ad\3\2\2\2\u00ab\u00a9\3\2\2\2\u00ab\u00ac\3\2\2\2\u00ac"+
		"\13\3\2\2\2\u00ad\u00ab\3\2\2\2\u00ae\u00b3\5\16\b\2\u00af\u00b0\7\7\2"+
		"\2\u00b0\u00b2\5\16\b\2\u00b1\u00af\3\2\2\2\u00b2\u00b5\3\2\2\2\u00b3"+
		"\u00b1\3\2\2\2\u00b3\u00b4\3\2\2\2\u00b4\r\3\2\2\2\u00b5\u00b3\3\2\2\2"+
		"\u00b6\u00bd\7\n\2\2\u00b7\u00bd\5\62\32\2\u00b8\u00b9\7\5\2\2\u00b9\u00ba"+
		"\5\f\7\2\u00ba\u00bb\7\6\2\2\u00bb\u00bd\3\2\2\2\u00bc\u00b6\3\2\2\2\u00bc"+
		"\u00b7\3\2\2\2\u00bc\u00b8\3\2\2\2\u00bd\17\3\2\2\2\u00be\u00bf\7\13\2"+
		"\2\u00bf\u00c2\5\62\32\2\u00c0\u00c1\7%\2\2\u00c1\u00c3\5\n\6\2\u00c2"+
		"\u00c0\3\2\2\2\u00c2\u00c3\3\2\2\2\u00c3\u00c4\3\2\2\2\u00c4\u00c5\7$"+
		"\2\2\u00c5\u00c6\5\6\4\2\u00c6\21\3\2\2\2\u00c7\u00c8\7\f\2\2\u00c8\u00cc"+
		"\7\5\2\2\u00c9\u00cb\7\32\2\2\u00ca\u00c9\3\2\2\2\u00cb\u00ce\3\2\2\2"+
		"\u00cc\u00ca\3\2\2\2\u00cc\u00cd\3\2\2\2\u00cd\u00cf\3\2\2\2\u00ce\u00cc"+
		"\3\2\2\2\u00cf\u00d3\5\6\4\2\u00d0\u00d2\7\32\2\2\u00d1\u00d0\3\2\2\2"+
		"\u00d2\u00d5\3\2\2\2\u00d3\u00d1\3\2\2\2\u00d3\u00d4\3\2\2\2\u00d4\u00d6"+
		"\3\2\2\2\u00d5\u00d3\3\2\2\2\u00d6\u00da\7\6\2\2\u00d7\u00d9\7\32\2\2"+
		"\u00d8\u00d7\3\2\2\2\u00d9\u00dc\3\2\2\2\u00da\u00d8\3\2\2\2\u00da\u00db"+
		"\3\2\2\2\u00db\u00dd\3\2\2\2\u00dc\u00da\3\2\2\2\u00dd\u00e1\5\6\4\2\u00de"+
		"\u00e0\7\32\2\2\u00df\u00de\3\2\2\2\u00e0\u00e3\3\2\2\2\u00e1\u00df\3"+
		"\2\2\2\u00e1\u00e2\3\2\2\2\u00e2\u00ec\3\2\2\2\u00e3\u00e1\3\2\2\2\u00e4"+
		"\u00e8\7\r\2\2\u00e5\u00e7\7\32\2\2\u00e6\u00e5\3\2\2\2\u00e7\u00ea\3"+
		"\2\2\2\u00e8\u00e6\3\2\2\2\u00e8\u00e9\3\2\2\2\u00e9\u00eb\3\2\2\2\u00ea"+
		"\u00e8\3\2\2\2\u00eb\u00ed\5\6\4\2\u00ec\u00e4\3\2\2\2\u00ec\u00ed\3\2"+
		"\2\2\u00ed\23\3\2\2\2\u00ee\u00ef\7\16\2\2\u00ef\u00f3\7\5\2\2\u00f0\u00f2"+
		"\7\32\2\2\u00f1\u00f0\3\2\2\2\u00f2\u00f5\3\2\2\2\u00f3\u00f1\3\2\2\2"+
		"\u00f3\u00f4\3\2\2\2\u00f4\u00f6\3\2\2\2\u00f5\u00f3\3\2\2\2\u00f6\u00fa"+
		"\5\6\4\2\u00f7\u00f9\7\32\2\2\u00f8\u00f7\3\2\2\2\u00f9\u00fc\3\2\2\2"+
		"\u00fa\u00f8\3\2\2\2\u00fa\u00fb\3\2\2\2\u00fb\u00fd\3\2\2\2\u00fc\u00fa"+
		"\3\2\2\2\u00fd\u0101\7\6\2\2\u00fe\u0100\7\32\2\2\u00ff\u00fe\3\2\2\2"+
		"\u0100\u0103\3\2\2\2\u0101\u00ff\3\2\2\2\u0101\u0102\3\2\2\2\u0102\u0104"+
		"\3\2\2\2\u0103\u0101\3\2\2\2\u0104\u0105\5\6\4\2\u0105\25\3\2\2\2\u0106"+
		"\u0107\5\62\32\2\u0107\27\3\2\2\2\u0108\u0109\7\5\2\2\u0109\u010e\5\26"+
		"\f\2\u010a\u010b\7\7\2\2\u010b\u010d\5\26\f\2\u010c\u010a\3\2\2\2\u010d"+
		"\u0110\3\2\2\2\u010e\u010c\3\2\2\2\u010e\u010f\3\2\2\2\u010f\u0111\3\2"+
		"\2\2\u0110\u010e\3\2\2\2\u0111\u0112\7\6\2\2\u0112\31\3\2\2\2\u0113\u0115"+
		"\5\n\6\2\u0114\u0116\7\17\2\2\u0115\u0114\3\2\2\2\u0115\u0116\3\2\2\2"+
		"\u0116\33\3\2\2\2\u0117\u0118\5\62\32\2\u0118\u0119\7%\2\2\u0119\u011c"+
		"\5\32\16\2\u011a\u011b\7$\2\2\u011b\u011d\5\6\4\2\u011c\u011a\3\2\2\2"+
		"\u011c\u011d\3\2\2\2\u011d\35\3\2\2\2\u011e\u0127\7\5\2\2\u011f\u0124"+
		"\5\34\17\2\u0120\u0121\7\7\2\2\u0121\u0123\5\34\17\2\u0122\u0120\3\2\2"+
		"\2\u0123\u0126\3\2\2\2\u0124\u0122\3\2\2\2\u0124\u0125\3\2\2\2\u0125\u0128"+
		"\3\2\2\2\u0126\u0124\3\2\2\2\u0127\u011f\3\2\2\2\u0127\u0128\3\2\2\2\u0128"+
		"\u0129\3\2\2\2\u0129\u012a\7\6\2\2\u012a\37\3\2\2\2\u012b\u012c\7\20\2"+
		"\2\u012c\u012d\5\62\32\2\u012d\u0130\5\36\20\2\u012e\u012f\7\b\2\2\u012f"+
		"\u0131\5\n\6\2\u0130\u012e\3\2\2\2\u0130\u0131\3\2\2\2\u0131\u0134\3\2"+
		"\2\2\u0132\u0133\7\21\2\2\u0133\u0135\5\30\r\2\u0134\u0132\3\2\2\2\u0134"+
		"\u0135\3\2\2\2\u0135\u0136\3\2\2\2\u0136\u0137\7\22\2\2\u0137\u0138\5"+
		"\4\3\2\u0138\u0139\7\23\2\2\u0139!\3\2\2\2\u013a\u013b\5\62\32\2\u013b"+
		"\u013c\7%\2\2\u013c\u013e\3\2\2\2\u013d\u013a\3\2\2\2\u013d\u013e\3\2"+
		"\2\2\u013e\u013f\3\2\2\2\u013f\u0140\5\6\4\2\u0140#\3\2\2\2\u0141\u014e"+
		"\7\t\2\2\u0142\u0143\7\5\2\2\u0143\u0148\5\"\22\2\u0144\u0145\7\7\2\2"+
		"\u0145\u0147\5\"\22\2\u0146\u0144\3\2\2\2\u0147\u014a\3\2\2\2\u0148\u0146"+
		"\3\2\2\2\u0148\u0149\3\2\2\2\u0149\u014b\3\2\2\2\u014a\u0148\3\2\2\2\u014b"+
		"\u014c\7\6\2\2\u014c\u014e\3\2\2\2\u014d\u0141\3\2\2\2\u014d\u0142\3\2"+
		"\2\2\u014e%\3\2\2\2\u014f\u0153\7\22\2\2\u0150\u0151\5\f\7\2\u0151\u0152"+
		"\7\24\2\2\u0152\u0154\3\2\2\2\u0153\u0150\3\2\2\2\u0153\u0154\3\2\2\2"+
		"\u0154\u0155\3\2\2\2\u0155\u0156\5\4\3\2\u0156\u0157\7\23\2\2\u0157\'"+
		"\3\2\2\2\u0158\u015c\7\25\2\2\u0159\u015b\7\32\2\2\u015a\u0159\3\2\2\2"+
		"\u015b\u015e\3\2\2\2\u015c\u015a\3\2\2\2\u015c\u015d\3\2\2\2\u015d\u0160"+
		"\3\2\2\2\u015e\u015c\3\2\2\2\u015f\u0161\5\6\4\2\u0160\u015f\3\2\2\2\u0160"+
		"\u0161\3\2\2\2\u0161\u0172\3\2\2\2\u0162\u0164\7\32\2\2\u0163\u0162\3"+
		"\2\2\2\u0164\u0167\3\2\2\2\u0165\u0163\3\2\2\2\u0165\u0166\3\2\2\2\u0166"+
		"\u0168\3\2\2\2\u0167\u0165\3\2\2\2\u0168\u016c\7\7\2\2\u0169\u016b\7\32"+
		"\2\2\u016a\u0169\3\2\2\2\u016b\u016e\3\2\2\2\u016c\u016a\3\2\2\2\u016c"+
		"\u016d\3\2\2\2\u016d\u016f\3\2\2\2\u016e\u016c\3\2\2\2\u016f\u0171\5\6"+
		"\4\2\u0170\u0165\3\2\2\2\u0171\u0174\3\2\2\2\u0172\u0170\3\2\2\2\u0172"+
		"\u0173\3\2\2\2\u0173\u0178\3\2\2\2\u0174\u0172\3\2\2\2\u0175\u0177\7\32"+
		"\2\2\u0176\u0175\3\2\2\2\u0177\u017a\3\2\2\2\u0178\u0176\3\2\2\2\u0178"+
		"\u0179\3\2\2\2\u0179\u017b\3\2\2\2\u017a\u0178\3\2\2\2\u017b\u017c\7\26"+
		"\2\2\u017c)\3\2\2\2\u017d\u0182\5,\27\2\u017e\u0182\5\60\31\2\u017f\u0182"+
		"\5.\30\2\u0180\u0182\5(\25\2\u0181\u017d\3\2\2\2\u0181\u017e\3\2\2\2\u0181"+
		"\u017f\3\2\2\2\u0181\u0180\3\2\2\2\u0182+\3\2\2\2\u0183\u0184\7\34\2\2"+
		"\u0184-\3\2\2\2\u0185\u0186\7\35\2\2\u0186/\3\2\2\2\u0187\u0188\7\33\2"+
		"\2\u0188\61\3\2\2\2\u0189\u018a\7\27\2\2\u018a\u018b\5\62\32\2\u018b\u018c"+
		"\7\27\2\2\u018c\u0195\3\2\2\2\u018d\u0195\7\37\2\2\u018e\u0195\7(\2\2"+
		"\u018f\u0195\7!\2\2\u0190\u0195\7\"\2\2\u0191\u0195\7$\2\2\u0192\u0195"+
		"\7 \2\2\u0193\u0195\7#\2\2\u0194\u0189\3\2\2\2\u0194\u018d\3\2\2\2\u0194"+
		"\u018e\3\2\2\2\u0194\u018f\3\2\2\2\u0194\u0190\3\2\2\2\u0194\u0191\3\2"+
		"\2\2\u0194\u0192\3\2\2\2\u0194\u0193\3\2\2\2\u0195\63\3\2\2\2\66:@EKQ"+
		"SW\\akmqw\177\u0086\u008b\u0091\u009c\u00a1\u00a4\u00ab\u00b3\u00bc\u00c2"+
		"\u00cc\u00d3\u00da\u00e1\u00e8\u00ec\u00f3\u00fa\u0101\u010e\u0115\u011c"+
		"\u0124\u0127\u0130\u0134\u013d\u0148\u014d\u0153\u015c\u0160\u0165\u016c"+
		"\u0172\u0178\u0181\u0194";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}