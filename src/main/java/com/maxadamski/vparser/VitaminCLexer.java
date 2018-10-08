// Generated from /home/max/Documents/vitamin/res/VitaminC.g4 by ANTLR 4.7
package com.maxadamski.vparser;
import org.antlr.v4.runtime.Lexer;
import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.atn.*;
import org.antlr.v4.runtime.dfa.DFA;
import org.antlr.v4.runtime.misc.*;

@SuppressWarnings({"all", "warnings", "unchecked", "unused", "cast"})
public class VitaminCLexer extends Lexer {
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
	public static String[] channelNames = {
		"DEFAULT_TOKEN_CHANNEL", "HIDDEN"
	};

	public static String[] modeNames = {
		"DEFAULT_MODE"
	};

	public static final String[] ruleNames = {
		"T__0", "T__1", "T__2", "T__3", "T__4", "T__5", "T__6", "T__7", "T__8", 
		"T__9", "T__10", "T__11", "T__12", "T__13", "T__14", "T__15", "T__16", 
		"T__17", "T__18", "T__19", "T__20", "ShebangLine", "Whitespace", "Newline", 
		"WS", "NL", "NumberSign", "HexDigits", "DecDigits", "OctDigits", "BinDigits", 
		"DecFraction", "HexFraction", "DecExponent", "HexExponent", "FltReal", 
		"IntReal", "Flt", "Int", "EscapedString", "Str", "LineComment", "BlockComment", 
		"Comment", "NameHead", "NameTail", "Name", "MINUS", "LANGLE", "RANGLE", 
		"QUOTE", "EQUAL", "COLON", "SEMI", "PIPE", "SymbolUsed", "SymbolHead", 
		"SymbolTail", "Symbol"
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


	public VitaminCLexer(CharStream input) {
		super(input);
		_interp = new LexerATNSimulator(this,_ATN,_decisionToDFA,_sharedContextCache);
	}

	@Override
	public String getGrammarFileName() { return "VitaminC.g4"; }

	@Override
	public String[] getRuleNames() { return ruleNames; }

	@Override
	public String getSerializedATN() { return _serializedATN; }

	@Override
	public String[] getChannelNames() { return channelNames; }

	@Override
	public String[] getModeNames() { return modeNames; }

	@Override
	public ATN getATN() { return _ATN; }

	public static final String _serializedATN =
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\2(\u0162\b\1\4\2\t"+
		"\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4\13"+
		"\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22\t\22"+
		"\4\23\t\23\4\24\t\24\4\25\t\25\4\26\t\26\4\27\t\27\4\30\t\30\4\31\t\31"+
		"\4\32\t\32\4\33\t\33\4\34\t\34\4\35\t\35\4\36\t\36\4\37\t\37\4 \t \4!"+
		"\t!\4\"\t\"\4#\t#\4$\t$\4%\t%\4&\t&\4\'\t\'\4(\t(\4)\t)\4*\t*\4+\t+\4"+
		",\t,\4-\t-\4.\t.\4/\t/\4\60\t\60\4\61\t\61\4\62\t\62\4\63\t\63\4\64\t"+
		"\64\4\65\t\65\4\66\t\66\4\67\t\67\48\t8\49\t9\4:\t:\4;\t;\4<\t<\3\2\3"+
		"\2\3\3\3\3\3\4\3\4\3\5\3\5\3\6\3\6\3\7\3\7\3\7\3\b\3\b\3\b\3\t\3\t\3\n"+
		"\3\n\3\n\3\n\3\13\3\13\3\13\3\f\3\f\3\f\3\f\3\f\3\r\3\r\3\r\3\r\3\r\3"+
		"\r\3\16\3\16\3\16\3\16\3\17\3\17\3\17\3\17\3\20\3\20\3\20\3\20\3\20\3"+
		"\21\3\21\3\22\3\22\3\23\3\23\3\23\3\24\3\24\3\25\3\25\3\26\3\26\3\27\3"+
		"\27\3\27\3\27\7\27\u00bc\n\27\f\27\16\27\u00bf\13\27\3\27\3\27\3\30\6"+
		"\30\u00c4\n\30\r\30\16\30\u00c5\3\31\5\31\u00c9\n\31\3\31\3\31\5\31\u00cd"+
		"\n\31\3\32\3\32\3\32\3\32\3\33\3\33\3\34\3\34\3\35\3\35\7\35\u00d9\n\35"+
		"\f\35\16\35\u00dc\13\35\3\36\3\36\7\36\u00e0\n\36\f\36\16\36\u00e3\13"+
		"\36\3\37\3\37\7\37\u00e7\n\37\f\37\16\37\u00ea\13\37\3 \3 \7 \u00ee\n"+
		" \f \16 \u00f1\13 \3!\3!\3!\3\"\3\"\3\"\3#\3#\5#\u00fb\n#\3#\3#\3$\3$"+
		"\5$\u0101\n$\3$\3$\3%\3%\3%\3&\3&\3\'\3\'\3(\3(\3)\3)\3)\3)\7)\u0112\n"+
		")\f)\16)\u0115\13)\3)\3)\3*\3*\3+\3+\3+\3+\7+\u011f\n+\f+\16+\u0122\13"+
		"+\3,\3,\3,\3,\3,\7,\u0129\n,\f,\16,\u012c\13,\3,\3,\3,\3-\3-\5-\u0133"+
		"\n-\3-\3-\3.\3.\3/\3/\5/\u013b\n/\3\60\3\60\7\60\u013f\n\60\f\60\16\60"+
		"\u0142\13\60\3\61\3\61\3\62\3\62\3\63\3\63\3\64\3\64\3\65\3\65\3\66\3"+
		"\66\3\67\3\67\38\38\39\39\3:\3:\5:\u0158\n:\3;\3;\3<\3<\7<\u015e\n<\f"+
		"<\16<\u0161\13<\3\u012a\2=\3\3\5\4\7\5\t\6\13\7\r\b\17\t\21\n\23\13\25"+
		"\f\27\r\31\16\33\17\35\20\37\21!\22#\23%\24\'\25)\26+\27-\30/\2\61\2\63"+
		"\31\65\32\67\29\2;\2=\2?\2A\2C\2E\2G\2I\2K\2M\33O\34Q\2S\35U\2W\2Y\36"+
		"[\2]\2_\37a c!e\"g#i$k%m&o\'q\2s\2u\2w(\3\2\23\4\2\f\f\17\17\4\2\13\13"+
		"\"\"\4\2--//\5\2\62;CHch\6\2\62;CHaach\3\2\62;\4\2\62;aa\3\2\629\4\2\62"+
		"9aa\3\2\62\63\4\2\62\63aa\4\2GGgg\4\2RRrr\5\2\f\f\17\17$$\5\2C\\aac|\6"+
		"\2//<<>@~~\n\2##&(,-\61\61AA``~~\u0080\u0080\2\u0160\2\3\3\2\2\2\2\5\3"+
		"\2\2\2\2\7\3\2\2\2\2\t\3\2\2\2\2\13\3\2\2\2\2\r\3\2\2\2\2\17\3\2\2\2\2"+
		"\21\3\2\2\2\2\23\3\2\2\2\2\25\3\2\2\2\2\27\3\2\2\2\2\31\3\2\2\2\2\33\3"+
		"\2\2\2\2\35\3\2\2\2\2\37\3\2\2\2\2!\3\2\2\2\2#\3\2\2\2\2%\3\2\2\2\2\'"+
		"\3\2\2\2\2)\3\2\2\2\2+\3\2\2\2\2-\3\2\2\2\2\63\3\2\2\2\2\65\3\2\2\2\2"+
		"M\3\2\2\2\2O\3\2\2\2\2S\3\2\2\2\2Y\3\2\2\2\2_\3\2\2\2\2a\3\2\2\2\2c\3"+
		"\2\2\2\2e\3\2\2\2\2g\3\2\2\2\2i\3\2\2\2\2k\3\2\2\2\2m\3\2\2\2\2o\3\2\2"+
		"\2\2w\3\2\2\2\3y\3\2\2\2\5{\3\2\2\2\7}\3\2\2\2\t\177\3\2\2\2\13\u0081"+
		"\3\2\2\2\r\u0083\3\2\2\2\17\u0086\3\2\2\2\21\u0089\3\2\2\2\23\u008b\3"+
		"\2\2\2\25\u008f\3\2\2\2\27\u0092\3\2\2\2\31\u0097\3\2\2\2\33\u009d\3\2"+
		"\2\2\35\u00a1\3\2\2\2\37\u00a5\3\2\2\2!\u00aa\3\2\2\2#\u00ac\3\2\2\2%"+
		"\u00ae\3\2\2\2\'\u00b1\3\2\2\2)\u00b3\3\2\2\2+\u00b5\3\2\2\2-\u00b7\3"+
		"\2\2\2/\u00c3\3\2\2\2\61\u00c8\3\2\2\2\63\u00ce\3\2\2\2\65\u00d2\3\2\2"+
		"\2\67\u00d4\3\2\2\29\u00d6\3\2\2\2;\u00dd\3\2\2\2=\u00e4\3\2\2\2?\u00eb"+
		"\3\2\2\2A\u00f2\3\2\2\2C\u00f5\3\2\2\2E\u00f8\3\2\2\2G\u00fe\3\2\2\2I"+
		"\u0104\3\2\2\2K\u0107\3\2\2\2M\u0109\3\2\2\2O\u010b\3\2\2\2Q\u010d\3\2"+
		"\2\2S\u0118\3\2\2\2U\u011a\3\2\2\2W\u0123\3\2\2\2Y\u0132\3\2\2\2[\u0136"+
		"\3\2\2\2]\u013a\3\2\2\2_\u013c\3\2\2\2a\u0143\3\2\2\2c\u0145\3\2\2\2e"+
		"\u0147\3\2\2\2g\u0149\3\2\2\2i\u014b\3\2\2\2k\u014d\3\2\2\2m\u014f\3\2"+
		"\2\2o\u0151\3\2\2\2q\u0153\3\2\2\2s\u0157\3\2\2\2u\u0159\3\2\2\2w\u015b"+
		"\3\2\2\2yz\7%\2\2z\4\3\2\2\2{|\7B\2\2|\6\3\2\2\2}~\7*\2\2~\b\3\2\2\2\177"+
		"\u0080\7+\2\2\u0080\n\3\2\2\2\u0081\u0082\7.\2\2\u0082\f\3\2\2\2\u0083"+
		"\u0084\7/\2\2\u0084\u0085\7@\2\2\u0085\16\3\2\2\2\u0086\u0087\7*\2\2\u0087"+
		"\u0088\7+\2\2\u0088\20\3\2\2\2\u0089\u008a\7a\2\2\u008a\22\3\2\2\2\u008b"+
		"\u008c\7n\2\2\u008c\u008d\7g\2\2\u008d\u008e\7v\2\2\u008e\24\3\2\2\2\u008f"+
		"\u0090\7k\2\2\u0090\u0091\7h\2\2\u0091\26\3\2\2\2\u0092\u0093\7g\2\2\u0093"+
		"\u0094\7n\2\2\u0094\u0095\7u\2\2\u0095\u0096\7g\2\2\u0096\30\3\2\2\2\u0097"+
		"\u0098\7y\2\2\u0098\u0099\7j\2\2\u0099\u009a\7k\2\2\u009a\u009b\7n\2\2"+
		"\u009b\u009c\7g\2\2\u009c\32\3\2\2\2\u009d\u009e\7\60\2\2\u009e\u009f"+
		"\7\60\2\2\u009f\u00a0\7\60\2\2\u00a0\34\3\2\2\2\u00a1\u00a2\7h\2\2\u00a2"+
		"\u00a3\7w\2\2\u00a3\u00a4\7p\2\2\u00a4\36\3\2\2\2\u00a5\u00a6\7y\2\2\u00a6"+
		"\u00a7\7k\2\2\u00a7\u00a8\7v\2\2\u00a8\u00a9\7j\2\2\u00a9 \3\2\2\2\u00aa"+
		"\u00ab\7}\2\2\u00ab\"\3\2\2\2\u00ac\u00ad\7\177\2\2\u00ad$\3\2\2\2\u00ae"+
		"\u00af\7k\2\2\u00af\u00b0\7p\2\2\u00b0&\3\2\2\2\u00b1\u00b2\7]\2\2\u00b2"+
		"(\3\2\2\2\u00b3\u00b4\7_\2\2\u00b4*\3\2\2\2\u00b5\u00b6\7b\2\2\u00b6,"+
		"\3\2\2\2\u00b7\u00b8\7%\2\2\u00b8\u00b9\7#\2\2\u00b9\u00bd\3\2\2\2\u00ba"+
		"\u00bc\n\2\2\2\u00bb\u00ba\3\2\2\2\u00bc\u00bf\3\2\2\2\u00bd\u00bb\3\2"+
		"\2\2\u00bd\u00be\3\2\2\2\u00be\u00c0\3\2\2\2\u00bf\u00bd\3\2\2\2\u00c0"+
		"\u00c1\b\27\2\2\u00c1.\3\2\2\2\u00c2\u00c4\t\3\2\2\u00c3\u00c2\3\2\2\2"+
		"\u00c4\u00c5\3\2\2\2\u00c5\u00c3\3\2\2\2\u00c5\u00c6\3\2\2\2\u00c6\60"+
		"\3\2\2\2\u00c7\u00c9\7\17\2\2\u00c8\u00c7\3\2\2\2\u00c8\u00c9\3\2\2\2"+
		"\u00c9\u00ca\3\2\2\2\u00ca\u00cc\7\f\2\2\u00cb\u00cd\7\17\2\2\u00cc\u00cb"+
		"\3\2\2\2\u00cc\u00cd\3\2\2\2\u00cd\62\3\2\2\2\u00ce\u00cf\5/\30\2\u00cf"+
		"\u00d0\3\2\2\2\u00d0\u00d1\b\32\2\2\u00d1\64\3\2\2\2\u00d2\u00d3\5\61"+
		"\31\2\u00d3\66\3\2\2\2\u00d4\u00d5\t\4\2\2\u00d58\3\2\2\2\u00d6\u00da"+
		"\t\5\2\2\u00d7\u00d9\t\6\2\2\u00d8\u00d7\3\2\2\2\u00d9\u00dc\3\2\2\2\u00da"+
		"\u00d8\3\2\2\2\u00da\u00db\3\2\2\2\u00db:\3\2\2\2\u00dc\u00da\3\2\2\2"+
		"\u00dd\u00e1\t\7\2\2\u00de\u00e0\t\b\2\2\u00df\u00de\3\2\2\2\u00e0\u00e3"+
		"\3\2\2\2\u00e1\u00df\3\2\2\2\u00e1\u00e2\3\2\2\2\u00e2<\3\2\2\2\u00e3"+
		"\u00e1\3\2\2\2\u00e4\u00e8\t\t\2\2\u00e5\u00e7\t\n\2\2\u00e6\u00e5\3\2"+
		"\2\2\u00e7\u00ea\3\2\2\2\u00e8\u00e6\3\2\2\2\u00e8\u00e9\3\2\2\2\u00e9"+
		">\3\2\2\2\u00ea\u00e8\3\2\2\2\u00eb\u00ef\t\13\2\2\u00ec\u00ee\t\f\2\2"+
		"\u00ed\u00ec\3\2\2\2\u00ee\u00f1\3\2\2\2\u00ef\u00ed\3\2\2\2\u00ef\u00f0"+
		"\3\2\2\2\u00f0@\3\2\2\2\u00f1\u00ef\3\2\2\2\u00f2\u00f3\7\60\2\2\u00f3"+
		"\u00f4\5;\36\2\u00f4B\3\2\2\2\u00f5\u00f6\7\60\2\2\u00f6\u00f7\5C\"\2"+
		"\u00f7D\3\2\2\2\u00f8\u00fa\t\r\2\2\u00f9\u00fb\5\67\34\2\u00fa\u00f9"+
		"\3\2\2\2\u00fa\u00fb\3\2\2\2\u00fb\u00fc\3\2\2\2\u00fc\u00fd\5;\36\2\u00fd"+
		"F\3\2\2\2\u00fe\u0100\t\16\2\2\u00ff\u0101\5\67\34\2\u0100\u00ff\3\2\2"+
		"\2\u0100\u0101\3\2\2\2\u0101\u0102\3\2\2\2\u0102\u0103\59\35\2\u0103H"+
		"\3\2\2\2\u0104\u0105\5;\36\2\u0105\u0106\5A!\2\u0106J\3\2\2\2\u0107\u0108"+
		"\5;\36\2\u0108L\3\2\2\2\u0109\u010a\5I%\2\u010aN\3\2\2\2\u010b\u010c\5"+
		"K&\2\u010cP\3\2\2\2\u010d\u0113\7$\2\2\u010e\u010f\7^\2\2\u010f\u0112"+
		"\13\2\2\2\u0110\u0112\n\17\2\2\u0111\u010e\3\2\2\2\u0111\u0110\3\2\2\2"+
		"\u0112\u0115\3\2\2\2\u0113\u0111\3\2\2\2\u0113\u0114\3\2\2\2\u0114\u0116"+
		"\3\2\2\2\u0115\u0113\3\2\2\2\u0116\u0117\7$\2\2\u0117R\3\2\2\2\u0118\u0119"+
		"\5Q)\2\u0119T\3\2\2\2\u011a\u011b\7\61\2\2\u011b\u011c\7\61\2\2\u011c"+
		"\u0120\3\2\2\2\u011d\u011f\n\2\2\2\u011e\u011d\3\2\2\2\u011f\u0122\3\2"+
		"\2\2\u0120\u011e\3\2\2\2\u0120\u0121\3\2\2\2\u0121V\3\2\2\2\u0122\u0120"+
		"\3\2\2\2\u0123\u0124\7\61\2\2\u0124\u0125\7,\2\2\u0125\u012a\3\2\2\2\u0126"+
		"\u0129\5W,\2\u0127\u0129\13\2\2\2\u0128\u0126\3\2\2\2\u0128\u0127\3\2"+
		"\2\2\u0129\u012c\3\2\2\2\u012a\u012b\3\2\2\2\u012a\u0128\3\2\2\2\u012b"+
		"\u012d\3\2\2\2\u012c\u012a\3\2\2\2\u012d\u012e\7,\2\2\u012e\u012f\7\61"+
		"\2\2\u012fX\3\2\2\2\u0130\u0133\5U+\2\u0131\u0133\5W,\2\u0132\u0130\3"+
		"\2\2\2\u0132\u0131\3\2\2\2\u0133\u0134\3\2\2\2\u0134\u0135\b-\2\2\u0135"+
		"Z\3\2\2\2\u0136\u0137\t\20\2\2\u0137\\\3\2\2\2\u0138\u013b\5[.\2\u0139"+
		"\u013b\t\7\2\2\u013a\u0138\3\2\2\2\u013a\u0139\3\2\2\2\u013b^\3\2\2\2"+
		"\u013c\u0140\5[.\2\u013d\u013f\5]/\2\u013e\u013d\3\2\2\2\u013f\u0142\3"+
		"\2\2\2\u0140\u013e\3\2\2\2\u0140\u0141\3\2\2\2\u0141`\3\2\2\2\u0142\u0140"+
		"\3\2\2\2\u0143\u0144\7/\2\2\u0144b\3\2\2\2\u0145\u0146\7>\2\2\u0146d\3"+
		"\2\2\2\u0147\u0148\7@\2\2\u0148f\3\2\2\2\u0149\u014a\7)\2\2\u014ah\3\2"+
		"\2\2\u014b\u014c\7?\2\2\u014cj\3\2\2\2\u014d\u014e\7<\2\2\u014el\3\2\2"+
		"\2\u014f\u0150\7=\2\2\u0150n\3\2\2\2\u0151\u0152\7~\2\2\u0152p\3\2\2\2"+
		"\u0153\u0154\t\21\2\2\u0154r\3\2\2\2\u0155\u0158\t\22\2\2\u0156\u0158"+
		"\5q9\2\u0157\u0155\3\2\2\2\u0157\u0156\3\2\2\2\u0158t\3\2\2\2\u0159\u015a"+
		"\5s:\2\u015av\3\2\2\2\u015b\u015f\5s:\2\u015c\u015e\5u;\2\u015d\u015c"+
		"\3\2\2\2\u015e\u0161\3\2\2\2\u015f\u015d\3\2\2\2\u015f\u0160\3\2\2\2\u0160"+
		"x\3\2\2\2\u0161\u015f\3\2\2\2\27\2\u00bd\u00c5\u00c8\u00cc\u00da\u00e1"+
		"\u00e8\u00ef\u00fa\u0100\u0111\u0113\u0120\u0128\u012a\u0132\u013a\u0140"+
		"\u0157\u015f\3\2\3\2";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}