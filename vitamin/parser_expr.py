"""
A simple expression parser in Pratt style.

I wanted to implement Prolog's algorithm, but it was too hard to translate.
"""

from .structure import Fixity, Associativity, Expr, Op, Object, ExprToken, C_NIL
from .reporting import *

from dataclasses import dataclass
from typing import *

EOF = 'EOF'


class ParserError(Exception):
    pass


class UnexpectedToken(ParserError):
    pass


class BadPrecedence(ParserError):
    pass


@dataclass
class ParserToken:
    key: str
    val: Object


@dataclass
class Null:
    # nud(parser: Parser, token: ParserToken, rbp: Int) -> AST
    nud: Callable
    rbp: int
    nbp: int


@dataclass
class Left:
    # led(parser: Parser, token: ParserToken, rbp: Int, left: AST) -> AST
    led: Callable
    lbp: int
    rbp: int
    nbp: int


#
# Generic Pratt style top-down parser
#

class Parser:
    op_names: List[str]
    inf_prec: int
    lit_prec: int
    tokens: Iterator[ParserToken]
    history: List[ParserToken]
    token: ParserToken
    ctx: Context

    def __init__(self):
        self.null, self.left = {}, {}
        self.add_null(EOF, null_error, 0)
        self.add_left(EOF, left_error, 0, 0)
        self.tokens = None

    def parse(self, tokens):
        self.tokens = tokens
        self.history = []
        self.token = None
        self.advance()
        return self.parse_until(0)

    def next(self):
        return next(self.tokens, ParserToken(EOF, C_NIL))

    def advance(self):
        self.history.append(self.token)
        self.token = self.next()
        return self.token

    @property
    def last(self):
        return self.history[-1]

    # def expect(self, val):
    #    if not self.token.val == val:
    #        raise UnexpectedToken(f"expected {val}, got {self.token.val}")

    def parse_until(self, rbp):
        last = self.last
        t = self.token
        self.advance()

        if t.key == EOF:
            raise UnexpectedToken(t)

        null = self.null.get(t.key, None)

        if not null:
            raise UnexpectedToken(err_parser_null_unexpected_token(self.ctx, t))
        if not rbp <= null.nbp:
            raise BadPrecedence(err_parser_null_bad_precedence(self.ctx, t, last))

        ast = null.nud(self, t, null.rbp)
        nbp = self.inf_prec

        while True:
            last = self.last
            t = self.token
            left = self.left.get(t.key, None)

            if not left:
                raise UnexpectedToken(err_parser_left_unexpected_token(self.ctx, t))
            if not left.lbp <= nbp:
                raise BadPrecedence(err_parser_left_bad_precedence(self.ctx, t, last))
            if t.key == EOF:
                break
            if not rbp <= left.lbp <= nbp:
                break

            self.advance()
            ast = left.led(self, t, left.rbp, ast)
            nbp = left.nbp
        return ast

    def add_left(self, key, led, lbp, rbp, nbp=None):
        if not nbp: nbp = lbp
        self.left[key] = Left(led, lbp, rbp, nbp)

    def add_null(self, key, nud, rbp, nbp=None):
        if not nbp: nbp = rbp
        self.null[key] = Null(nud, rbp, nbp)


def null_error(p, t, rbp):
    raise UnexpectedToken(err_parser_null_not_registered(p.ctx, t))


def left_error(p, t, rbp, left):
    raise UnexpectedToken(err_parser_left_not_registered(p.ctx, t))


# TODO: recalculate span for expr

def literal(p, t: ParserToken, rbp):
    t.val.leaf = True
    return t.val


def infix(p, t, rbp, left):
    return Expr(ExprToken.Expr, [t.val, left, p.parse_until(rbp)], span=t.val.span)


def suffix(p, t, rbp, left):
    t.val.value += '`'
    return Expr(ExprToken.Expr, [t.val, left], span=t.val.span)


def prefix(p, t, rbp):
    return Expr(ExprToken.Expr, [t.val, p.parse_until(rbp)], span=t.val.span)


#
# Dynamic precedence parser
#

LIT = 'Literal'


def ternary(p, token, rbp, left):
    # _ ? _ : _
    a = p.parse_until(0)
    p.expect(':')
    p.token = p.next()
    b = p.parse_until(rbp)
    raise ValueError()
    # return ExprNode(token.val, left, a, b)


def make_parser(ops: List[Op]):
    max_prec = max(op.prec for op in ops) if ops else 0
    op_names = [op.name for op in ops]
    offset = 10
    max_prec += offset
    lit_prec = max_prec + 1
    inf_prec = lit_prec + 1

    p = Parser()
    p.inf_prec = inf_prec
    p.lit_prec = lit_prec
    p.op_names = op_names
    p.add_null(LIT, literal, lit_prec)

    for op in ops:
        prec = op.prec + offset
        # if op.fix == 'y3x':
        #    p.add_left(op.name, ternary, op.prec, op.prec)
        # if op.kind == 'x3y':
        #    p.add_left(op.name, ternary, op.prec, op.prec - 1)
        if op.fix == Fixity.INFIX and op.ass == Associativity.NONE:
            p.add_left(op.name, infix, prec, prec + 1, nbp=prec - 1)
        if op.fix == Fixity.INFIX and op.ass == Associativity.RIGHT:
            p.add_left(op.name, infix, prec, prec)
        if op.fix == Fixity.INFIX and op.ass == Associativity.LEFT:
            p.add_left(op.name, infix, prec, prec + 1)
        if op.fix == Fixity.PREFIX and op.ass == Associativity.RIGHT:
            p.add_null(op.name, prefix, prec)
        if op.fix == Fixity.PREFIX and op.ass == Associativity.NONE:
            p.add_null(op.name, prefix, prec, nbp=prec - 1)
        if op.fix == Fixity.SUFFIX:
            p.add_left(op.name, suffix, prec, prec)

    return p


def parse(parser: Parser, expr: Object):
    if isinstance(expr, Expr):
        if not expr.args:
            return None

        tokens = []
        for child in expr.args:
            t = ParserToken(LIT, child)
            if isinstance(child, Expr):
                t.val = parse(parser, child)
            elif isinstance(child, Object) and child.mem in parser.op_names:
                t.key = child.mem
            tokens.append(t)

        ast = parser.parse(iter(tokens))
        ast.span = expr.span
        return ast

    if isinstance(expr, Object):
        return Expr(ExprToken.Expr, [expr], expr.span)
