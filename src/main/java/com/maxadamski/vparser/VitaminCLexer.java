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
		T__9=10, ShebangLine=11, WS=12, NL=13, Real=14, Int=15, String=16, Comment=17, 
		Name=18, LANGLE=19, RANGLE=20, QUOTE=21, EQUAL=22, COLON=23, SEMI=24, 
		PIPE=25, Symbol=26;
	public static String[] channelNames = {
		"DEFAULT_TOKEN_CHANNEL", "HIDDEN"
	};

	public static String[] modeNames = {
		"DEFAULT_MODE"
	};

	public static final String[] ruleNames = {
		"T__0", "T__1", "T__2", "T__3", "T__4", "T__5", "T__6", "T__7", "T__8", 
		"T__9", "ShebangLine", "Whitespace", "Newline", "WS", "NL", "NumberSign", 
		"HexDigits", "DecDigits", "OctDigits", "BinDigits", "DecFraction", "HexFraction", 
		"DecExponent", "HexExponent", "FloatReal", "IntReal", "Real", "Int", "EscapedString", 
		"String", "LineComment", "BlockComment", "Comment", "NameHead", "NameTail", 
		"Name", "LANGLE", "RANGLE", "QUOTE", "EQUAL", "COLON", "SEMI", "PIPE", 
		"SymbolHead", "SymbolTail", "Symbol"
	};

	private static final String[] _LITERAL_NAMES = {
		null, "'('", "')'", "'if'", "'else'", "'while'", "'{'", "','", "'}'", 
		"'#'", "'`'", null, null, null, null, null, null, null, null, "'<'", "'>'", 
		"'''", "'='", "':'", "';'", "'|'"
	};
	private static final String[] _SYMBOLIC_NAMES = {
		null, null, null, null, null, null, null, null, null, null, null, "ShebangLine", 
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
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\2\34\u0143\b\1\4\2"+
		"\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4"+
		"\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22"+
		"\t\22\4\23\t\23\4\24\t\24\4\25\t\25\4\26\t\26\4\27\t\27\4\30\t\30\4\31"+
		"\t\31\4\32\t\32\4\33\t\33\4\34\t\34\4\35\t\35\4\36\t\36\4\37\t\37\4 \t"+
		" \4!\t!\4\"\t\"\4#\t#\4$\t$\4%\t%\4&\t&\4\'\t\'\4(\t(\4)\t)\4*\t*\4+\t"+
		"+\4,\t,\4-\t-\4.\t.\4/\t/\3\2\3\2\3\3\3\3\3\4\3\4\3\4\3\5\3\5\3\5\3\5"+
		"\3\5\3\6\3\6\3\6\3\6\3\6\3\6\3\7\3\7\3\b\3\b\3\t\3\t\3\n\3\n\3\13\3\13"+
		"\3\f\3\f\3\f\3\f\7\f\u0080\n\f\f\f\16\f\u0083\13\f\3\f\3\f\3\r\6\r\u0088"+
		"\n\r\r\r\16\r\u0089\3\16\5\16\u008d\n\16\3\16\3\16\5\16\u0091\n\16\3\17"+
		"\3\17\3\17\3\17\3\20\3\20\3\21\3\21\3\22\3\22\7\22\u009d\n\22\f\22\16"+
		"\22\u00a0\13\22\3\23\3\23\7\23\u00a4\n\23\f\23\16\23\u00a7\13\23\3\24"+
		"\3\24\7\24\u00ab\n\24\f\24\16\24\u00ae\13\24\3\25\3\25\7\25\u00b2\n\25"+
		"\f\25\16\25\u00b5\13\25\3\26\3\26\3\26\3\27\3\27\3\27\3\30\3\30\5\30\u00bf"+
		"\n\30\3\30\3\30\3\31\3\31\5\31\u00c5\n\31\3\31\3\31\3\32\3\32\3\32\5\32"+
		"\u00cc\n\32\3\32\5\32\u00cf\n\32\3\32\3\32\3\32\3\32\3\32\3\32\5\32\u00d7"+
		"\n\32\3\32\5\32\u00da\n\32\5\32\u00dc\n\32\3\33\3\33\3\33\3\33\3\33\3"+
		"\33\3\33\3\33\3\33\3\33\3\33\3\33\3\33\5\33\u00eb\n\33\3\34\3\34\5\34"+
		"\u00ef\n\34\3\35\3\35\5\35\u00f3\n\35\3\36\3\36\3\36\3\36\7\36\u00f9\n"+
		"\36\f\36\16\36\u00fc\13\36\3\36\3\36\3\37\3\37\3 \3 \3 \3 \7 \u0106\n"+
		" \f \16 \u0109\13 \3!\3!\3!\3!\3!\7!\u0110\n!\f!\16!\u0113\13!\3!\3!\3"+
		"!\3\"\3\"\5\"\u011a\n\"\3\"\3\"\3#\3#\3$\3$\5$\u0122\n$\3%\3%\7%\u0126"+
		"\n%\f%\16%\u0129\13%\3&\3&\3\'\3\'\3(\3(\3)\3)\3*\3*\3+\3+\3,\3,\3-\3"+
		"-\3.\3.\3/\3/\7/\u013f\n/\f/\16/\u0142\13/\3\u0111\2\60\3\3\5\4\7\5\t"+
		"\6\13\7\r\b\17\t\21\n\23\13\25\f\27\r\31\2\33\2\35\16\37\17!\2#\2%\2\'"+
		"\2)\2+\2-\2/\2\61\2\63\2\65\2\67\209\21;\2=\22?\2A\2C\23E\2G\2I\24K\25"+
		"M\26O\27Q\30S\31U\32W\33Y\2[\2]\34\3\2\23\4\2\f\f\17\17\4\2\13\13\"\""+
		"\4\2--//\5\2\62;CHch\6\2\62;CHaach\3\2\62;\4\2\62;aa\3\2\629\4\2\629a"+
		"a\3\2\62\63\4\2\62\63aa\4\2GGgg\4\2RRrr\3\2kk\5\2\f\f\17\17$$\5\2C\\a"+
		"ac|\f\2##&(,-//\61\61<<>A``~~\u0080\u0080\2\u014b\2\3\3\2\2\2\2\5\3\2"+
		"\2\2\2\7\3\2\2\2\2\t\3\2\2\2\2\13\3\2\2\2\2\r\3\2\2\2\2\17\3\2\2\2\2\21"+
		"\3\2\2\2\2\23\3\2\2\2\2\25\3\2\2\2\2\27\3\2\2\2\2\35\3\2\2\2\2\37\3\2"+
		"\2\2\2\67\3\2\2\2\29\3\2\2\2\2=\3\2\2\2\2C\3\2\2\2\2I\3\2\2\2\2K\3\2\2"+
		"\2\2M\3\2\2\2\2O\3\2\2\2\2Q\3\2\2\2\2S\3\2\2\2\2U\3\2\2\2\2W\3\2\2\2\2"+
		"]\3\2\2\2\3_\3\2\2\2\5a\3\2\2\2\7c\3\2\2\2\tf\3\2\2\2\13k\3\2\2\2\rq\3"+
		"\2\2\2\17s\3\2\2\2\21u\3\2\2\2\23w\3\2\2\2\25y\3\2\2\2\27{\3\2\2\2\31"+
		"\u0087\3\2\2\2\33\u008c\3\2\2\2\35\u0092\3\2\2\2\37\u0096\3\2\2\2!\u0098"+
		"\3\2\2\2#\u009a\3\2\2\2%\u00a1\3\2\2\2\'\u00a8\3\2\2\2)\u00af\3\2\2\2"+
		"+\u00b6\3\2\2\2-\u00b9\3\2\2\2/\u00bc\3\2\2\2\61\u00c2\3\2\2\2\63\u00db"+
		"\3\2\2\2\65\u00ea\3\2\2\2\67\u00ec\3\2\2\29\u00f0\3\2\2\2;\u00f4\3\2\2"+
		"\2=\u00ff\3\2\2\2?\u0101\3\2\2\2A\u010a\3\2\2\2C\u0119\3\2\2\2E\u011d"+
		"\3\2\2\2G\u0121\3\2\2\2I\u0123\3\2\2\2K\u012a\3\2\2\2M\u012c\3\2\2\2O"+
		"\u012e\3\2\2\2Q\u0130\3\2\2\2S\u0132\3\2\2\2U\u0134\3\2\2\2W\u0136\3\2"+
		"\2\2Y\u0138\3\2\2\2[\u013a\3\2\2\2]\u013c\3\2\2\2_`\7*\2\2`\4\3\2\2\2"+
		"ab\7+\2\2b\6\3\2\2\2cd\7k\2\2de\7h\2\2e\b\3\2\2\2fg\7g\2\2gh\7n\2\2hi"+
		"\7u\2\2ij\7g\2\2j\n\3\2\2\2kl\7y\2\2lm\7j\2\2mn\7k\2\2no\7n\2\2op\7g\2"+
		"\2p\f\3\2\2\2qr\7}\2\2r\16\3\2\2\2st\7.\2\2t\20\3\2\2\2uv\7\177\2\2v\22"+
		"\3\2\2\2wx\7%\2\2x\24\3\2\2\2yz\7b\2\2z\26\3\2\2\2{|\7%\2\2|}\7#\2\2}"+
		"\u0081\3\2\2\2~\u0080\n\2\2\2\177~\3\2\2\2\u0080\u0083\3\2\2\2\u0081\177"+
		"\3\2\2\2\u0081\u0082\3\2\2\2\u0082\u0084\3\2\2\2\u0083\u0081\3\2\2\2\u0084"+
		"\u0085\b\f\2\2\u0085\30\3\2\2\2\u0086\u0088\t\3\2\2\u0087\u0086\3\2\2"+
		"\2\u0088\u0089\3\2\2\2\u0089\u0087\3\2\2\2\u0089\u008a\3\2\2\2\u008a\32"+
		"\3\2\2\2\u008b\u008d\7\17\2\2\u008c\u008b\3\2\2\2\u008c\u008d\3\2\2\2"+
		"\u008d\u008e\3\2\2\2\u008e\u0090\7\f\2\2\u008f\u0091\7\17\2\2\u0090\u008f"+
		"\3\2\2\2\u0090\u0091\3\2\2\2\u0091\34\3\2\2\2\u0092\u0093\5\31\r\2\u0093"+
		"\u0094\3\2\2\2\u0094\u0095\b\17\3\2\u0095\36\3\2\2\2\u0096\u0097\5\33"+
		"\16\2\u0097 \3\2\2\2\u0098\u0099\t\4\2\2\u0099\"\3\2\2\2\u009a\u009e\t"+
		"\5\2\2\u009b\u009d\t\6\2\2\u009c\u009b\3\2\2\2\u009d\u00a0\3\2\2\2\u009e"+
		"\u009c\3\2\2\2\u009e\u009f\3\2\2\2\u009f$\3\2\2\2\u00a0\u009e\3\2\2\2"+
		"\u00a1\u00a5\t\7\2\2\u00a2\u00a4\t\b\2\2\u00a3\u00a2\3\2\2\2\u00a4\u00a7"+
		"\3\2\2\2\u00a5\u00a3\3\2\2\2\u00a5\u00a6\3\2\2\2\u00a6&\3\2\2\2\u00a7"+
		"\u00a5\3\2\2\2\u00a8\u00ac\t\t\2\2\u00a9\u00ab\t\n\2\2\u00aa\u00a9\3\2"+
		"\2\2\u00ab\u00ae\3\2\2\2\u00ac\u00aa\3\2\2\2\u00ac\u00ad\3\2\2\2\u00ad"+
		"(\3\2\2\2\u00ae\u00ac\3\2\2\2\u00af\u00b3\t\13\2\2\u00b0\u00b2\t\f\2\2"+
		"\u00b1\u00b0\3\2\2\2\u00b2\u00b5\3\2\2\2\u00b3\u00b1\3\2\2\2\u00b3\u00b4"+
		"\3\2\2\2\u00b4*\3\2\2\2\u00b5\u00b3\3\2\2\2\u00b6\u00b7\7\60\2\2\u00b7"+
		"\u00b8\5%\23\2\u00b8,\3\2\2\2\u00b9\u00ba\7\60\2\2\u00ba\u00bb\5-\27\2"+
		"\u00bb.\3\2\2\2\u00bc\u00be\t\r\2\2\u00bd\u00bf\5!\21\2\u00be\u00bd\3"+
		"\2\2\2\u00be\u00bf\3\2\2\2\u00bf\u00c0\3\2\2\2\u00c0\u00c1\5%\23\2\u00c1"+
		"\60\3\2\2\2\u00c2\u00c4\t\16\2\2\u00c3\u00c5\5!\21\2\u00c4\u00c3\3\2\2"+
		"\2\u00c4\u00c5\3\2\2\2\u00c5\u00c6\3\2\2\2\u00c6\u00c7\5#\22\2\u00c7\62"+
		"\3\2\2\2\u00c8\u00ce\5%\23\2\u00c9\u00cb\5+\26\2\u00ca\u00cc\5/\30\2\u00cb"+
		"\u00ca\3\2\2\2\u00cb\u00cc\3\2\2\2\u00cc\u00cf\3\2\2\2\u00cd\u00cf\5/"+
		"\30\2\u00ce\u00c9\3\2\2\2\u00ce\u00cd\3\2\2\2\u00cf\u00dc\3\2\2\2\u00d0"+
		"\u00d1\7\62\2\2\u00d1\u00d2\7z\2\2\u00d2\u00d3\3\2\2\2\u00d3\u00d9\5#"+
		"\22\2\u00d4\u00d6\5-\27\2\u00d5\u00d7\5\61\31\2\u00d6\u00d5\3\2\2\2\u00d6"+
		"\u00d7\3\2\2\2\u00d7\u00da\3\2\2\2\u00d8\u00da\5\61\31\2\u00d9\u00d4\3"+
		"\2\2\2\u00d9\u00d8\3\2\2\2\u00da\u00dc\3\2\2\2\u00db\u00c8\3\2\2\2\u00db"+
		"\u00d0\3\2\2\2\u00dc\64\3\2\2\2\u00dd\u00eb\5%\23\2\u00de\u00df\7\62\2"+
		"\2\u00df\u00e0\7z\2\2\u00e0\u00e1\3\2\2\2\u00e1\u00eb\5#\22\2\u00e2\u00e3"+
		"\7\62\2\2\u00e3\u00e4\7q\2\2\u00e4\u00e5\3\2\2\2\u00e5\u00eb\5\'\24\2"+
		"\u00e6\u00e7\7\62\2\2\u00e7\u00e8\7d\2\2\u00e8\u00e9\3\2\2\2\u00e9\u00eb"+
		"\5)\25\2\u00ea\u00dd\3\2\2\2\u00ea\u00de\3\2\2\2\u00ea\u00e2\3\2\2\2\u00ea"+
		"\u00e6\3\2\2\2\u00eb\66\3\2\2\2\u00ec\u00ee\5\63\32\2\u00ed\u00ef\t\17"+
		"\2\2\u00ee\u00ed\3\2\2\2\u00ee\u00ef\3\2\2\2\u00ef8\3\2\2\2\u00f0\u00f2"+
		"\5\65\33\2\u00f1\u00f3\t\17\2\2\u00f2\u00f1\3\2\2\2\u00f2\u00f3\3\2\2"+
		"\2\u00f3:\3\2\2\2\u00f4\u00fa\7$\2\2\u00f5\u00f6\7^\2\2\u00f6\u00f9\13"+
		"\2\2\2\u00f7\u00f9\n\20\2\2\u00f8\u00f5\3\2\2\2\u00f8\u00f7\3\2\2\2\u00f9"+
		"\u00fc\3\2\2\2\u00fa\u00f8\3\2\2\2\u00fa\u00fb\3\2\2\2\u00fb\u00fd\3\2"+
		"\2\2\u00fc\u00fa\3\2\2\2\u00fd\u00fe\7$\2\2\u00fe<\3\2\2\2\u00ff\u0100"+
		"\5;\36\2\u0100>\3\2\2\2\u0101\u0102\7\61\2\2\u0102\u0103\7\61\2\2\u0103"+
		"\u0107\3\2\2\2\u0104\u0106\n\2\2\2\u0105\u0104\3\2\2\2\u0106\u0109\3\2"+
		"\2\2\u0107\u0105\3\2\2\2\u0107\u0108\3\2\2\2\u0108@\3\2\2\2\u0109\u0107"+
		"\3\2\2\2\u010a\u010b\7\61\2\2\u010b\u010c\7,\2\2\u010c\u0111\3\2\2\2\u010d"+
		"\u0110\5A!\2\u010e\u0110\13\2\2\2\u010f\u010d\3\2\2\2\u010f\u010e\3\2"+
		"\2\2\u0110\u0113\3\2\2\2\u0111\u0112\3\2\2\2\u0111\u010f\3\2\2\2\u0112"+
		"\u0114\3\2\2\2\u0113\u0111\3\2\2\2\u0114\u0115\7,\2\2\u0115\u0116\7\61"+
		"\2\2\u0116B\3\2\2\2\u0117\u011a\5? \2\u0118\u011a\5A!\2\u0119\u0117\3"+
		"\2\2\2\u0119\u0118\3\2\2\2\u011a\u011b\3\2\2\2\u011b\u011c\b\"\2\2\u011c"+
		"D\3\2\2\2\u011d\u011e\t\21\2\2\u011eF\3\2\2\2\u011f\u0122\5E#\2\u0120"+
		"\u0122\t\7\2\2\u0121\u011f\3\2\2\2\u0121\u0120\3\2\2\2\u0122H\3\2\2\2"+
		"\u0123\u0127\5E#\2\u0124\u0126\5G$\2\u0125\u0124\3\2\2\2\u0126\u0129\3"+
		"\2\2\2\u0127\u0125\3\2\2\2\u0127\u0128\3\2\2\2\u0128J\3\2\2\2\u0129\u0127"+
		"\3\2\2\2\u012a\u012b\7>\2\2\u012bL\3\2\2\2\u012c\u012d\7@\2\2\u012dN\3"+
		"\2\2\2\u012e\u012f\7)\2\2\u012fP\3\2\2\2\u0130\u0131\7?\2\2\u0131R\3\2"+
		"\2\2\u0132\u0133\7<\2\2\u0133T\3\2\2\2\u0134\u0135\7=\2\2\u0135V\3\2\2"+
		"\2\u0136\u0137\7~\2\2\u0137X\3\2\2\2\u0138\u0139\t\22\2\2\u0139Z\3\2\2"+
		"\2\u013a\u013b\5Y-\2\u013b\\\3\2\2\2\u013c\u0140\5Y-\2\u013d\u013f\5["+
		".\2\u013e\u013d\3\2\2\2\u013f\u0142\3\2\2\2\u0140\u013e\3\2\2\2\u0140"+
		"\u0141\3\2\2\2\u0141^\3\2\2\2\u0142\u0140\3\2\2\2\36\2\u0081\u0089\u008c"+
		"\u0090\u009e\u00a5\u00ac\u00b3\u00be\u00c4\u00cb\u00ce\u00d6\u00d9\u00db"+
		"\u00ea\u00ee\u00f2\u00f8\u00fa\u0107\u010f\u0111\u0119\u0121\u0127\u0140"+
		"\4\2\3\2\b\2\2";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}