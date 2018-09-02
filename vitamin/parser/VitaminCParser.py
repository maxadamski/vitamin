# Generated from VitaminC.g4 by ANTLR 4.7.1
# encoding: utf-8
from antlr4 import *
from io import StringIO
from typing.io import TextIO
import sys

def serializedATN():
    with StringIO() as buf:
        buf.write("\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\3\24")
        buf.write("q\4\2\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b")
        buf.write("\t\b\4\t\t\t\4\n\t\n\4\13\t\13\4\f\t\f\4\r\t\r\4\16\t")
        buf.write("\16\4\17\t\17\4\20\t\20\3\2\3\2\3\3\3\3\3\3\3\3\3\4\3")
        buf.write("\4\7\4)\n\4\f\4\16\4,\13\4\3\5\3\5\3\5\3\6\3\6\3\6\3\6")
        buf.write("\3\6\3\6\3\6\3\6\3\6\5\6:\n\6\3\7\3\7\3\7\5\7?\n\7\3\7")
        buf.write("\3\7\3\b\3\b\3\b\3\b\3\b\3\b\7\bI\n\b\f\b\16\bL\13\b\3")
        buf.write("\b\3\b\3\t\3\t\3\t\6\tS\n\t\r\t\16\tT\3\n\3\n\3\n\3\13")
        buf.write("\6\13[\n\13\r\13\16\13\\\3\f\3\f\3\f\3\f\3\f\5\fd\n\f")
        buf.write("\3\r\3\r\3\r\5\ri\n\r\3\16\3\16\3\17\3\17\3\20\3\20\3")
        buf.write("\20\2\2\21\2\4\6\b\n\f\16\20\22\24\26\30\32\34\36\2\3")
        buf.write("\4\2\22\22\24\24\2l\2 \3\2\2\2\4\"\3\2\2\2\6*\3\2\2\2")
        buf.write("\b-\3\2\2\2\n9\3\2\2\2\f>\3\2\2\2\16B\3\2\2\2\20O\3\2")
        buf.write("\2\2\22V\3\2\2\2\24Z\3\2\2\2\26c\3\2\2\2\30h\3\2\2\2\32")
        buf.write("j\3\2\2\2\34l\3\2\2\2\36n\3\2\2\2 !\5\6\4\2!\3\3\2\2\2")
        buf.write("\"#\7\3\2\2#$\5\6\4\2$%\7\4\2\2%\5\3\2\2\2&)\5\b\5\2\'")
        buf.write(")\5\n\6\2(&\3\2\2\2(\'\3\2\2\2),\3\2\2\2*(\3\2\2\2*+\3")
        buf.write("\2\2\2+\7\3\2\2\2,*\3\2\2\2-.\5\24\13\2./\7\23\2\2/\t")
        buf.write("\3\2\2\2\60\61\5\22\n\2\61\62\7\23\2\2\62:\3\2\2\2\63")
        buf.write("\64\5\16\b\2\64\65\7\23\2\2\65:\3\2\2\2\66\67\5\20\t\2")
        buf.write("\678\7\23\2\28:\3\2\2\29\60\3\2\2\29\63\3\2\2\29\66\3")
        buf.write("\2\2\2:\13\3\2\2\2;<\5\36\20\2<=\7\22\2\2=?\3\2\2\2>;")
        buf.write("\3\2\2\2>?\3\2\2\2?@\3\2\2\2@A\5\30\r\2A\r\3\2\2\2BC\7")
        buf.write("\5\2\2CD\5\36\20\2DE\7\6\2\2EJ\5\f\7\2FG\7\7\2\2GI\5\f")
        buf.write("\7\2HF\3\2\2\2IL\3\2\2\2JH\3\2\2\2JK\3\2\2\2KM\3\2\2\2")
        buf.write("LJ\3\2\2\2MN\7\b\2\2N\17\3\2\2\2OP\7\5\2\2PR\5\36\20\2")
        buf.write("QS\5\30\r\2RQ\3\2\2\2ST\3\2\2\2TR\3\2\2\2TU\3\2\2\2U\21")
        buf.write("\3\2\2\2VW\7\t\2\2WX\5\24\13\2X\23\3\2\2\2Y[\5\26\f\2")
        buf.write("ZY\3\2\2\2[\\\3\2\2\2\\Z\3\2\2\2\\]\3\2\2\2]\25\3\2\2")
        buf.write("\2^d\5\30\r\2_`\7\6\2\2`a\5\24\13\2ab\7\b\2\2bd\3\2\2")
        buf.write("\2c^\3\2\2\2c_\3\2\2\2d\27\3\2\2\2ei\5\32\16\2fi\5\34")
        buf.write("\17\2gi\5\36\20\2he\3\2\2\2hf\3\2\2\2hg\3\2\2\2i\31\3")
        buf.write("\2\2\2jk\7\r\2\2k\33\3\2\2\2lm\t\2\2\2m\35\3\2\2\2no\7")
        buf.write("\21\2\2o\37\3\2\2\2\13(*9>JT\\ch")
        return buf.getvalue()


class VitaminCParser ( Parser ):

    grammarFileName = "VitaminC.g4"

    atn = ATNDeserializer().deserialize(serializedATN())

    decisionsToDFA = [ DFA(ds, i) for i, ds in enumerate(atn.decisionToState) ]

    sharedContextCache = PredictionContextCache()

    literalNames = [ "<INVALID>", "'{'", "'}'", "'#'", "'('", "','", "')'", 
                     "'var'", "<INVALID>", "<INVALID>", "<INVALID>", "<INVALID>", 
                     "<INVALID>", "<INVALID>", "<INVALID>", "<INVALID>", 
                     "':'", "';'" ]

    symbolicNames = [ "<INVALID>", "<INVALID>", "<INVALID>", "<INVALID>", 
                      "<INVALID>", "<INVALID>", "<INVALID>", "<INVALID>", 
                      "ShebangLine", "WS", "NL", "Number", "String", "Rune", 
                      "Comment", "Name", "COLON", "SEMI", "Symbol" ]

    RULE_program = 0
    RULE_block = 1
    RULE_chunk = 2
    RULE_stat = 3
    RULE_decl = 4
    RULE_constantArg = 5
    RULE_functionDirective = 6
    RULE_commandDirective = 7
    RULE_variable = 8
    RULE_expr = 9
    RULE_primary = 10
    RULE_constant = 11
    RULE_number = 12
    RULE_symbol = 13
    RULE_name = 14

    ruleNames =  [ "program", "block", "chunk", "stat", "decl", "constantArg", 
                   "functionDirective", "commandDirective", "variable", 
                   "expr", "primary", "constant", "number", "symbol", "name" ]

    EOF = Token.EOF
    T__0=1
    T__1=2
    T__2=3
    T__3=4
    T__4=5
    T__5=6
    T__6=7
    ShebangLine=8
    WS=9
    NL=10
    Number=11
    String=12
    Rune=13
    Comment=14
    Name=15
    COLON=16
    SEMI=17
    Symbol=18

    def __init__(self, input:TokenStream, output:TextIO = sys.stdout):
        super().__init__(input, output)
        self.checkVersion("4.7.1")
        self._interp = ParserATNSimulator(self, self.atn, self.decisionsToDFA, self.sharedContextCache)
        self._predicates = None



    class ProgramContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def chunk(self):
            return self.getTypedRuleContext(VitaminCParser.ChunkContext,0)


        def getRuleIndex(self):
            return VitaminCParser.RULE_program

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterProgram" ):
                listener.enterProgram(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitProgram" ):
                listener.exitProgram(self)




    def program(self):

        localctx = VitaminCParser.ProgramContext(self, self._ctx, self.state)
        self.enterRule(localctx, 0, self.RULE_program)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 30
            self.chunk()
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class BlockContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def chunk(self):
            return self.getTypedRuleContext(VitaminCParser.ChunkContext,0)


        def getRuleIndex(self):
            return VitaminCParser.RULE_block

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterBlock" ):
                listener.enterBlock(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitBlock" ):
                listener.exitBlock(self)




    def block(self):

        localctx = VitaminCParser.BlockContext(self, self._ctx, self.state)
        self.enterRule(localctx, 2, self.RULE_block)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 32
            self.match(VitaminCParser.T__0)
            self.state = 33
            self.chunk()
            self.state = 34
            self.match(VitaminCParser.T__1)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class ChunkContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def stat(self, i:int=None):
            if i is None:
                return self.getTypedRuleContexts(VitaminCParser.StatContext)
            else:
                return self.getTypedRuleContext(VitaminCParser.StatContext,i)


        def decl(self, i:int=None):
            if i is None:
                return self.getTypedRuleContexts(VitaminCParser.DeclContext)
            else:
                return self.getTypedRuleContext(VitaminCParser.DeclContext,i)


        def getRuleIndex(self):
            return VitaminCParser.RULE_chunk

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterChunk" ):
                listener.enterChunk(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitChunk" ):
                listener.exitChunk(self)




    def chunk(self):

        localctx = VitaminCParser.ChunkContext(self, self._ctx, self.state)
        self.enterRule(localctx, 4, self.RULE_chunk)
        self._la = 0 # Token type
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 40
            self._errHandler.sync(self)
            _la = self._input.LA(1)
            while (((_la) & ~0x3f) == 0 and ((1 << _la) & ((1 << VitaminCParser.T__2) | (1 << VitaminCParser.T__3) | (1 << VitaminCParser.T__6) | (1 << VitaminCParser.Number) | (1 << VitaminCParser.Name) | (1 << VitaminCParser.COLON) | (1 << VitaminCParser.Symbol))) != 0):
                self.state = 38
                self._errHandler.sync(self)
                token = self._input.LA(1)
                if token in [VitaminCParser.T__3, VitaminCParser.Number, VitaminCParser.Name, VitaminCParser.COLON, VitaminCParser.Symbol]:
                    self.state = 36
                    self.stat()
                    pass
                elif token in [VitaminCParser.T__2, VitaminCParser.T__6]:
                    self.state = 37
                    self.decl()
                    pass
                else:
                    raise NoViableAltException(self)

                self.state = 42
                self._errHandler.sync(self)
                _la = self._input.LA(1)

        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class StatContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def expr(self):
            return self.getTypedRuleContext(VitaminCParser.ExprContext,0)


        def SEMI(self):
            return self.getToken(VitaminCParser.SEMI, 0)

        def getRuleIndex(self):
            return VitaminCParser.RULE_stat

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterStat" ):
                listener.enterStat(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitStat" ):
                listener.exitStat(self)




    def stat(self):

        localctx = VitaminCParser.StatContext(self, self._ctx, self.state)
        self.enterRule(localctx, 6, self.RULE_stat)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 43
            self.expr()
            self.state = 44
            self.match(VitaminCParser.SEMI)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class DeclContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def variable(self):
            return self.getTypedRuleContext(VitaminCParser.VariableContext,0)


        def SEMI(self):
            return self.getToken(VitaminCParser.SEMI, 0)

        def functionDirective(self):
            return self.getTypedRuleContext(VitaminCParser.FunctionDirectiveContext,0)


        def commandDirective(self):
            return self.getTypedRuleContext(VitaminCParser.CommandDirectiveContext,0)


        def getRuleIndex(self):
            return VitaminCParser.RULE_decl

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterDecl" ):
                listener.enterDecl(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitDecl" ):
                listener.exitDecl(self)




    def decl(self):

        localctx = VitaminCParser.DeclContext(self, self._ctx, self.state)
        self.enterRule(localctx, 8, self.RULE_decl)
        try:
            self.state = 55
            self._errHandler.sync(self)
            la_ = self._interp.adaptivePredict(self._input,2,self._ctx)
            if la_ == 1:
                self.enterOuterAlt(localctx, 1)
                self.state = 46
                self.variable()
                self.state = 47
                self.match(VitaminCParser.SEMI)
                pass

            elif la_ == 2:
                self.enterOuterAlt(localctx, 2)
                self.state = 49
                self.functionDirective()
                self.state = 50
                self.match(VitaminCParser.SEMI)
                pass

            elif la_ == 3:
                self.enterOuterAlt(localctx, 3)
                self.state = 52
                self.commandDirective()
                self.state = 53
                self.match(VitaminCParser.SEMI)
                pass


        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class ConstantArgContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def constant(self):
            return self.getTypedRuleContext(VitaminCParser.ConstantContext,0)


        def name(self):
            return self.getTypedRuleContext(VitaminCParser.NameContext,0)


        def COLON(self):
            return self.getToken(VitaminCParser.COLON, 0)

        def getRuleIndex(self):
            return VitaminCParser.RULE_constantArg

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterConstantArg" ):
                listener.enterConstantArg(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitConstantArg" ):
                listener.exitConstantArg(self)




    def constantArg(self):

        localctx = VitaminCParser.ConstantArgContext(self, self._ctx, self.state)
        self.enterRule(localctx, 10, self.RULE_constantArg)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 60
            self._errHandler.sync(self)
            la_ = self._interp.adaptivePredict(self._input,3,self._ctx)
            if la_ == 1:
                self.state = 57
                self.name()
                self.state = 58
                self.match(VitaminCParser.COLON)


            self.state = 62
            self.constant()
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class FunctionDirectiveContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def name(self):
            return self.getTypedRuleContext(VitaminCParser.NameContext,0)


        def constantArg(self, i:int=None):
            if i is None:
                return self.getTypedRuleContexts(VitaminCParser.ConstantArgContext)
            else:
                return self.getTypedRuleContext(VitaminCParser.ConstantArgContext,i)


        def getRuleIndex(self):
            return VitaminCParser.RULE_functionDirective

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterFunctionDirective" ):
                listener.enterFunctionDirective(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitFunctionDirective" ):
                listener.exitFunctionDirective(self)




    def functionDirective(self):

        localctx = VitaminCParser.FunctionDirectiveContext(self, self._ctx, self.state)
        self.enterRule(localctx, 12, self.RULE_functionDirective)
        self._la = 0 # Token type
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 64
            self.match(VitaminCParser.T__2)
            self.state = 65
            self.name()
            self.state = 66
            self.match(VitaminCParser.T__3)
            self.state = 67
            self.constantArg()
            self.state = 72
            self._errHandler.sync(self)
            _la = self._input.LA(1)
            while _la==VitaminCParser.T__4:
                self.state = 68
                self.match(VitaminCParser.T__4)
                self.state = 69
                self.constantArg()
                self.state = 74
                self._errHandler.sync(self)
                _la = self._input.LA(1)

            self.state = 75
            self.match(VitaminCParser.T__5)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class CommandDirectiveContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def name(self):
            return self.getTypedRuleContext(VitaminCParser.NameContext,0)


        def constant(self, i:int=None):
            if i is None:
                return self.getTypedRuleContexts(VitaminCParser.ConstantContext)
            else:
                return self.getTypedRuleContext(VitaminCParser.ConstantContext,i)


        def getRuleIndex(self):
            return VitaminCParser.RULE_commandDirective

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterCommandDirective" ):
                listener.enterCommandDirective(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitCommandDirective" ):
                listener.exitCommandDirective(self)




    def commandDirective(self):

        localctx = VitaminCParser.CommandDirectiveContext(self, self._ctx, self.state)
        self.enterRule(localctx, 14, self.RULE_commandDirective)
        self._la = 0 # Token type
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 77
            self.match(VitaminCParser.T__2)
            self.state = 78
            self.name()
            self.state = 80 
            self._errHandler.sync(self)
            _la = self._input.LA(1)
            while True:
                self.state = 79
                self.constant()
                self.state = 82 
                self._errHandler.sync(self)
                _la = self._input.LA(1)
                if not ((((_la) & ~0x3f) == 0 and ((1 << _la) & ((1 << VitaminCParser.Number) | (1 << VitaminCParser.Name) | (1 << VitaminCParser.COLON) | (1 << VitaminCParser.Symbol))) != 0)):
                    break

        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class VariableContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def expr(self):
            return self.getTypedRuleContext(VitaminCParser.ExprContext,0)


        def getRuleIndex(self):
            return VitaminCParser.RULE_variable

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterVariable" ):
                listener.enterVariable(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitVariable" ):
                listener.exitVariable(self)




    def variable(self):

        localctx = VitaminCParser.VariableContext(self, self._ctx, self.state)
        self.enterRule(localctx, 16, self.RULE_variable)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 84
            self.match(VitaminCParser.T__6)
            self.state = 85
            self.expr()
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class ExprContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def primary(self, i:int=None):
            if i is None:
                return self.getTypedRuleContexts(VitaminCParser.PrimaryContext)
            else:
                return self.getTypedRuleContext(VitaminCParser.PrimaryContext,i)


        def getRuleIndex(self):
            return VitaminCParser.RULE_expr

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterExpr" ):
                listener.enterExpr(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitExpr" ):
                listener.exitExpr(self)




    def expr(self):

        localctx = VitaminCParser.ExprContext(self, self._ctx, self.state)
        self.enterRule(localctx, 18, self.RULE_expr)
        self._la = 0 # Token type
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 88 
            self._errHandler.sync(self)
            _la = self._input.LA(1)
            while True:
                self.state = 87
                self.primary()
                self.state = 90 
                self._errHandler.sync(self)
                _la = self._input.LA(1)
                if not ((((_la) & ~0x3f) == 0 and ((1 << _la) & ((1 << VitaminCParser.T__3) | (1 << VitaminCParser.Number) | (1 << VitaminCParser.Name) | (1 << VitaminCParser.COLON) | (1 << VitaminCParser.Symbol))) != 0)):
                    break

        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class PrimaryContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def constant(self):
            return self.getTypedRuleContext(VitaminCParser.ConstantContext,0)


        def expr(self):
            return self.getTypedRuleContext(VitaminCParser.ExprContext,0)


        def getRuleIndex(self):
            return VitaminCParser.RULE_primary

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterPrimary" ):
                listener.enterPrimary(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitPrimary" ):
                listener.exitPrimary(self)




    def primary(self):

        localctx = VitaminCParser.PrimaryContext(self, self._ctx, self.state)
        self.enterRule(localctx, 20, self.RULE_primary)
        try:
            self.state = 97
            self._errHandler.sync(self)
            token = self._input.LA(1)
            if token in [VitaminCParser.Number, VitaminCParser.Name, VitaminCParser.COLON, VitaminCParser.Symbol]:
                self.enterOuterAlt(localctx, 1)
                self.state = 92
                self.constant()
                pass
            elif token in [VitaminCParser.T__3]:
                self.enterOuterAlt(localctx, 2)
                self.state = 93
                self.match(VitaminCParser.T__3)
                self.state = 94
                self.expr()
                self.state = 95
                self.match(VitaminCParser.T__5)
                pass
            else:
                raise NoViableAltException(self)

        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class ConstantContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def number(self):
            return self.getTypedRuleContext(VitaminCParser.NumberContext,0)


        def symbol(self):
            return self.getTypedRuleContext(VitaminCParser.SymbolContext,0)


        def name(self):
            return self.getTypedRuleContext(VitaminCParser.NameContext,0)


        def getRuleIndex(self):
            return VitaminCParser.RULE_constant

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterConstant" ):
                listener.enterConstant(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitConstant" ):
                listener.exitConstant(self)




    def constant(self):

        localctx = VitaminCParser.ConstantContext(self, self._ctx, self.state)
        self.enterRule(localctx, 22, self.RULE_constant)
        try:
            self.state = 102
            self._errHandler.sync(self)
            token = self._input.LA(1)
            if token in [VitaminCParser.Number]:
                self.enterOuterAlt(localctx, 1)
                self.state = 99
                self.number()
                pass
            elif token in [VitaminCParser.COLON, VitaminCParser.Symbol]:
                self.enterOuterAlt(localctx, 2)
                self.state = 100
                self.symbol()
                pass
            elif token in [VitaminCParser.Name]:
                self.enterOuterAlt(localctx, 3)
                self.state = 101
                self.name()
                pass
            else:
                raise NoViableAltException(self)

        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class NumberContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def Number(self):
            return self.getToken(VitaminCParser.Number, 0)

        def getRuleIndex(self):
            return VitaminCParser.RULE_number

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterNumber" ):
                listener.enterNumber(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitNumber" ):
                listener.exitNumber(self)




    def number(self):

        localctx = VitaminCParser.NumberContext(self, self._ctx, self.state)
        self.enterRule(localctx, 24, self.RULE_number)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 104
            self.match(VitaminCParser.Number)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class SymbolContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def Symbol(self):
            return self.getToken(VitaminCParser.Symbol, 0)

        def COLON(self):
            return self.getToken(VitaminCParser.COLON, 0)

        def getRuleIndex(self):
            return VitaminCParser.RULE_symbol

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterSymbol" ):
                listener.enterSymbol(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitSymbol" ):
                listener.exitSymbol(self)




    def symbol(self):

        localctx = VitaminCParser.SymbolContext(self, self._ctx, self.state)
        self.enterRule(localctx, 26, self.RULE_symbol)
        self._la = 0 # Token type
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 106
            _la = self._input.LA(1)
            if not(_la==VitaminCParser.COLON or _la==VitaminCParser.Symbol):
                self._errHandler.recoverInline(self)
            else:
                self._errHandler.reportMatch(self)
                self.consume()
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx

    class NameContext(ParserRuleContext):

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def Name(self):
            return self.getToken(VitaminCParser.Name, 0)

        def getRuleIndex(self):
            return VitaminCParser.RULE_name

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterName" ):
                listener.enterName(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitName" ):
                listener.exitName(self)




    def name(self):

        localctx = VitaminCParser.NameContext(self, self._ctx, self.state)
        self.enterRule(localctx, 28, self.RULE_name)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 108
            self.match(VitaminCParser.Name)
        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx





