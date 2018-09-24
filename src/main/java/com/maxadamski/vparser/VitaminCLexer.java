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
		ShebangLine=10, WS=11, NL=12, Real=13, Int=14, String=15, Comment=16, 
		Name=17, LANGLE=18, RANGLE=19, QUOTE=20, EQUAL=21, COLON=22, SEMI=23, 
		PIPE=24, Symbol=25;
	public static String[] channelNames = {
		"DEFAULT_TOKEN_CHANNEL", "HIDDEN"
	};

	public static String[] modeNames = {
		"DEFAULT_MODE"
	};

	public static final String[] ruleNames = {
		"T__0", "T__1", "T__2", "T__3", "T__4", "T__5", "T__6", "T__7", "T__8", 
		"ShebangLine", "Whitespace", "Newline", "WS", "NL", "NumberSign", "HexDigits", 
		"DecDigits", "OctDigits", "BinDigits", "DecFraction", "HexFraction", "DecExponent", 
		"HexExponent", "FloatReal", "IntReal", "Real", "Int", "EscapedString", 
		"String", "LineComment", "BlockComment", "Comment", "NameHead", "NameTail", 
		"Name", "LANGLE", "RANGLE", "QUOTE", "EQUAL", "COLON", "SEMI", "PIPE", 
		"SymbolHead", "SymbolTail", "Symbol"
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
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\2\33\u013b\b\1\4\2"+
		"\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4"+
		"\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22"+
		"\t\22\4\23\t\23\4\24\t\24\4\25\t\25\4\26\t\26\4\27\t\27\4\30\t\30\4\31"+
		"\t\31\4\32\t\32\4\33\t\33\4\34\t\34\4\35\t\35\4\36\t\36\4\37\t\37\4 \t"+
		" \4!\t!\4\"\t\"\4#\t#\4$\t$\4%\t%\4&\t&\4\'\t\'\4(\t(\4)\t)\4*\t*\4+\t"+
		"+\4,\t,\4-\t-\4.\t.\3\2\3\2\3\3\3\3\3\4\3\4\3\4\3\5\3\5\3\5\3\5\3\5\3"+
		"\6\3\6\3\7\3\7\3\b\3\b\3\t\3\t\3\n\3\n\3\13\3\13\3\13\3\13\7\13x\n\13"+
		"\f\13\16\13{\13\13\3\13\3\13\3\f\6\f\u0080\n\f\r\f\16\f\u0081\3\r\5\r"+
		"\u0085\n\r\3\r\3\r\5\r\u0089\n\r\3\16\3\16\3\16\3\16\3\17\3\17\3\20\3"+
		"\20\3\21\3\21\7\21\u0095\n\21\f\21\16\21\u0098\13\21\3\22\3\22\7\22\u009c"+
		"\n\22\f\22\16\22\u009f\13\22\3\23\3\23\7\23\u00a3\n\23\f\23\16\23\u00a6"+
		"\13\23\3\24\3\24\7\24\u00aa\n\24\f\24\16\24\u00ad\13\24\3\25\3\25\3\25"+
		"\3\26\3\26\3\26\3\27\3\27\5\27\u00b7\n\27\3\27\3\27\3\30\3\30\5\30\u00bd"+
		"\n\30\3\30\3\30\3\31\3\31\3\31\5\31\u00c4\n\31\3\31\5\31\u00c7\n\31\3"+
		"\31\3\31\3\31\3\31\3\31\3\31\5\31\u00cf\n\31\3\31\5\31\u00d2\n\31\5\31"+
		"\u00d4\n\31\3\32\3\32\3\32\3\32\3\32\3\32\3\32\3\32\3\32\3\32\3\32\3\32"+
		"\3\32\5\32\u00e3\n\32\3\33\3\33\5\33\u00e7\n\33\3\34\3\34\5\34\u00eb\n"+
		"\34\3\35\3\35\3\35\3\35\7\35\u00f1\n\35\f\35\16\35\u00f4\13\35\3\35\3"+
		"\35\3\36\3\36\3\37\3\37\3\37\3\37\7\37\u00fe\n\37\f\37\16\37\u0101\13"+
		"\37\3 \3 \3 \3 \3 \7 \u0108\n \f \16 \u010b\13 \3 \3 \3 \3!\3!\5!\u0112"+
		"\n!\3!\3!\3\"\3\"\3#\3#\5#\u011a\n#\3$\3$\7$\u011e\n$\f$\16$\u0121\13"+
		"$\3%\3%\3&\3&\3\'\3\'\3(\3(\3)\3)\3*\3*\3+\3+\3,\3,\3-\3-\3.\3.\7.\u0137"+
		"\n.\f.\16.\u013a\13.\3\u0109\2/\3\3\5\4\7\5\t\6\13\7\r\b\17\t\21\n\23"+
		"\13\25\f\27\2\31\2\33\r\35\16\37\2!\2#\2%\2\'\2)\2+\2-\2/\2\61\2\63\2"+
		"\65\17\67\209\2;\21=\2?\2A\22C\2E\2G\23I\24K\25M\26O\27Q\30S\31U\32W\2"+
		"Y\2[\33\3\2\23\4\2\f\f\17\17\4\2\13\13\"\"\4\2--//\5\2\62;CHch\6\2\62"+
		";CHaach\3\2\62;\4\2\62;aa\3\2\629\4\2\629aa\3\2\62\63\4\2\62\63aa\4\2"+
		"GGgg\4\2RRrr\3\2kk\5\2\f\f\17\17$$\5\2C\\aac|\f\2##&(,-//\61\61<<>A``"+
		"~~\u0080\u0080\2\u0143\2\3\3\2\2\2\2\5\3\2\2\2\2\7\3\2\2\2\2\t\3\2\2\2"+
		"\2\13\3\2\2\2\2\r\3\2\2\2\2\17\3\2\2\2\2\21\3\2\2\2\2\23\3\2\2\2\2\25"+
		"\3\2\2\2\2\33\3\2\2\2\2\35\3\2\2\2\2\65\3\2\2\2\2\67\3\2\2\2\2;\3\2\2"+
		"\2\2A\3\2\2\2\2G\3\2\2\2\2I\3\2\2\2\2K\3\2\2\2\2M\3\2\2\2\2O\3\2\2\2\2"+
		"Q\3\2\2\2\2S\3\2\2\2\2U\3\2\2\2\2[\3\2\2\2\3]\3\2\2\2\5_\3\2\2\2\7a\3"+
		"\2\2\2\td\3\2\2\2\13i\3\2\2\2\rk\3\2\2\2\17m\3\2\2\2\21o\3\2\2\2\23q\3"+
		"\2\2\2\25s\3\2\2\2\27\177\3\2\2\2\31\u0084\3\2\2\2\33\u008a\3\2\2\2\35"+
		"\u008e\3\2\2\2\37\u0090\3\2\2\2!\u0092\3\2\2\2#\u0099\3\2\2\2%\u00a0\3"+
		"\2\2\2\'\u00a7\3\2\2\2)\u00ae\3\2\2\2+\u00b1\3\2\2\2-\u00b4\3\2\2\2/\u00ba"+
		"\3\2\2\2\61\u00d3\3\2\2\2\63\u00e2\3\2\2\2\65\u00e4\3\2\2\2\67\u00e8\3"+
		"\2\2\29\u00ec\3\2\2\2;\u00f7\3\2\2\2=\u00f9\3\2\2\2?\u0102\3\2\2\2A\u0111"+
		"\3\2\2\2C\u0115\3\2\2\2E\u0119\3\2\2\2G\u011b\3\2\2\2I\u0122\3\2\2\2K"+
		"\u0124\3\2\2\2M\u0126\3\2\2\2O\u0128\3\2\2\2Q\u012a\3\2\2\2S\u012c\3\2"+
		"\2\2U\u012e\3\2\2\2W\u0130\3\2\2\2Y\u0132\3\2\2\2[\u0134\3\2\2\2]^\7*"+
		"\2\2^\4\3\2\2\2_`\7+\2\2`\6\3\2\2\2ab\7k\2\2bc\7h\2\2c\b\3\2\2\2de\7g"+
		"\2\2ef\7n\2\2fg\7u\2\2gh\7g\2\2h\n\3\2\2\2ij\7}\2\2j\f\3\2\2\2kl\7.\2"+
		"\2l\16\3\2\2\2mn\7\177\2\2n\20\3\2\2\2op\7%\2\2p\22\3\2\2\2qr\7b\2\2r"+
		"\24\3\2\2\2st\7%\2\2tu\7#\2\2uy\3\2\2\2vx\n\2\2\2wv\3\2\2\2x{\3\2\2\2"+
		"yw\3\2\2\2yz\3\2\2\2z|\3\2\2\2{y\3\2\2\2|}\b\13\2\2}\26\3\2\2\2~\u0080"+
		"\t\3\2\2\177~\3\2\2\2\u0080\u0081\3\2\2\2\u0081\177\3\2\2\2\u0081\u0082"+
		"\3\2\2\2\u0082\30\3\2\2\2\u0083\u0085\7\17\2\2\u0084\u0083\3\2\2\2\u0084"+
		"\u0085\3\2\2\2\u0085\u0086\3\2\2\2\u0086\u0088\7\f\2\2\u0087\u0089\7\17"+
		"\2\2\u0088\u0087\3\2\2\2\u0088\u0089\3\2\2\2\u0089\32\3\2\2\2\u008a\u008b"+
		"\5\27\f\2\u008b\u008c\3\2\2\2\u008c\u008d\b\16\3\2\u008d\34\3\2\2\2\u008e"+
		"\u008f\5\31\r\2\u008f\36\3\2\2\2\u0090\u0091\t\4\2\2\u0091 \3\2\2\2\u0092"+
		"\u0096\t\5\2\2\u0093\u0095\t\6\2\2\u0094\u0093\3\2\2\2\u0095\u0098\3\2"+
		"\2\2\u0096\u0094\3\2\2\2\u0096\u0097\3\2\2\2\u0097\"\3\2\2\2\u0098\u0096"+
		"\3\2\2\2\u0099\u009d\t\7\2\2\u009a\u009c\t\b\2\2\u009b\u009a\3\2\2\2\u009c"+
		"\u009f\3\2\2\2\u009d\u009b\3\2\2\2\u009d\u009e\3\2\2\2\u009e$\3\2\2\2"+
		"\u009f\u009d\3\2\2\2\u00a0\u00a4\t\t\2\2\u00a1\u00a3\t\n\2\2\u00a2\u00a1"+
		"\3\2\2\2\u00a3\u00a6\3\2\2\2\u00a4\u00a2\3\2\2\2\u00a4\u00a5\3\2\2\2\u00a5"+
		"&\3\2\2\2\u00a6\u00a4\3\2\2\2\u00a7\u00ab\t\13\2\2\u00a8\u00aa\t\f\2\2"+
		"\u00a9\u00a8\3\2\2\2\u00aa\u00ad\3\2\2\2\u00ab\u00a9\3\2\2\2\u00ab\u00ac"+
		"\3\2\2\2\u00ac(\3\2\2\2\u00ad\u00ab\3\2\2\2\u00ae\u00af\7\60\2\2\u00af"+
		"\u00b0\5#\22\2\u00b0*\3\2\2\2\u00b1\u00b2\7\60\2\2\u00b2\u00b3\5+\26\2"+
		"\u00b3,\3\2\2\2\u00b4\u00b6\t\r\2\2\u00b5\u00b7\5\37\20\2\u00b6\u00b5"+
		"\3\2\2\2\u00b6\u00b7\3\2\2\2\u00b7\u00b8\3\2\2\2\u00b8\u00b9\5#\22\2\u00b9"+
		".\3\2\2\2\u00ba\u00bc\t\16\2\2\u00bb\u00bd\5\37\20\2\u00bc\u00bb\3\2\2"+
		"\2\u00bc\u00bd\3\2\2\2\u00bd\u00be\3\2\2\2\u00be\u00bf\5!\21\2\u00bf\60"+
		"\3\2\2\2\u00c0\u00c6\5#\22\2\u00c1\u00c3\5)\25\2\u00c2\u00c4\5-\27\2\u00c3"+
		"\u00c2\3\2\2\2\u00c3\u00c4\3\2\2\2\u00c4\u00c7\3\2\2\2\u00c5\u00c7\5-"+
		"\27\2\u00c6\u00c1\3\2\2\2\u00c6\u00c5\3\2\2\2\u00c7\u00d4\3\2\2\2\u00c8"+
		"\u00c9\7\62\2\2\u00c9\u00ca\7z\2\2\u00ca\u00cb\3\2\2\2\u00cb\u00d1\5!"+
		"\21\2\u00cc\u00ce\5+\26\2\u00cd\u00cf\5/\30\2\u00ce\u00cd\3\2\2\2\u00ce"+
		"\u00cf\3\2\2\2\u00cf\u00d2\3\2\2\2\u00d0\u00d2\5/\30\2\u00d1\u00cc\3\2"+
		"\2\2\u00d1\u00d0\3\2\2\2\u00d2\u00d4\3\2\2\2\u00d3\u00c0\3\2\2\2\u00d3"+
		"\u00c8\3\2\2\2\u00d4\62\3\2\2\2\u00d5\u00e3\5#\22\2\u00d6\u00d7\7\62\2"+
		"\2\u00d7\u00d8\7z\2\2\u00d8\u00d9\3\2\2\2\u00d9\u00e3\5!\21\2\u00da\u00db"+
		"\7\62\2\2\u00db\u00dc\7q\2\2\u00dc\u00dd\3\2\2\2\u00dd\u00e3\5%\23\2\u00de"+
		"\u00df\7\62\2\2\u00df\u00e0\7d\2\2\u00e0\u00e1\3\2\2\2\u00e1\u00e3\5\'"+
		"\24\2\u00e2\u00d5\3\2\2\2\u00e2\u00d6\3\2\2\2\u00e2\u00da\3\2\2\2\u00e2"+
		"\u00de\3\2\2\2\u00e3\64\3\2\2\2\u00e4\u00e6\5\61\31\2\u00e5\u00e7\t\17"+
		"\2\2\u00e6\u00e5\3\2\2\2\u00e6\u00e7\3\2\2\2\u00e7\66\3\2\2\2\u00e8\u00ea"+
		"\5\63\32\2\u00e9\u00eb\t\17\2\2\u00ea\u00e9\3\2\2\2\u00ea\u00eb\3\2\2"+
		"\2\u00eb8\3\2\2\2\u00ec\u00f2\7$\2\2\u00ed\u00ee\7^\2\2\u00ee\u00f1\13"+
		"\2\2\2\u00ef\u00f1\n\20\2\2\u00f0\u00ed\3\2\2\2\u00f0\u00ef\3\2\2\2\u00f1"+
		"\u00f4\3\2\2\2\u00f2\u00f0\3\2\2\2\u00f2\u00f3\3\2\2\2\u00f3\u00f5\3\2"+
		"\2\2\u00f4\u00f2\3\2\2\2\u00f5\u00f6\7$\2\2\u00f6:\3\2\2\2\u00f7\u00f8"+
		"\59\35\2\u00f8<\3\2\2\2\u00f9\u00fa\7\61\2\2\u00fa\u00fb\7\61\2\2\u00fb"+
		"\u00ff\3\2\2\2\u00fc\u00fe\n\2\2\2\u00fd\u00fc\3\2\2\2\u00fe\u0101\3\2"+
		"\2\2\u00ff\u00fd\3\2\2\2\u00ff\u0100\3\2\2\2\u0100>\3\2\2\2\u0101\u00ff"+
		"\3\2\2\2\u0102\u0103\7\61\2\2\u0103\u0104\7,\2\2\u0104\u0109\3\2\2\2\u0105"+
		"\u0108\5? \2\u0106\u0108\13\2\2\2\u0107\u0105\3\2\2\2\u0107\u0106\3\2"+
		"\2\2\u0108\u010b\3\2\2\2\u0109\u010a\3\2\2\2\u0109\u0107\3\2\2\2\u010a"+
		"\u010c\3\2\2\2\u010b\u0109\3\2\2\2\u010c\u010d\7,\2\2\u010d\u010e\7\61"+
		"\2\2\u010e@\3\2\2\2\u010f\u0112\5=\37\2\u0110\u0112\5? \2\u0111\u010f"+
		"\3\2\2\2\u0111\u0110\3\2\2\2\u0112\u0113\3\2\2\2\u0113\u0114\b!\2\2\u0114"+
		"B\3\2\2\2\u0115\u0116\t\21\2\2\u0116D\3\2\2\2\u0117\u011a\5C\"\2\u0118"+
		"\u011a\t\7\2\2\u0119\u0117\3\2\2\2\u0119\u0118\3\2\2\2\u011aF\3\2\2\2"+
		"\u011b\u011f\5C\"\2\u011c\u011e\5E#\2\u011d\u011c\3\2\2\2\u011e\u0121"+
		"\3\2\2\2\u011f\u011d\3\2\2\2\u011f\u0120\3\2\2\2\u0120H\3\2\2\2\u0121"+
		"\u011f\3\2\2\2\u0122\u0123\7>\2\2\u0123J\3\2\2\2\u0124\u0125\7@\2\2\u0125"+
		"L\3\2\2\2\u0126\u0127\7)\2\2\u0127N\3\2\2\2\u0128\u0129\7?\2\2\u0129P"+
		"\3\2\2\2\u012a\u012b\7<\2\2\u012bR\3\2\2\2\u012c\u012d\7=\2\2\u012dT\3"+
		"\2\2\2\u012e\u012f\7~\2\2\u012fV\3\2\2\2\u0130\u0131\t\22\2\2\u0131X\3"+
		"\2\2\2\u0132\u0133\5W,\2\u0133Z\3\2\2\2\u0134\u0138\5W,\2\u0135\u0137"+
		"\5Y-\2\u0136\u0135\3\2\2\2\u0137\u013a\3\2\2\2\u0138\u0136\3\2\2\2\u0138"+
		"\u0139\3\2\2\2\u0139\\\3\2\2\2\u013a\u0138\3\2\2\2\36\2y\u0081\u0084\u0088"+
		"\u0096\u009d\u00a4\u00ab\u00b6\u00bc\u00c3\u00c6\u00ce\u00d1\u00d3\u00e2"+
		"\u00e6\u00ea\u00f0\u00f2\u00ff\u0107\u0109\u0111\u0119\u011f\u0138\4\2"+
		"\3\2\b\2\2";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}