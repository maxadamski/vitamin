"""
A simple expression parser in Pratt style.

I wanted to implement Prolog's algorithm, but it was too hard to translate.
"""

from .reporting import *

LIT = 'Literal'
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
    val: Obj


@dataclass
class Null:
    # fun nud(parser: Parser, token: ParserToken, rbp: Int) -> AST
    nud: Callable[['Parser', ParserToken, int], Expr]
    rbp: int
    nbp: int


@dataclass
class Left:
    # fun led(parser: Parser, token: ParserToken, rbp: Int, left: AST) -> AST
    led: Callable[['Parser', ParserToken, int, Expr], Expr]
    lbp: int
    rbp: int
    nbp: int


# Generic Pratt style top-down parser

class Parser:
    op_names: List[str]
    inf_prec: int
    lit_prec: int
    tokens: Iterator[ParserToken]
    history: List[ParserToken]
    token: ParserToken
    ctx: Context

    @property
    def last(self):
        return self.history[-1]

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

    def parse_until(self, rbp) -> Expr:
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
        self.left[key] = Left(led, lbp, rbp, nbp if nbp else lbp)

    def add_null(self, key, nud, rbp, nbp=None):
        self.null[key] = Null(nud, rbp, nbp if nbp else rbp)


# Operator led and nud implementation

def null_error(p, t, rbp):
    raise UnexpectedToken(err_parser_null_not_registered(p.ctx, t))


def left_error(p, t, rbp, left):
    raise UnexpectedToken(err_parser_left_not_registered(p.ctx, t))


# TODO: recalculate (sum) span for expr
# TODO: n-ary chaining operators like 'x > y > z'
# TODO: left mixfix operators like 'x ? y : z'
# TODO: null mixfix operators like 'if x then y else z'

def literal(p, t: ParserToken, rbp):
    t.val.leaf = True
    return t.val


def prefix(p, t: ParserToken, rbp):
    rhs = p.parse_until(rbp)
    args = [t.val, LambdaArg(rhs.span, rhs)]
    return Expr(ExprToken.Call, args, span=t.val.span)


def infix(p, t, rbp, left):
    lhs, rhs = left, p.parse_until(rbp)
    args = [t.val, LambdaArg(lhs.span, lhs), LambdaArg(rhs.span, rhs)]
    return Expr(ExprToken.Call, args, span=t.val.span)


def suffix(p, t, rbp, left):
    t.val.value += '`'
    args = [t.val, LambdaArg(left.span, left)]
    return Expr(ExprToken.Call, args, span=t.val.span)


# def ternary(p, token, rbp, left):
#    # _ ? _ : _
#    a = p.parse_until(0)
#    p.expect(':')
#    p.token = p.next()
#    b = p.parse_until(rbp)
#    return ExprToken(ExprToken.Expr, [token.val, left, a, b])


# Dynamic precedence parser

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
        # if op.fix == 'y3x': # ternary left associative operator
        #    p.add_left(op.name, ternary, op.prec, op.prec)
        # if op.kind == 'x3y': # ternary right associative operator
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


def parse(parser: Parser, expr: Obj):
    if isinstance(expr, Expr):
        if expr.head == ExprToken.Pragma:
            return expr
        if not expr.args:
            return None

        tokens = []
        for child in expr.args:
            t = ParserToken(LIT, child)
            if isinstance(child, Expr):
                t.val = parse(parser, child)
            elif isinstance(child, Obj) and child.mem in parser.op_names:
                t.key = child.mem
            tokens.append(t)

        ast = parser.parse(iter(tokens))
        ast.span = expr.span
        return ast

    if isinstance(expr, Obj):
        return Expr(ExprToken.Expr, [expr], expr.span)
