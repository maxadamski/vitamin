"""
"""

from typing import *
from copy import deepcopy
from .analyzer import process_lambda
from .analyzer import process_lambda_args
from .reporting import *
from .structure import *
import vitamin.core as core


def eval_pragma(ctx, obj: Expr):
    head: Obj = obj.args[0]
    tail: List[LambdaArg] = obj.args[1:]
    spec = ctx.pragmas.get(head.mem, None)
    if spec is None:
        raise SemError(err_unknown_pragma(ctx, obj))
    args = process_lambda_args(ctx, spec, head.mem, tail)
    return spec.mem(ctx, args)


def core_transform(ctx: Context, obj: Obj) -> Obj:
    if isinstance(obj, Expr):
        if obj.head == ExprToken.Call:
            head = obj.args[0]
            tail = [lambda_arg.val for lambda_arg in obj.args[1:]]
            is_assignment = head.mem in ['=', '+=', '-=', '*=', '/=']
            is_declaration = head.mem in [':=']
            is_cond = head.mem in ['cond']
            is_quote = head.mem in ['quote', '\'']

            if is_assignment:
                return core.Set(tail[0].mem, core_transform(ctx, tail[1]))
            if is_declaration:
                return core.Let(tail[0].mem, core_transform(ctx, tail[1]))

            args = [core_transform(ctx, arg) for arg in tail]

            if is_cond:
                return core.Cond(args[0], args[1], args[2])
            if is_quote:
                return core.Quote(args[0])

            return core.Call(core_transform(ctx, head), args)

        elif obj.head == ExprToken.Lambda:
            exprs = [core_transform(ctx, x) for x in obj.args[1].args]
            res = core.Lambda(obj.args[0], exprs)
            return res

        elif obj.head == ExprToken.Block:
            exprs = [core_transform(ctx, x) for x in obj.args]
            return core.Lambda([], exprs)

        elif obj.head == ExprToken.Pragma:
            eval_pragma(ctx, obj)

        else:
            raise SemError(err_unknown(ctx, f"Cannot evluate expr {obj}: {sexpr(obj)}"))

    elif isinstance(obj, Lambda):
        assert isinstance(obj.mem, Expr) and obj.mem.head == ExprToken.Block
        block = [core_transform(ctx, exp) for exp in obj.mem.args]
        return core.Set(obj.name, core.Lambda(obj.keywords, block))

    elif isinstance(obj, Obj):
        if obj.typ == T_ATOM:
            # append leaf to argument list
            return core.Get(obj.mem)
        elif isinstance(obj, LambdaArg):
            return obj.val
        else:
            return obj

    else:
        raise SemError(err_unknown(ctx, f"Cannot evluate object {obj}: {sexpr(obj)}"))


def eval_transform(ctx: Context, obj: Obj):
    code = core_transform(ctx, obj)
    if code is not None:
        core.core_eval(ctx, code)
