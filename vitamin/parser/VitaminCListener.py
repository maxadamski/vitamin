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


    # Enter a parse tree produced by VitaminCParser#block.
    def enterBlock(self, ctx:VitaminCParser.BlockContext):
        pass

    # Exit a parse tree produced by VitaminCParser#block.
    def exitBlock(self, ctx:VitaminCParser.BlockContext):
        pass


    # Enter a parse tree produced by VitaminCParser#chunk.
    def enterChunk(self, ctx:VitaminCParser.ChunkContext):
        pass

    # Exit a parse tree produced by VitaminCParser#chunk.
    def exitChunk(self, ctx:VitaminCParser.ChunkContext):
        pass


    # Enter a parse tree produced by VitaminCParser#stat.
    def enterStat(self, ctx:VitaminCParser.StatContext):
        pass

    # Exit a parse tree produced by VitaminCParser#stat.
    def exitStat(self, ctx:VitaminCParser.StatContext):
        pass


    # Enter a parse tree produced by VitaminCParser#decl.
    def enterDecl(self, ctx:VitaminCParser.DeclContext):
        pass

    # Exit a parse tree produced by VitaminCParser#decl.
    def exitDecl(self, ctx:VitaminCParser.DeclContext):
        pass


    # Enter a parse tree produced by VitaminCParser#constantArg.
    def enterConstantArg(self, ctx:VitaminCParser.ConstantArgContext):
        pass

    # Exit a parse tree produced by VitaminCParser#constantArg.
    def exitConstantArg(self, ctx:VitaminCParser.ConstantArgContext):
        pass


    # Enter a parse tree produced by VitaminCParser#functionDirective.
    def enterFunctionDirective(self, ctx:VitaminCParser.FunctionDirectiveContext):
        pass

    # Exit a parse tree produced by VitaminCParser#functionDirective.
    def exitFunctionDirective(self, ctx:VitaminCParser.FunctionDirectiveContext):
        pass


    # Enter a parse tree produced by VitaminCParser#commandDirective.
    def enterCommandDirective(self, ctx:VitaminCParser.CommandDirectiveContext):
        pass

    # Exit a parse tree produced by VitaminCParser#commandDirective.
    def exitCommandDirective(self, ctx:VitaminCParser.CommandDirectiveContext):
        pass


    # Enter a parse tree produced by VitaminCParser#variable.
    def enterVariable(self, ctx:VitaminCParser.VariableContext):
        pass

    # Exit a parse tree produced by VitaminCParser#variable.
    def exitVariable(self, ctx:VitaminCParser.VariableContext):
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


    # Enter a parse tree produced by VitaminCParser#constant.
    def enterConstant(self, ctx:VitaminCParser.ConstantContext):
        pass

    # Exit a parse tree produced by VitaminCParser#constant.
    def exitConstant(self, ctx:VitaminCParser.ConstantContext):
        pass


    # Enter a parse tree produced by VitaminCParser#symbol.
    def enterSymbol(self, ctx:VitaminCParser.SymbolContext):
        pass

    # Exit a parse tree produced by VitaminCParser#symbol.
    def exitSymbol(self, ctx:VitaminCParser.SymbolContext):
        pass


    # Enter a parse tree produced by VitaminCParser#name.
    def enterName(self, ctx:VitaminCParser.NameContext):
        pass

    # Exit a parse tree produced by VitaminCParser#name.
    def exitName(self, ctx:VitaminCParser.NameContext):
        pass


    # Enter a parse tree produced by VitaminCParser#number.
    def enterNumber(self, ctx:VitaminCParser.NumberContext):
        pass

    # Exit a parse tree produced by VitaminCParser#number.
    def exitNumber(self, ctx:VitaminCParser.NumberContext):
        pass


    # Enter a parse tree produced by VitaminCParser#string.
    def enterString(self, ctx:VitaminCParser.StringContext):
        pass

    # Exit a parse tree produced by VitaminCParser#string.
    def exitString(self, ctx:VitaminCParser.StringContext):
        pass


