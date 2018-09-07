# Generated from VitaminC.g4 by ANTLR 4.7.1
from antlr4 import *
if __name__ is not None and "." in __name__:
    from .VitaminCParser import VitaminCParser
else:
    from VitaminCParser import VitaminCParser

# This class defines a complete listener for a parse tree produced by VitaminCParser.
class VitaminCListener(ParseTreeListener):

    # Enter a parse tree produced by VitaminCParser#program.
    def enterProgram(self, ctx:VitaminCParser.ProgramContext):
        pass

    # Exit a parse tree produced by VitaminCParser#program.
    def exitProgram(self, ctx:VitaminCParser.ProgramContext):
        pass


    # Enter a parse tree produced by VitaminCParser#chunk.
    def enterChunk(self, ctx:VitaminCParser.ChunkContext):
        pass

    # Exit a parse tree produced by VitaminCParser#chunk.
    def exitChunk(self, ctx:VitaminCParser.ChunkContext):
        pass


    # Enter a parse tree produced by VitaminCParser#block.
    def enterBlock(self, ctx:VitaminCParser.BlockContext):
        pass

    # Exit a parse tree produced by VitaminCParser#block.
    def exitBlock(self, ctx:VitaminCParser.BlockContext):
        pass


    # Enter a parse tree produced by VitaminCParser#quote.
    def enterQuote(self, ctx:VitaminCParser.QuoteContext):
        pass

    # Exit a parse tree produced by VitaminCParser#quote.
    def exitQuote(self, ctx:VitaminCParser.QuoteContext):
        pass


    # Enter a parse tree produced by VitaminCParser#expr.
    def enterExpr(self, ctx:VitaminCParser.ExprContext):
        pass

    # Exit a parse tree produced by VitaminCParser#expr.
    def exitExpr(self, ctx:VitaminCParser.ExprContext):
        pass


    # Enter a parse tree produced by VitaminCParser#primary.
    def enterPrimary(self, ctx:VitaminCParser.PrimaryContext):
        pass

    # Exit a parse tree produced by VitaminCParser#primary.
    def exitPrimary(self, ctx:VitaminCParser.PrimaryContext):
        pass


    # Enter a parse tree produced by VitaminCParser#pragma.
    def enterPragma(self, ctx:VitaminCParser.PragmaContext):
        pass

    # Exit a parse tree produced by VitaminCParser#pragma.
    def exitPragma(self, ctx:VitaminCParser.PragmaContext):
        pass


    # Enter a parse tree produced by VitaminCParser#pragmaFun.
    def enterPragmaFun(self, ctx:VitaminCParser.PragmaFunContext):
        pass

    # Exit a parse tree produced by VitaminCParser#pragmaFun.
    def exitPragmaFun(self, ctx:VitaminCParser.PragmaFunContext):
        pass


    # Enter a parse tree produced by VitaminCParser#pragmaArg.
    def enterPragmaArg(self, ctx:VitaminCParser.PragmaArgContext):
        pass

    # Exit a parse tree produced by VitaminCParser#pragmaArg.
    def exitPragmaArg(self, ctx:VitaminCParser.PragmaArgContext):
        pass


    # Enter a parse tree produced by VitaminCParser#constant.
    def enterConstant(self, ctx:VitaminCParser.ConstantContext):
        pass

    # Exit a parse tree produced by VitaminCParser#constant.
    def exitConstant(self, ctx:VitaminCParser.ConstantContext):
        pass


    # Enter a parse tree produced by VitaminCParser#atom.
    def enterAtom(self, ctx:VitaminCParser.AtomContext):
        pass

    # Exit a parse tree produced by VitaminCParser#atom.
    def exitAtom(self, ctx:VitaminCParser.AtomContext):
        pass


    # Enter a parse tree produced by VitaminCParser#intn.
    def enterIntn(self, ctx:VitaminCParser.IntnContext):
        pass

    # Exit a parse tree produced by VitaminCParser#intn.
    def exitIntn(self, ctx:VitaminCParser.IntnContext):
        pass


    # Enter a parse tree produced by VitaminCParser#real.
    def enterReal(self, ctx:VitaminCParser.RealContext):
        pass

    # Exit a parse tree produced by VitaminCParser#real.
    def exitReal(self, ctx:VitaminCParser.RealContext):
        pass


    # Enter a parse tree produced by VitaminCParser#string.
    def enterString(self, ctx:VitaminCParser.StringContext):
        pass

    # Exit a parse tree produced by VitaminCParser#string.
    def exitString(self, ctx:VitaminCParser.StringContext):
        pass


