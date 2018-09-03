import unittest
from unittest import TestCase, main
from vitamin.structure import Op, AST, ExprLeaf, ExprNode, Constant
from vitamin.parser_expr import *

char2tokens = lambda s: [Constant(None, x) for x in s]
word2tokens = lambda s: [Constant(None, x) for x in s.split(' ')]

def parse2(parser: Parser, tokens: List[Constant]):
    if not tokens: return ExprLeaf(None, '')
    new_tokens = []
    for token in tokens:
        t = Token(LIT, token)
        if token.mem in parser.op_names:
            t.key = token.mem
        new_tokens.append(t)
    return parser.parse(iter(new_tokens))

def to_sexpr(ast: AST):
    if isinstance(ast, ExprLeaf):
        return f'{ast.head}'
    if isinstance(ast, ExprNode):
        tail = ' '.join(map(to_sexpr, ast.tail))
        return f'({ast.head} {tail})'


class TestExpression(TestCase):

    def assertParses(self, parser, tokens, sexpr):
        ast = to_sexpr(parse2(parser, tokens))
        self.assertEqual(ast, sexpr)

    def assertParsesBatch(self, parser, lexer, *pairs):
        for expr, sexpr in pairs:
            tokens = lexer(expr)
            self.assertParses(parser, tokens, sexpr)

    def assertParserError(self, parser, tokens, error):
        with self.assertRaises(error):
            parse2(parser, char2tokens(tokens))

    def assertBadPrecedence(self, parser, lexer, *tokens):
        for t in tokens:
            self.assertParserError(parser, t, BadPrecedence)


    fy_parser = make_parser([
        Op('3', 'fy', 3),
        Op('2', 'fy', 2),
        Op('1', 'fy', 1),
    ])

    fx_parser = make_parser([
        Op('3', 'fx', 3),
        Op('2', 'fx', 2),
        Op('1', 'fx', 1),
    ])

    yf_parser = make_parser([
        Op('3', 'yf', 3),
        Op('2', 'yf', 2),
        Op('1', 'yf', 1),
    ])

    yfx_parser = make_parser([
        Op('3', 'yfx', 3),
        Op('2', 'yfx', 2),
        Op('1', 'yfx', 1),
    ])

    xfy_parser = make_parser([
        Op('3', 'xfy', 3),
        Op('2', 'xfy', 2),
        Op('1', 'xfy', 1),
    ])

    xfx_parser = make_parser([
        Op('3', 'xfx', 3),
        Op('2', 'xfx', 2),
        Op('1', 'xfx', 1),
    ])

    unary_parser = make_parser([
        Op('6', 'yf', 6),
        Op('5', 'fy', 5),
        Op('4', 'yf', 4),
        Op('3', 'fy', 3),
        Op('2', 'yf', 2),
        Op('1', 'fy', 1),
    ])

    nonass_parser = make_parser([
        Op('+', 'yfx', 2),
        Op('=', 'xfx', 1),
    ])


    def test_null_parser(self):
        p = make_parser([])

        self.assertParsesBatch(p, char2tokens,
            ('', ''),
            ('x', 'x'),
        )

    def test_fy(self):
        self.assertParsesBatch(self.fy_parser, char2tokens,
            ('1x', '(1 x)'),
            ('2x', '(2 x)'),
            ('11x', '(1 (1 x))'),
            ('12x', '(1 (2 x))'),
            ('123x', '(1 (2 (3 x)))'),
        )

    def test_fy_restrictions(self):
        self.assertBadPrecedence(self.fy_parser, char2tokens,
            '21x',
            '121x',
        )

    def test_fx(self):
        self.assertParsesBatch(self.fx_parser, char2tokens,
            ('1x', '(1 x)'),
            ('2x', '(2 x)'),
            ('12x', '(1 (2 x))'),
            ('123x', '(1 (2 (3 x)))'),
        )

    def test_fx_restrictions(self):
        self.assertBadPrecedence(self.fx_parser, char2tokens,
            '11x',
            '21x',
            '121x',
        )

    def test_yf(self):
        self.assertParsesBatch(self.yf_parser, char2tokens,
            ('x1', '(1` x)'),
            ('x11', '(1` (1` x))'),
            ('x21', '(1` (2` x))'),
            ('x221', '(1` (2` (2` x)))'),
        )

    def test_yf_restrictions(self):
        self.assertBadPrecedence(self.yf_parser, char2tokens,
            'x12',
            'x323',
        )

    def test_unary(self):
        self.assertParsesBatch(self.unary_parser, char2tokens,
            ('1x2', '(1 (2` x))'),
            ('3x2', '(2` (3 x))'),
            ('1x42', '(1 (2` (4` x)))'),
            ('3x42', '(2` (3 (4` x)))'),
        )

    def test_yfx(self):
        self.assertParsesBatch(self.yfx_parser, char2tokens,
            ('x1y', '(1 x y)'),
            ('x2y', '(2 x y)'),
            ('x1y1z', '(1 (1 x y) z)'),
            ('x1y2z', '(1 x (2 y z))'),
            ('x2y1z', '(1 (2 x y) z)'),
        )

    def test_xfy(self):
        self.assertParsesBatch(self.xfy_parser, char2tokens,
            ('x1y', '(1 x y)'),
            ('x1y1z', '(1 x (1 y z))'),
            ('x1y2z', '(1 x (2 y z))'),
            ('x2y1z', '(1 (2 x y) z)'),
        )

    def test_xfx(self):
        self.assertParsesBatch(self.xfx_parser, char2tokens,
            ('x1y', '(1 x y)'),
            ('x1y2z', '(1 x (2 y z))'),
            ('a2b1c2d', '(1 (2 a b) (2 c d))'),
        )

    def test_xfx_restrictions(self):
        self.assertBadPrecedence(self.xfx_parser, char2tokens,
            'a1b1c',
            'a1b1c1d',
        )

    def test_same_name(self):
        p = make_parser([
            # declaring an infix and suffix operator with the same name is invalid
            #Op('-', 'yf', 2),
            Op('-', 'fy', 3),
            Op('-', 'yfx', 1),
        ])

        self.assertParsesBatch(p, char2tokens,
            ('x----y', '(- x (- (- (- y))))'),
            ('--x---y', '(- (- (- x)) (- (- y)))'),
        )

    def test_calculator(self):
        p = make_parser([
            Op('-', 'fy', 5), Op('+', 'fy', 5),
            Op('^', 'xfy', 4),
            Op('*', 'yfx', 3), Op('/', 'yfx', 3),
            Op('+', 'yfx', 2), Op('-', 'yfx', 2),
            Op('=', 'xfx', 1),
        ])

        self.assertParsesBatch(p, char2tokens,
            ('x--y', '(- x (- y))'),
            ('x^a+b', '(+ (^ x a) b)'),
            ('x^-x', '(^ x (- x))'),
            ('x=a+b*c', '(= x (+ a (* b c)))'),
            ('x*-y^z', '(* x (^ (- y) z))'),
        )

    def test_logic(self):
        p = make_parser([
            Op('==', 'xfx', 5), Op('!=', 'xfx', 5),
            Op('not', 'fy', 4),
            Op('and', 'yfx', 3),
            Op('or', 'yfx', 2),
        ])

        self.assertParsesBatch(p, word2tokens,
            ('x == y', '(== x y)'),
            ('not x == y', '(not (== x y))'),
            ('x == y and y != z', '(and (== x y) (!= y z))'),
            ('p and q and r', '(and (and p q) r)'),
            ('p and q or r and s', '(or (and p q) (and r s))'),
        )

    def xtest_ternary(self):
        p = make_parser([
            Op('-', 'fy', 2),
            Op('?_:_', 'x3y', 1),
        ])

        self.assertParsesBatch(p, char2tokens,
            ('p?t:f', '(? p t f)'),
            ('p?q?a:b:c', '(? p (? q a b) c)'),
            ('p?a:q?b:c', '(? p a (? q b c))'),
        )


if __name__ == '__main__':
    #p = make_parser([
    #    Op('^', 'xfy', 4),
    #    Op('*', 'yfx', 3),
    #    Op('+', 'yfx', 2),
    #    Op('2', 'yfx', 2),
    #    Op('1', 'yfx', 1),
    #    Op('=', 'xfx', 5),
    #])
    #print(parse(p, 'x=y=z'))

    suite = unittest.TestLoader().loadTestsFromTestCase(TestExpression)
    unittest.TextTestRunner(verbosity=2).run(suite)

