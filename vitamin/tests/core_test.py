import unittest

from vitamin.core import *
from vitamin.structure import Context, C_TRUE, C_FALSE


class TestCore(unittest.TestCase):

    def test_set(self):
        ctx = Context()
        core_eval(ctx, Set('x', C_TRUE))
        self.assertEqual(C_TRUE, ctx.get_slot('x'))

    def test_get(self):
        ctx = Context()
        ctx.set_slot('x', C_TRUE)
        self.assertEqual(C_TRUE, core_eval(ctx, Get('x')))

    def test_lambda(self):
        ctx = Context()
        expr = Call(Lambda(['x'], [C_TRUE]), [C_FALSE])
        self.assertEqual(C_TRUE, core_eval(ctx, expr))

    def test_lambda_shadow(self):
        ctx = Context()
        core_eval(ctx, Set('x', C_TRUE))
        local = core_eval(ctx, Call(Lambda(['x'], [Get('x')]), [C_FALSE]))
        globl = core_eval(ctx, Get('x'))
        self.assertEqual(C_FALSE, local)
        self.assertEqual(C_TRUE, globl)

    def test_lambda_leaks(self):
        ctx = Context()
        core_eval(ctx, Call(Lambda(['x'], [Set('x', Get('x'))]), [C_TRUE]))
        self.assertEqual(None, ctx.get_slot('x'))

    def test_cond_true(self):
        self.assertEqual(C_TRUE, core_eval(None, Cond(C_TRUE, C_TRUE, C_FALSE)))

    def test_cond_false(self):
        self.assertEqual(C_FALSE, core_eval(None, Cond(C_FALSE, C_TRUE, C_FALSE)))


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestCore)
    unittest.TextTestRunner(verbosity=2).run(suite)
