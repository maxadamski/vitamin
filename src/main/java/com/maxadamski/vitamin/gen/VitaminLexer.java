// Generated from C:/Users/Max/Desktop/vitamin/src/main/scala/com/maxadamski/vitamin/parser\VitaminLexer.g4 by ANTLR 4.7.2
package com.maxadamski.vitamin.gen;
import org.antlr.v4.runtime.Lexer;
import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.atn.*;
import org.antlr.v4.runtime.dfa.DFA;
import org.antlr.v4.runtime.misc.*;

@SuppressWarnings({"all", "warnings", "unchecked", "unused", "cast"})
public class VitaminLexer extends Lexer {
	static { RuntimeMetaData.checkVersion("4.7.2", RuntimeMetaData.VERSION); }

	protected static final DFA[] _decisionToDFA;
	protected static final PredictionContextCache _sharedContextCache =
		new PredictionContextCache();
	public static final int
		Shebang=1, NL=2, WS=3, Num1=4, Num2=5, Str1=6, Str2=7, Comment1=8, Comment2=9, 
		Symb=10, Atom=11, IN=12, SEMI=13, COMMA=14, QUASI=15, LBRACE=16, RBRACE=17, 
		LBRACK=18, RBRACK=19, LPAREN=20, RPAREN=21;
	public static String[] channelNames = {
		"DEFAULT_TOKEN_CHANNEL", "HIDDEN"
	};

	public static String[] modeNames = {
		"DEFAULT_MODE"
	};

	private static String[] makeRuleNames() {
		return new String[] {
			"Shebang", "NL", "WS", "Radix", "Digit1", "Digit2", "Num1", "Num2", "Str1", 
			"Str2", "Comment1", "Comment2", "SymbHead", "SymbTail", "NameHead", "NameTail", 
			"Symb", "Atom", "IN", "SEMI", "COMMA", "QUASI", "LBRACE", "RBRACE", "LBRACK", 
			"RBRACK", "LPAREN", "RPAREN", "Reserved"
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


	public VitaminLexer(CharStream input) {
		super(input);
		_interp = new LexerATNSimulator(this,_ATN,_decisionToDFA,_sharedContextCache);
	}

	@Override
	public String getGrammarFileName() { return "VitaminLexer.g4"; }

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
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\2\27\u0128\b\1\4\2"+
		"\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4"+
		"\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22"+
		"\t\22\4\23\t\23\4\24\t\24\4\25\t\25\4\26\t\26\4\27\t\27\4\30\t\30\4\31"+
		"\t\31\4\32\t\32\4\33\t\33\4\34\t\34\4\35\t\35\4\36\t\36\3\2\3\2\3\2\3"+
		"\2\7\2B\n\2\f\2\16\2E\13\2\3\2\3\2\3\3\5\3J\n\3\3\3\3\3\5\3N\n\3\3\3\3"+
		"\3\3\4\6\4S\n\4\r\4\16\4T\3\4\3\4\3\5\3\5\3\5\3\5\7\5]\n\5\f\5\16\5`\13"+
		"\5\3\5\5\5c\n\5\3\6\3\6\7\6g\n\6\f\6\16\6j\13\6\3\7\3\7\7\7n\n\7\f\7\16"+
		"\7q\13\7\3\b\3\b\3\b\3\t\3\t\3\t\5\ty\n\t\3\n\5\n|\n\n\3\n\3\n\3\n\3\n"+
		"\7\n\u0082\n\n\f\n\16\n\u0085\13\n\3\n\3\n\3\13\5\13\u008a\n\13\3\13\3"+
		"\13\3\13\3\13\3\13\3\13\3\13\7\13\u0093\n\13\f\13\16\13\u0096\13\13\3"+
		"\13\3\13\3\13\3\13\3\f\3\f\3\f\3\f\7\f\u00a0\n\f\f\f\16\f\u00a3\13\f\3"+
		"\f\3\f\3\r\3\r\3\r\3\r\3\r\7\r\u00ac\n\r\f\r\16\r\u00af\13\r\3\r\3\r\3"+
		"\r\3\r\3\r\3\16\3\16\3\17\3\17\5\17\u00ba\n\17\3\20\3\20\3\21\3\21\3\22"+
		"\3\22\3\22\7\22\u00c3\n\22\f\22\16\22\u00c6\13\22\5\22\u00c8\n\22\3\23"+
		"\3\23\7\23\u00cc\n\23\f\23\16\23\u00cf\13\23\3\24\3\24\3\24\3\25\3\25"+
		"\3\26\3\26\3\27\3\27\3\30\3\30\3\31\3\31\3\32\3\32\3\33\3\33\3\34\3\34"+
		"\3\35\3\35\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36"+
		"\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36"+
		"\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36"+
		"\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36"+
		"\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\3\36\5\36\u0127\n\36"+
		"\4\u0094\u00ad\2\37\3\3\5\4\7\5\t\2\13\2\r\2\17\6\21\7\23\b\25\t\27\n"+
		"\31\13\33\2\35\2\37\2!\2#\f%\r\'\16)\17+\20-\21/\22\61\23\63\24\65\25"+
		"\67\269\27;\2\3\2\17\4\2\f\f\17\17\4\2\13\13\"\"\5\2ddqqzz\3\2\63;\3\2"+
		"\62;\5\2\62;C\\c|\6\2\62;C\\aac|\4\2\62;aa\5\2\f\f\17\17$$\13\2##&(,-"+
		"/\61<<>A`a~~\u0080\u0080\4\2%%BB\6\2%%B\\aac|\t\2##))\62;AAC\\aac|\2\u0146"+
		"\2\3\3\2\2\2\2\5\3\2\2\2\2\7\3\2\2\2\2\17\3\2\2\2\2\21\3\2\2\2\2\23\3"+
		"\2\2\2\2\25\3\2\2\2\2\27\3\2\2\2\2\31\3\2\2\2\2#\3\2\2\2\2%\3\2\2\2\2"+
		"\'\3\2\2\2\2)\3\2\2\2\2+\3\2\2\2\2-\3\2\2\2\2/\3\2\2\2\2\61\3\2\2\2\2"+
		"\63\3\2\2\2\2\65\3\2\2\2\2\67\3\2\2\2\29\3\2\2\2\3=\3\2\2\2\5I\3\2\2\2"+
		"\7R\3\2\2\2\tb\3\2\2\2\13d\3\2\2\2\rk\3\2\2\2\17r\3\2\2\2\21u\3\2\2\2"+
		"\23{\3\2\2\2\25\u0089\3\2\2\2\27\u009b\3\2\2\2\31\u00a6\3\2\2\2\33\u00b5"+
		"\3\2\2\2\35\u00b9\3\2\2\2\37\u00bb\3\2\2\2!\u00bd\3\2\2\2#\u00c7\3\2\2"+
		"\2%\u00c9\3\2\2\2\'\u00d0\3\2\2\2)\u00d3\3\2\2\2+\u00d5\3\2\2\2-\u00d7"+
		"\3\2\2\2/\u00d9\3\2\2\2\61\u00db\3\2\2\2\63\u00dd\3\2\2\2\65\u00df\3\2"+
		"\2\2\67\u00e1\3\2\2\29\u00e3\3\2\2\2;\u0126\3\2\2\2=>\7%\2\2>?\7#\2\2"+
		"?C\3\2\2\2@B\n\2\2\2A@\3\2\2\2BE\3\2\2\2CA\3\2\2\2CD\3\2\2\2DF\3\2\2\2"+
		"EC\3\2\2\2FG\b\2\2\2G\4\3\2\2\2HJ\7\17\2\2IH\3\2\2\2IJ\3\2\2\2JK\3\2\2"+
		"\2KM\7\f\2\2LN\7\17\2\2ML\3\2\2\2MN\3\2\2\2NO\3\2\2\2OP\b\3\2\2P\6\3\2"+
		"\2\2QS\t\3\2\2RQ\3\2\2\2ST\3\2\2\2TR\3\2\2\2TU\3\2\2\2UV\3\2\2\2VW\b\4"+
		"\2\2W\b\3\2\2\2XY\7\62\2\2Yc\t\4\2\2Z^\t\5\2\2[]\t\6\2\2\\[\3\2\2\2]`"+
		"\3\2\2\2^\\\3\2\2\2^_\3\2\2\2_a\3\2\2\2`^\3\2\2\2ac\7%\2\2bX\3\2\2\2b"+
		"Z\3\2\2\2c\n\3\2\2\2dh\t\7\2\2eg\t\b\2\2fe\3\2\2\2gj\3\2\2\2hf\3\2\2\2"+
		"hi\3\2\2\2i\f\3\2\2\2jh\3\2\2\2ko\t\6\2\2ln\t\t\2\2ml\3\2\2\2nq\3\2\2"+
		"\2om\3\2\2\2op\3\2\2\2p\16\3\2\2\2qo\3\2\2\2rs\5\t\5\2st\5\13\6\2t\20"+
		"\3\2\2\2ux\5\r\7\2vw\7\60\2\2wy\5\r\7\2xv\3\2\2\2xy\3\2\2\2y\22\3\2\2"+
		"\2z|\5%\23\2{z\3\2\2\2{|\3\2\2\2|}\3\2\2\2}\u0083\7$\2\2~\177\7^\2\2\177"+
		"\u0082\7$\2\2\u0080\u0082\n\n\2\2\u0081~\3\2\2\2\u0081\u0080\3\2\2\2\u0082"+
		"\u0085\3\2\2\2\u0083\u0081\3\2\2\2\u0083\u0084\3\2\2\2\u0084\u0086\3\2"+
		"\2\2\u0085\u0083\3\2\2\2\u0086\u0087\7$\2\2\u0087\24\3\2\2\2\u0088\u008a"+
		"\5%\23\2\u0089\u0088\3\2\2\2\u0089\u008a\3\2\2\2\u008a\u008b\3\2\2\2\u008b"+
		"\u008c\7$\2\2\u008c\u008d\7$\2\2\u008d\u008e\7$\2\2\u008e\u0094\3\2\2"+
		"\2\u008f\u0090\7^\2\2\u0090\u0093\7$\2\2\u0091\u0093\13\2\2\2\u0092\u008f"+
		"\3\2\2\2\u0092\u0091\3\2\2\2\u0093\u0096\3\2\2\2\u0094\u0095\3\2\2\2\u0094"+
		"\u0092\3\2\2\2\u0095\u0097\3\2\2\2\u0096\u0094\3\2\2\2\u0097\u0098\7$"+
		"\2\2\u0098\u0099\7$\2\2\u0099\u009a\7$\2\2\u009a\26\3\2\2\2\u009b\u009c"+
		"\7\61\2\2\u009c\u009d\7\61\2\2\u009d\u00a1\3\2\2\2\u009e\u00a0\n\2\2\2"+
		"\u009f\u009e\3\2\2\2\u00a0\u00a3\3\2\2\2\u00a1\u009f\3\2\2\2\u00a1\u00a2"+
		"\3\2\2\2\u00a2\u00a4\3\2\2\2\u00a3\u00a1\3\2\2\2\u00a4\u00a5\b\f\2\2\u00a5"+
		"\30\3\2\2\2\u00a6\u00a7\7\61\2\2\u00a7\u00a8\7,\2\2\u00a8\u00ad\3\2\2"+
		"\2\u00a9\u00ac\5\31\r\2\u00aa\u00ac\13\2\2\2\u00ab\u00a9\3\2\2\2\u00ab"+
		"\u00aa\3\2\2\2\u00ac\u00af\3\2\2\2\u00ad\u00ae\3\2\2\2\u00ad\u00ab\3\2"+
		"\2\2\u00ae\u00b0\3\2\2\2\u00af\u00ad\3\2\2\2\u00b0\u00b1\7,\2\2\u00b1"+
		"\u00b2\7\61\2\2\u00b2\u00b3\3\2\2\2\u00b3\u00b4\b\r\2\2\u00b4\32\3\2\2"+
		"\2\u00b5\u00b6\t\13\2\2\u00b6\34\3\2\2\2\u00b7\u00ba\5\33\16\2\u00b8\u00ba"+
		"\t\f\2\2\u00b9\u00b7\3\2\2\2\u00b9\u00b8\3\2\2\2\u00ba\36\3\2\2\2\u00bb"+
		"\u00bc\t\r\2\2\u00bc \3\2\2\2\u00bd\u00be\t\16\2\2\u00be\"\3\2\2\2\u00bf"+
		"\u00c8\5;\36\2\u00c0\u00c4\5\33\16\2\u00c1\u00c3\5\35\17\2\u00c2\u00c1"+
		"\3\2\2\2\u00c3\u00c6\3\2\2\2\u00c4\u00c2\3\2\2\2\u00c4\u00c5\3\2\2\2\u00c5"+
		"\u00c8\3\2\2\2\u00c6\u00c4\3\2\2\2\u00c7\u00bf\3\2\2\2\u00c7\u00c0\3\2"+
		"\2\2\u00c8$\3\2\2\2\u00c9\u00cd\5\37\20\2\u00ca\u00cc\5!\21\2\u00cb\u00ca"+
		"\3\2\2\2\u00cc\u00cf\3\2\2\2\u00cd\u00cb\3\2\2\2\u00cd\u00ce\3\2\2\2\u00ce"+
		"&\3\2\2\2\u00cf\u00cd\3\2\2\2\u00d0\u00d1\7k\2\2\u00d1\u00d2\7p\2\2\u00d2"+
		"(\3\2\2\2\u00d3\u00d4\7=\2\2\u00d4*\3\2\2\2\u00d5\u00d6\7.\2\2\u00d6,"+
		"\3\2\2\2\u00d7\u00d8\7b\2\2\u00d8.\3\2\2\2\u00d9\u00da\7}\2\2\u00da\60"+
		"\3\2\2\2\u00db\u00dc\7\177\2\2\u00dc\62\3\2\2\2\u00dd\u00de\7]\2\2\u00de"+
		"\64\3\2\2\2\u00df\u00e0\7_\2\2\u00e0\66\3\2\2\2\u00e1\u00e2\7*\2\2\u00e2"+
		"8\3\2\2\2\u00e3\u00e4\7+\2\2\u00e4:\3\2\2\2\u00e5\u00e6\7n\2\2\u00e6\u00e7"+
		"\7g\2\2\u00e7\u0127\7v\2\2\u00e8\u00e9\7x\2\2\u00e9\u00ea\7c\2\2\u00ea"+
		"\u0127\7t\2\2\u00eb\u00ec\7f\2\2\u00ec\u00ed\7g\2\2\u00ed\u0127\7h\2\2"+
		"\u00ee\u00ef\7h\2\2\u00ef\u00f0\7w\2\2\u00f0\u0127\7p\2\2\u00f1\u00f2"+
		"\7v\2\2\u00f2\u00f3\7{\2\2\u00f3\u00f4\7r\2\2\u00f4\u0127\7g\2\2\u00f5"+
		"\u00f6\7f\2\2\u00f6\u00f7\7c\2\2\u00f7\u00f8\7v\2\2\u00f8\u0127\7c\2\2"+
		"\u00f9\u00fa\7g\2\2\u00fa\u00fb\7p\2\2\u00fb\u00fc\7w\2\2\u00fc\u0127"+
		"\7o\2\2\u00fd\u00fe\7r\2\2\u00fe\u00ff\7t\2\2\u00ff\u0100\7q\2\2\u0100"+
		"\u0101\7v\2\2\u0101\u0102\7q\2\2\u0102\u0103\7e\2\2\u0103\u0104\7q\2\2"+
		"\u0104\u0127\7n\2\2\u0105\u0106\7k\2\2\u0106\u0107\7p\2\2\u0107\u0108"+
		"\7u\2\2\u0108\u0109\7v\2\2\u0109\u010a\7c\2\2\u010a\u010b\7p\2\2\u010b"+
		"\u010c\7e\2\2\u010c\u0127\7g\2\2\u010d\u010e\7p\2\2\u010e\u010f\7q\2\2"+
		"\u010f\u0127\7v\2\2\u0110\u0111\7c\2\2\u0111\u0112\7p\2\2\u0112\u0127"+
		"\7f\2\2\u0113\u0114\7q\2\2\u0114\u0127\7t\2\2\u0115\u0116\7f\2\2\u0116"+
		"\u0117\7k\2\2\u0117\u0127\7x\2\2\u0118\u0119\7o\2\2\u0119\u011a\7q\2\2"+
		"\u011a\u0127\7f\2\2\u011b\u011c\7t\2\2\u011c\u011d\7g\2\2\u011d\u0127"+
		"\7o\2\2\u011e\u011f\7y\2\2\u011f\u0120\7j\2\2\u0120\u0121\7g\2\2\u0121"+
		"\u0122\7t\2\2\u0122\u0127\7g\2\2\u0123\u0124\7c\2\2\u0124\u0127\7u\2\2"+
		"\u0125\u0127\5\'\24\2\u0126\u00e5\3\2\2\2\u0126\u00e8\3\2\2\2\u0126\u00eb"+
		"\3\2\2\2\u0126\u00ee\3\2\2\2\u0126\u00f1\3\2\2\2\u0126\u00f5\3\2\2\2\u0126"+
		"\u00f9\3\2\2\2\u0126\u00fd\3\2\2\2\u0126\u0105\3\2\2\2\u0126\u010d\3\2"+
		"\2\2\u0126\u0110\3\2\2\2\u0126\u0113\3\2\2\2\u0126\u0115\3\2\2\2\u0126"+
		"\u0118\3\2\2\2\u0126\u011b\3\2\2\2\u0126\u011e\3\2\2\2\u0126\u0123\3\2"+
		"\2\2\u0126\u0125\3\2\2\2\u0127<\3\2\2\2\32\2CIMT^bhox{\u0081\u0083\u0089"+
		"\u0092\u0094\u00a1\u00ab\u00ad\u00b9\u00c4\u00c7\u00cd\u0126\3\2\3\2";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}