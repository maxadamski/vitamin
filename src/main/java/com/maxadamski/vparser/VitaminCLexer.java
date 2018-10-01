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
		T__9=10, T__10=11, T__11=12, ShebangLine=13, WS=14, NL=15, Real=16, Int=17, 
		String=18, Comment=19, Name=20, MINUS=21, LANGLE=22, RANGLE=23, QUOTE=24, 
		EQUAL=25, COLON=26, SEMI=27, PIPE=28, Symbol=29;
	public static String[] channelNames = {
		"DEFAULT_TOKEN_CHANNEL", "HIDDEN"
	};

	public static String[] modeNames = {
		"DEFAULT_MODE"
	};

	public static final String[] ruleNames = {
		"T__0", "T__1", "T__2", "T__3", "T__4", "T__5", "T__6", "T__7", "T__8", 
		"T__9", "T__10", "T__11", "ShebangLine", "Whitespace", "Newline", "WS", 
		"NL", "NumberSign", "HexDigits", "DecDigits", "OctDigits", "BinDigits", 
		"DecFraction", "HexFraction", "DecExponent", "HexExponent", "FloatReal", 
		"IntReal", "Real", "Int", "EscapedString", "String", "LineComment", "BlockComment", 
		"Comment", "NameHead", "NameTail", "Name", "MINUS", "LANGLE", "RANGLE", 
		"QUOTE", "EQUAL", "COLON", "SEMI", "PIPE", "SymbolUsed", "SymbolHead", 
		"SymbolTail", "Symbol"
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
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\2\37\u0157\b\1\4\2"+
		"\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4"+
		"\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22"+
		"\t\22\4\23\t\23\4\24\t\24\4\25\t\25\4\26\t\26\4\27\t\27\4\30\t\30\4\31"+
		"\t\31\4\32\t\32\4\33\t\33\4\34\t\34\4\35\t\35\4\36\t\36\4\37\t\37\4 \t"+
		" \4!\t!\4\"\t\"\4#\t#\4$\t$\4%\t%\4&\t&\4\'\t\'\4(\t(\4)\t)\4*\t*\4+\t"+
		"+\4,\t,\4-\t-\4.\t.\4/\t/\4\60\t\60\4\61\t\61\4\62\t\62\4\63\t\63\3\2"+
		"\3\2\3\3\3\3\3\4\3\4\3\4\3\5\3\5\3\5\3\5\3\5\3\6\3\6\3\6\3\6\3\6\3\6\3"+
		"\7\3\7\3\b\3\b\3\t\3\t\3\t\3\n\3\n\3\n\3\13\3\13\3\f\3\f\3\r\3\r\3\16"+
		"\3\16\3\16\3\16\7\16\u008e\n\16\f\16\16\16\u0091\13\16\3\16\3\16\3\17"+
		"\6\17\u0096\n\17\r\17\16\17\u0097\3\20\5\20\u009b\n\20\3\20\3\20\5\20"+
		"\u009f\n\20\3\21\3\21\3\21\3\21\3\22\3\22\3\23\3\23\3\24\3\24\7\24\u00ab"+
		"\n\24\f\24\16\24\u00ae\13\24\3\25\3\25\7\25\u00b2\n\25\f\25\16\25\u00b5"+
		"\13\25\3\26\3\26\7\26\u00b9\n\26\f\26\16\26\u00bc\13\26\3\27\3\27\7\27"+
		"\u00c0\n\27\f\27\16\27\u00c3\13\27\3\30\3\30\3\30\3\31\3\31\3\31\3\32"+
		"\3\32\5\32\u00cd\n\32\3\32\3\32\3\33\3\33\5\33\u00d3\n\33\3\33\3\33\3"+
		"\34\3\34\3\34\5\34\u00da\n\34\3\34\5\34\u00dd\n\34\3\34\3\34\3\34\3\34"+
		"\3\34\3\34\5\34\u00e5\n\34\3\34\5\34\u00e8\n\34\5\34\u00ea\n\34\3\35\3"+
		"\35\3\35\3\35\3\35\3\35\3\35\3\35\3\35\3\35\3\35\3\35\3\35\5\35\u00f9"+
		"\n\35\3\36\3\36\5\36\u00fd\n\36\3\37\3\37\5\37\u0101\n\37\3 \3 \3 \3 "+
		"\7 \u0107\n \f \16 \u010a\13 \3 \3 \3!\3!\3\"\3\"\3\"\3\"\7\"\u0114\n"+
		"\"\f\"\16\"\u0117\13\"\3#\3#\3#\3#\3#\7#\u011e\n#\f#\16#\u0121\13#\3#"+
		"\3#\3#\3$\3$\5$\u0128\n$\3$\3$\3%\3%\3&\3&\5&\u0130\n&\3\'\3\'\7\'\u0134"+
		"\n\'\f\'\16\'\u0137\13\'\3(\3(\3)\3)\3*\3*\3+\3+\3,\3,\3-\3-\3.\3.\3/"+
		"\3/\3\60\3\60\3\61\3\61\5\61\u014d\n\61\3\62\3\62\3\63\3\63\7\63\u0153"+
		"\n\63\f\63\16\63\u0156\13\63\3\u011f\2\64\3\3\5\4\7\5\t\6\13\7\r\b\17"+
		"\t\21\n\23\13\25\f\27\r\31\16\33\17\35\2\37\2!\20#\21%\2\'\2)\2+\2-\2"+
		"/\2\61\2\63\2\65\2\67\29\2;\22=\23?\2A\24C\2E\2G\25I\2K\2M\26O\27Q\30"+
		"S\31U\32W\33Y\34[\35]\36_\2a\2c\2e\37\3\2\24\4\2\f\f\17\17\4\2\13\13\""+
		"\"\4\2--//\5\2\62;CHch\6\2\62;CHaach\3\2\62;\4\2\62;aa\3\2\629\4\2\62"+
		"9aa\3\2\62\63\4\2\62\63aa\4\2GGgg\4\2RRrr\3\2kk\5\2\f\f\17\17$$\5\2C\\"+
		"aac|\6\2//<<>@~~\n\2##&(,-\61\61AA``~~\u0080\u0080\2\u015f\2\3\3\2\2\2"+
		"\2\5\3\2\2\2\2\7\3\2\2\2\2\t\3\2\2\2\2\13\3\2\2\2\2\r\3\2\2\2\2\17\3\2"+
		"\2\2\2\21\3\2\2\2\2\23\3\2\2\2\2\25\3\2\2\2\2\27\3\2\2\2\2\31\3\2\2\2"+
		"\2\33\3\2\2\2\2!\3\2\2\2\2#\3\2\2\2\2;\3\2\2\2\2=\3\2\2\2\2A\3\2\2\2\2"+
		"G\3\2\2\2\2M\3\2\2\2\2O\3\2\2\2\2Q\3\2\2\2\2S\3\2\2\2\2U\3\2\2\2\2W\3"+
		"\2\2\2\2Y\3\2\2\2\2[\3\2\2\2\2]\3\2\2\2\2e\3\2\2\2\3g\3\2\2\2\5i\3\2\2"+
		"\2\7k\3\2\2\2\tn\3\2\2\2\13s\3\2\2\2\ry\3\2\2\2\17{\3\2\2\2\21}\3\2\2"+
		"\2\23\u0080\3\2\2\2\25\u0083\3\2\2\2\27\u0085\3\2\2\2\31\u0087\3\2\2\2"+
		"\33\u0089\3\2\2\2\35\u0095\3\2\2\2\37\u009a\3\2\2\2!\u00a0\3\2\2\2#\u00a4"+
		"\3\2\2\2%\u00a6\3\2\2\2\'\u00a8\3\2\2\2)\u00af\3\2\2\2+\u00b6\3\2\2\2"+
		"-\u00bd\3\2\2\2/\u00c4\3\2\2\2\61\u00c7\3\2\2\2\63\u00ca\3\2\2\2\65\u00d0"+
		"\3\2\2\2\67\u00e9\3\2\2\29\u00f8\3\2\2\2;\u00fa\3\2\2\2=\u00fe\3\2\2\2"+
		"?\u0102\3\2\2\2A\u010d\3\2\2\2C\u010f\3\2\2\2E\u0118\3\2\2\2G\u0127\3"+
		"\2\2\2I\u012b\3\2\2\2K\u012f\3\2\2\2M\u0131\3\2\2\2O\u0138\3\2\2\2Q\u013a"+
		"\3\2\2\2S\u013c\3\2\2\2U\u013e\3\2\2\2W\u0140\3\2\2\2Y\u0142\3\2\2\2["+
		"\u0144\3\2\2\2]\u0146\3\2\2\2_\u0148\3\2\2\2a\u014c\3\2\2\2c\u014e\3\2"+
		"\2\2e\u0150\3\2\2\2gh\7*\2\2h\4\3\2\2\2ij\7+\2\2j\6\3\2\2\2kl\7k\2\2l"+
		"m\7h\2\2m\b\3\2\2\2no\7g\2\2op\7n\2\2pq\7u\2\2qr\7g\2\2r\n\3\2\2\2st\7"+
		"y\2\2tu\7j\2\2uv\7k\2\2vw\7n\2\2wx\7g\2\2x\f\3\2\2\2yz\7}\2\2z\16\3\2"+
		"\2\2{|\7.\2\2|\20\3\2\2\2}~\7/\2\2~\177\7@\2\2\177\22\3\2\2\2\u0080\u0081"+
		"\7k\2\2\u0081\u0082\7p\2\2\u0082\24\3\2\2\2\u0083\u0084\7\177\2\2\u0084"+
		"\26\3\2\2\2\u0085\u0086\7%\2\2\u0086\30\3\2\2\2\u0087\u0088\7b\2\2\u0088"+
		"\32\3\2\2\2\u0089\u008a\7%\2\2\u008a\u008b\7#\2\2\u008b\u008f\3\2\2\2"+
		"\u008c\u008e\n\2\2\2\u008d\u008c\3\2\2\2\u008e\u0091\3\2\2\2\u008f\u008d"+
		"\3\2\2\2\u008f\u0090\3\2\2\2\u0090\u0092\3\2\2\2\u0091\u008f\3\2\2\2\u0092"+
		"\u0093\b\16\2\2\u0093\34\3\2\2\2\u0094\u0096\t\3\2\2\u0095\u0094\3\2\2"+
		"\2\u0096\u0097\3\2\2\2\u0097\u0095\3\2\2\2\u0097\u0098\3\2\2\2\u0098\36"+
		"\3\2\2\2\u0099\u009b\7\17\2\2\u009a\u0099\3\2\2\2\u009a\u009b\3\2\2\2"+
		"\u009b\u009c\3\2\2\2\u009c\u009e\7\f\2\2\u009d\u009f\7\17\2\2\u009e\u009d"+
		"\3\2\2\2\u009e\u009f\3\2\2\2\u009f \3\2\2\2\u00a0\u00a1\5\35\17\2\u00a1"+
		"\u00a2\3\2\2\2\u00a2\u00a3\b\21\2\2\u00a3\"\3\2\2\2\u00a4\u00a5\5\37\20"+
		"\2\u00a5$\3\2\2\2\u00a6\u00a7\t\4\2\2\u00a7&\3\2\2\2\u00a8\u00ac\t\5\2"+
		"\2\u00a9\u00ab\t\6\2\2\u00aa\u00a9\3\2\2\2\u00ab\u00ae\3\2\2\2\u00ac\u00aa"+
		"\3\2\2\2\u00ac\u00ad\3\2\2\2\u00ad(\3\2\2\2\u00ae\u00ac\3\2\2\2\u00af"+
		"\u00b3\t\7\2\2\u00b0\u00b2\t\b\2\2\u00b1\u00b0\3\2\2\2\u00b2\u00b5\3\2"+
		"\2\2\u00b3\u00b1\3\2\2\2\u00b3\u00b4\3\2\2\2\u00b4*\3\2\2\2\u00b5\u00b3"+
		"\3\2\2\2\u00b6\u00ba\t\t\2\2\u00b7\u00b9\t\n\2\2\u00b8\u00b7\3\2\2\2\u00b9"+
		"\u00bc\3\2\2\2\u00ba\u00b8\3\2\2\2\u00ba\u00bb\3\2\2\2\u00bb,\3\2\2\2"+
		"\u00bc\u00ba\3\2\2\2\u00bd\u00c1\t\13\2\2\u00be\u00c0\t\f\2\2\u00bf\u00be"+
		"\3\2\2\2\u00c0\u00c3\3\2\2\2\u00c1\u00bf\3\2\2\2\u00c1\u00c2\3\2\2\2\u00c2"+
		".\3\2\2\2\u00c3\u00c1\3\2\2\2\u00c4\u00c5\7\60\2\2\u00c5\u00c6\5)\25\2"+
		"\u00c6\60\3\2\2\2\u00c7\u00c8\7\60\2\2\u00c8\u00c9\5\61\31\2\u00c9\62"+
		"\3\2\2\2\u00ca\u00cc\t\r\2\2\u00cb\u00cd\5%\23\2\u00cc\u00cb\3\2\2\2\u00cc"+
		"\u00cd\3\2\2\2\u00cd\u00ce\3\2\2\2\u00ce\u00cf\5)\25\2\u00cf\64\3\2\2"+
		"\2\u00d0\u00d2\t\16\2\2\u00d1\u00d3\5%\23\2\u00d2\u00d1\3\2\2\2\u00d2"+
		"\u00d3\3\2\2\2\u00d3\u00d4\3\2\2\2\u00d4\u00d5\5\'\24\2\u00d5\66\3\2\2"+
		"\2\u00d6\u00dc\5)\25\2\u00d7\u00d9\5/\30\2\u00d8\u00da\5\63\32\2\u00d9"+
		"\u00d8\3\2\2\2\u00d9\u00da\3\2\2\2\u00da\u00dd\3\2\2\2\u00db\u00dd\5\63"+
		"\32\2\u00dc\u00d7\3\2\2\2\u00dc\u00db\3\2\2\2\u00dd\u00ea\3\2\2\2\u00de"+
		"\u00df\7\62\2\2\u00df\u00e0\7z\2\2\u00e0\u00e1\3\2\2\2\u00e1\u00e7\5\'"+
		"\24\2\u00e2\u00e4\5\61\31\2\u00e3\u00e5\5\65\33\2\u00e4\u00e3\3\2\2\2"+
		"\u00e4\u00e5\3\2\2\2\u00e5\u00e8\3\2\2\2\u00e6\u00e8\5\65\33\2\u00e7\u00e2"+
		"\3\2\2\2\u00e7\u00e6\3\2\2\2\u00e8\u00ea\3\2\2\2\u00e9\u00d6\3\2\2\2\u00e9"+
		"\u00de\3\2\2\2\u00ea8\3\2\2\2\u00eb\u00f9\5)\25\2\u00ec\u00ed\7\62\2\2"+
		"\u00ed\u00ee\7z\2\2\u00ee\u00ef\3\2\2\2\u00ef\u00f9\5\'\24\2\u00f0\u00f1"+
		"\7\62\2\2\u00f1\u00f2\7q\2\2\u00f2\u00f3\3\2\2\2\u00f3\u00f9\5+\26\2\u00f4"+
		"\u00f5\7\62\2\2\u00f5\u00f6\7d\2\2\u00f6\u00f7\3\2\2\2\u00f7\u00f9\5-"+
		"\27\2\u00f8\u00eb\3\2\2\2\u00f8\u00ec\3\2\2\2\u00f8\u00f0\3\2\2\2\u00f8"+
		"\u00f4\3\2\2\2\u00f9:\3\2\2\2\u00fa\u00fc\5\67\34\2\u00fb\u00fd\t\17\2"+
		"\2\u00fc\u00fb\3\2\2\2\u00fc\u00fd\3\2\2\2\u00fd<\3\2\2\2\u00fe\u0100"+
		"\59\35\2\u00ff\u0101\t\17\2\2\u0100\u00ff\3\2\2\2\u0100\u0101\3\2\2\2"+
		"\u0101>\3\2\2\2\u0102\u0108\7$\2\2\u0103\u0104\7^\2\2\u0104\u0107\13\2"+
		"\2\2\u0105\u0107\n\20\2\2\u0106\u0103\3\2\2\2\u0106\u0105\3\2\2\2\u0107"+
		"\u010a\3\2\2\2\u0108\u0106\3\2\2\2\u0108\u0109\3\2\2\2\u0109\u010b\3\2"+
		"\2\2\u010a\u0108\3\2\2\2\u010b\u010c\7$\2\2\u010c@\3\2\2\2\u010d\u010e"+
		"\5? \2\u010eB\3\2\2\2\u010f\u0110\7\61\2\2\u0110\u0111\7\61\2\2\u0111"+
		"\u0115\3\2\2\2\u0112\u0114\n\2\2\2\u0113\u0112\3\2\2\2\u0114\u0117\3\2"+
		"\2\2\u0115\u0113\3\2\2\2\u0115\u0116\3\2\2\2\u0116D\3\2\2\2\u0117\u0115"+
		"\3\2\2\2\u0118\u0119\7\61\2\2\u0119\u011a\7,\2\2\u011a\u011f\3\2\2\2\u011b"+
		"\u011e\5E#\2\u011c\u011e\13\2\2\2\u011d\u011b\3\2\2\2\u011d\u011c\3\2"+
		"\2\2\u011e\u0121\3\2\2\2\u011f\u0120\3\2\2\2\u011f\u011d\3\2\2\2\u0120"+
		"\u0122\3\2\2\2\u0121\u011f\3\2\2\2\u0122\u0123\7,\2\2\u0123\u0124\7\61"+
		"\2\2\u0124F\3\2\2\2\u0125\u0128\5C\"\2\u0126\u0128\5E#\2\u0127\u0125\3"+
		"\2\2\2\u0127\u0126\3\2\2\2\u0128\u0129\3\2\2\2\u0129\u012a\b$\2\2\u012a"+
		"H\3\2\2\2\u012b\u012c\t\21\2\2\u012cJ\3\2\2\2\u012d\u0130\5I%\2\u012e"+
		"\u0130\t\7\2\2\u012f\u012d\3\2\2\2\u012f\u012e\3\2\2\2\u0130L\3\2\2\2"+
		"\u0131\u0135\5I%\2\u0132\u0134\5K&\2\u0133\u0132\3\2\2\2\u0134\u0137\3"+
		"\2\2\2\u0135\u0133\3\2\2\2\u0135\u0136\3\2\2\2\u0136N\3\2\2\2\u0137\u0135"+
		"\3\2\2\2\u0138\u0139\7/\2\2\u0139P\3\2\2\2\u013a\u013b\7>\2\2\u013bR\3"+
		"\2\2\2\u013c\u013d\7@\2\2\u013dT\3\2\2\2\u013e\u013f\7)\2\2\u013fV\3\2"+
		"\2\2\u0140\u0141\7?\2\2\u0141X\3\2\2\2\u0142\u0143\7<\2\2\u0143Z\3\2\2"+
		"\2\u0144\u0145\7=\2\2\u0145\\\3\2\2\2\u0146\u0147\7~\2\2\u0147^\3\2\2"+
		"\2\u0148\u0149\t\22\2\2\u0149`\3\2\2\2\u014a\u014d\t\23\2\2\u014b\u014d"+
		"\5_\60\2\u014c\u014a\3\2\2\2\u014c\u014b\3\2\2\2\u014db\3\2\2\2\u014e"+
		"\u014f\5a\61\2\u014fd\3\2\2\2\u0150\u0154\5a\61\2\u0151\u0153\5c\62\2"+
		"\u0152\u0151\3\2\2\2\u0153\u0156\3\2\2\2\u0154\u0152\3\2\2\2\u0154\u0155"+
		"\3\2\2\2\u0155f\3\2\2\2\u0156\u0154\3\2\2\2\37\2\u008f\u0097\u009a\u009e"+
		"\u00ac\u00b3\u00ba\u00c1\u00cc\u00d2\u00d9\u00dc\u00e4\u00e7\u00e9\u00f8"+
		"\u00fc\u0100\u0106\u0108\u0115\u011d\u011f\u0127\u012f\u0135\u014c\u0154"+
		"\3\2\3\2";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}