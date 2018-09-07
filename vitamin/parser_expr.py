"""
A simple expression parser in Pratt style.

I wanted to implement Prolog's algorithm, but it was too hard to translate.
"""

from .structure import Token as ExprToken
from .reporting import *

from dataclasses import dataclass
from typing import *

EOF = 'EOF'


class UnexpectedToken(Exception):
    pass


class BadPrecedence(Exception):
    pass


@dataclass
class Token:
    key: str
    val: Object


@dataclass
class Null:
    # nud(parser: Parser, token: Token, rbp: Int) -> AST
    nud: Callable
    rbp: int
    nbp: int


@dataclass
class Left:
    # led(parser: Parser, token: Token, rbp: Int, left: AST) -> AST
    led: Callable
    lbp: int
    rbp: int
    nbp: int


#
# Generic Pratt style top-down parser
#

class Parser:
    def __init__(self):
        self.null, self.left = {}, {}
        self.add_null(EOF, null_error, 0)
        self.add_left(EOF, left_error, 0, 0)

    def parse(self, tokens):
        self.tokens = tokens
        self.token = self.next()
        return self.parse_until(0)

    def next(self):
        return next(self.tokens, Token(EOF, ''))

    # def expect(self, val):
    #    if not self.token.val == val:
    #        raise UnexpectedToken(f"expected {val}, got {self.token.val}")

    def parse_until(self, rbp):
        t = self.token
        self.token = self.next()

        if t.key == EOF:
            raise UnexpectedToken(t)

        null = self.null.get(t.key, None)

        if not null:
            raise UnexpectedToken(t)
        if not rbp <= null.nbp:
            raise BadPrecedence(t)

        ast = null.nud(self, t, null.rbp)
        nbp = self.inf_prec

        while True:
            t = self.token
            left = self.left.get(t.key, None)

            if not left:
                raise UnexpectedToken(t)
            if not left.lbp <= nbp:
                raise BadPrecedence(t)
            if t.key == EOF:
                break
            if not rbp <= left.lbp <= nbp:
                break

            self.token = self.next()
            ast = left.led(self, t, left.rbp, ast)
            nbp = left.nbp
        return ast

    def add_left(self, key, led, lbp, rbp, nbp=None):
        if not nbp: nbp = lbp
        self.left[key] = Left(led, lbp, rbp, nbp)

    def add_null(self, key, nud, rbp, nbp=None):
        if not nbp: nbp = rbp
        self.null[key] = Null(nud, rbp, nbp)


def null_error(p, token, rbp):
    raise UnexpectedToken(f"{token} can't be used as prefix")


def left_error(p, token, rbp, left):
    raise UnexpectedToken(f"{token} can't be used as infix")


# TODO: recalculate span for expr

def literal(p, t: Token, rbp):
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

LIT = 'LIT'


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


def parse(parser: Parser, expr: Expr):
    if parser is None: raise SemError(err_no_operators)
    if not isinstance(expr, Expr): raise ValueError(f'expr must be Expr')
    if not expr.args: return None
    tokens = []
    for child in expr.args:
        t = Token(LIT, child)
        if isinstance(child, Expr):
            t.val = parse(parser, child)
        elif isinstance(child, Object) and child.mem in parser.op_names:
            t.key = child.mem
        tokens.append(t)

    ast = parser.parse(iter(tokens))
    ast.span = expr.span
    return ast
