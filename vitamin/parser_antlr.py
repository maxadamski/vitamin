
from .structure import *

from antlr4 import ParseTreeWalker, CommonTokenStream, FileStream, ParserRuleContext
from .parser.VitaminCLexer import VitaminCLexer
from .parser.VitaminCParser import VitaminCParser
from .parser.VitaminCListener import VitaminCListener

class ASTEmitter(VitaminCListener):
    def __init__(self, input_stream, token_stream):
        self.input_stream = input_stream
        self.token_stream = token_stream

    def context_source(self, ctx, hi = None):
        if isinstance(hi, ParserRuleContext): hi = hi.segment()
        is_one_line = ctx.stop.line - ctx.start.line == 0
        start, stop = ctx.start.start, ctx.stop.start
        source = self.input_stream.getText(start, stop)
        output = source_excerpt(source, ctx.segment(), hi=hi, hi_col=is_one_line)
        return output

    def enterProgram(self, ctx):
        ast = Program([])
        for child in ctx.chunk().getChildren():
            if isinstance(child, VitaminCParser.DeclContext):
                ast.nodes.append(self.emitDecl(child))
            if isinstance(child, VitaminCParser.StatContext):
                ast.nodes.append(self.emitStat(child))
        self.program = ast

    def emitStat(self, ctx):
        if ctx.expr():
            return self.emitExpr(ctx.expr())

    def emitDecl(self, ctx):
        if ctx.variable():
            return self.emitExpr(ctx.variable().expr())
        if ctx.functionDirective():
            return self.emitFunctionDirective(ctx.functionDirective())
        if ctx.commandDirective():
            return self.emitCommandDirective(ctx.commandDirective())

    def emitExpr(self, ctx):
        ast = ListExpr([])
        for primary in ctx.primary():
            if primary.constant():
                ast.nodes.append(self.emitConstant(primary.constant()))
            if primary.expr():
                ast.nodes.append(self.emitExpr(primary.expr()))
        return ast

    def emitFunctionDirective(self, ctx):
        name = self.emitName(ctx.name())
        ast = Directive(name, [])
        for arg in ctx.constantArg():
            val = self.emitConstant(arg.constant())
            if arg.name():
                key = self.emitName(arg.name())
                ast.args.append(KeywordArgument(key, val))
            else:
                ast.args.append(val)
        return ast

    def emitCommandDirective(self, ctx):
        name = self.emitName(ctx.name())
        args = [self.emitConstant(x) for x in ctx.constant()]
        return Directive(name, args)

    def emitConstant(self, ctx):
        if ctx.symbol():
            return self.emitSymbol(ctx.symbol())
        if ctx.name():
            return self.emitName(ctx.name())
        if ctx.number():
            return self.emitNumber(ctx.number())

    def emitSymbol(self, ctx):
        return Symbol(ctx.getText())

    def emitName(self, ctx):
        return Name(ctx.getText())


def parse_stream(input_stream):
    lexer = VitaminCLexer(input_stream)
    token_stream = CommonTokenStream(lexer)
    parser = VitaminCParser(token_stream)

    tree = parser.program()
    listener = ASTEmitter(input_stream, token_stream)
    walker = ParseTreeWalker()
    walker.walk(listener, tree)
    return listener.program


def parse_string(string):
    input_stream = InputStream(path)
    return parse_stream(input_stream)


def parse_file(path):
    input_stream = FileStream(path)
    return parse_stream(input_stream)

