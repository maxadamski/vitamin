"""
This file contains the compatibility layer between the Antlr grammar and Vitamin's AST

The ASTEmitter is mostly redundant, as it only converts the Antlr AST to Vitamin's
representation. When a custom parser is written, it will output directly in Vitamin's AST,
and no other code besides `parse_string/file` functions, will have to be changed.
"""

from decimal import Decimal

from antlr4 import ParseTreeWalker, CommonTokenStream, FileStream, InputStream

from .parser.VitaminCLexer import VitaminCLexer
from .parser.VitaminCListener import VitaminCListener
from .parser.VitaminCParser import VitaminCParser
from .structure import *


def span(ctx):
    # TODO: what if expression ends in newlines
    if not ctx.stop: ctx.stop = ctx.start
    start = Loc(ctx.start.line, ctx.start.column + 1, ctx.start.start)
    end = Loc(ctx.stop.line, ctx.stop.column + 1, ctx.stop.stop)
    if ctx.start.line == ctx.stop.line:
        end.char = start.char + end.byte - start.byte + 1
    # print(start, end, ctx.getText())
    return Span(start, end)


def str2int(data: str) -> int:
    base = 10
    if data.startswith('0x'):
        base = 16
    elif data.startswith('0o'):
        base = 8
    elif data.startswith('0b'):
        base = 2
    return int(data, base)


class ASTEmitter(VitaminCListener):
    def __init__(self, input_stream, token_stream):
        self.input_stream = input_stream
        self.token_stream = token_stream
        self.ast = None

    def enterProgram(self, ctx: VitaminCParser.ProgramContext):
        self.ast = self.emitChunk(ctx.chunk())

    def emitChunk(self, ctx: VitaminCParser.ChunkContext):
        args = [self.emitExpr(x) for x in ctx.expr()]
        return Expr(ExprToken.Block, args, span(ctx))

    def emitBlock(self, ctx: VitaminCParser.BlockContext):
        return self.emitChunk(ctx.chunk())

    #def emitQuote(self, ctx: VitaminCParser.QuoteContext):
    #    expr = self.emitBlock(ctx.block())
    #    expr.head = ExprToken.Quote
    #    return expr

    def emitExpr(self, ctx: VitaminCParser.ExprContext):
        if ctx.primary():
            args = [self.emitPrimary(x) for x in ctx.primary()]
            return Expr(ExprToken.Unparsed, args, span(ctx))
        elif ctx.fun():
            return self.emitFun(ctx.fun())

    def emitPrimary(self, ctx: VitaminCParser.PrimaryContext):
        if ctx.constant():
            return self.emitConstant(ctx.constant())
        elif ctx.pragma():
            return self.emitPragma(ctx.pragma())
        elif ctx.block():
            return self.emitBlock(ctx.block())
        elif ctx.expr():
            return self.emitExpr(ctx.expr())
        elif ctx.call():
            return self.emitCall(ctx.call())

    def emitConstant(self, ctx: VitaminCParser.ConstantContext):
        if ctx.atom():
            return self.emitAtom(ctx.atom())
        elif ctx.intn():
            return self.emitIntn(ctx.intn())
        elif ctx.real():
            return self.emitReal(ctx.real())
        elif ctx.string():
            return self.emitString(ctx.string())
        elif ctx.word():
            return self.emitWord(ctx.word())

    # TODO: Revise the literal parsing functions

    def emitWord(self, ctx: VitaminCParser.AtomContext):
        text = ctx.getText().lower()
        if text == 'true':
            return C_TRUE
        if text == 'false':
            return C_FALSE
        if text == 'nil':
            return C_NIL

    def emitAtom(self, ctx: VitaminCParser.AtomContext):
        return Obj(T_ATOM, ctx.getText(), span=span(ctx))

    def emitIntn(self, ctx: VitaminCParser.IntnContext):
        data = ctx.getText().lower()
        return Obj(T_INT_LITERAL, str2int(data), span=span(ctx))

    def emitReal(self, ctx: VitaminCParser.RealContext):
        data = ctx.getText().lower()
        if data.startswith('0x'): raise NotImplemented()
        return Obj(T_REAL_LITERAL, Decimal(data), span=span(ctx))

    def emitString(self, ctx: VitaminCParser.StringContext):
        data = ctx.getText()
        if not data.startswith('"'): raise NotImplemented()
        data = data[1:-1].encode('utf-8').decode('unicode_escape')
        return Obj(T_STRING_LITERAL, data, span=span(ctx))

    def emitCall(self, ctx: VitaminCParser.CallContext):
        name = self.emitAtom(ctx.atom())
        expr = Expr(ExprToken.Call, [name], span(ctx))
        for arg in ctx.callArg():
            key = self.emitAtom(arg.atom()) if arg.atom() else None
            val = self.emitExpr(arg.expr())
            expr.args.append(LambdaArg(span(arg), val, key=key))
        return expr

    def emitFun(self, ctx: VitaminCParser.FunContext):
        name = self.emitAtom(ctx.atom())
        block = self.emitBlock(ctx.block())
        returns = self.emitTyp(ctx.typ()) if ctx.typ() else T_VOID

        # todo: detect which parameter is variadic
        params: List[LambdaParamTuple] = []
        for i, param in enumerate(ctx.funParam()):
            key = self.emitAtom(param.atom()).mem
            typ = self.emitTyp(param.typ())
            if param.expr():
                val = self.emitExpr(param.expr())
                params.append((key, typ, val))
            else:
                params.append((key, typ))

        expr = Lambda(name.mem, block, params, returns=returns)
        return expr

    def emitTyp(self, ctx: VitaminCParser.TypContext) -> Typ:
        atom = self.emitAtom(ctx.atom())
        return Typ(atom.mem, gen=[])

    def emitPragma(self, ctx: VitaminCParser.PragmaContext):
        name = self.emitAtom(ctx.atom())
        expr = Expr(ExprToken.Pragma, [name], span(ctx))
        if ctx.pragmaFun():
            for arg in ctx.pragmaFun().pragmaArg():
                key = self.emitAtom(arg.atom()) if arg.atom() else None
                val = self.emitConstant(arg.constant())
                arg = LambdaArg(span(arg), val, key=key)
                expr.args.append(arg)
        return expr


def parse_stream(input_stream):
    lexer = VitaminCLexer(input_stream)
    token_stream = CommonTokenStream(lexer)
    parser = VitaminCParser(token_stream)

    emitter = ASTEmitter(input_stream, token_stream)
    walker = ParseTreeWalker()
    walker.walk(emitter, parser.program())
    return emitter.ast


def parse_string(string):
    input_stream = InputStream(string)
    return parse_stream(input_stream)


def parse_file(path):
    input_stream = FileStream(path)
    return parse_stream(input_stream)
