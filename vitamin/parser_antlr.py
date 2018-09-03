"""
The ASTEmitter is mostly redundant, as it only converts the Antlr AST to Vitamin's
representation. It is important though, because when a custom parser will
be written, it will output directly in Vitamin's AST, and no other code
besides `parse_string/file` functions, will have to be changed.
"""

from .structure import *

from antlr4 import ParseTreeWalker, CommonTokenStream, FileStream, ParserRuleContext
from .parser.VitaminCLexer import VitaminCLexer
from .parser.VitaminCParser import VitaminCParser
from .parser.VitaminCListener import VitaminCListener

from pprint import pprint

def span(ctx):
    if not ctx.stop: ctx.stop = ctx.start
    start = Loc(ctx.start.line, ctx.start.column + 1, ctx.start.start)
    end = Loc(ctx.stop.line, ctx.stop.column + 1, ctx.stop.stop)
    if ctx.start.line == ctx.stop.line:
        end.char = start.char + end.byte - start.byte + 1
    #print(start, end, ctx.getText())
    return Span(start, end)

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
        ast = Program(span(ctx), [])
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
        ast = ListExpr(span(ctx), [])
        for primary in ctx.primary():
            if primary.constant():
                ast.nodes.append(self.emitConstant(primary.constant()))
            if primary.expr():
                ast.nodes.append(self.emitExpr(primary.expr()))
        return ast

    def emitFunctionDirective(self, ctx):
        name = self.emitName(ctx.name())
        ast = Directive(span(ctx), name, [])
        for arg in ctx.constantArg():
            val = self.emitConstant(arg.constant())
            if arg.name():
                key = self.emitName(arg.name())
                ast.args.append(KeywordArgument(span(arg), key, val))
            else:
                ast.args.append(val)
        return ast

    def emitCommandDirective(self, ctx):
        name = self.emitName(ctx.name())
        args = [self.emitConstant(x) for x in ctx.constant()]
        return Directive(span(ctx), name, args)

    def emitConstant(self, ctx):
        if ctx.symbol():
            return self.emitSymbol(ctx.symbol())
        if ctx.name():
            return self.emitName(ctx.name())
        if ctx.number():
            return self.emitNumber(ctx.number())
        if ctx.string():
            return self.emitString(ctx.string())

    def emitString(self, ctx):
        return Constant(span(ctx), ctx.getText(), STRING)

    def emitNumber(self, ctx):
        return Constant(span(ctx), ctx.getText(), NUMBER)

    def emitSymbol(self, ctx):
        return Constant(span(ctx), ctx.getText(), SYMBOL)

    def emitName(self, ctx):
        return Constant(span(ctx), ctx.getText(), NAME)


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

