"""
"""

from typing import *
from copy import deepcopy
from .analyzer import process_lambda
from .analyzer import process_lambda_args
from .reporting import *
from .structure import *


def add_lambda(ctx, obj: Lambda):
    # add lambda to context
    ctx.scope.add_sym(obj.name, obj)
    return obj


def eval_block(ctx, obj: Expr):
    # evaluate block statement by statement
    ret = C_VOID
    for expr in obj.args:
        ctx.push_expr(expr)
        ret = eval_obj(ctx, expr)
        ctx.pop_expr()
    return ret


def eval_pragma(ctx, obj: Expr):
    head: Obj = obj.args[0]
    tail: List[LambdaArg] = obj.args[1:]
    spec = ctx.pragmas.get(head.mem, None)
    if spec is None:
        raise SemError(err_unknown_pragma(ctx, obj))
    args = process_lambda_args(ctx, spec, head.mem, tail)
    return spec.mem(ctx, args)


def eval_call(ctx, obj: Expr):
    head: Obj = obj.args[0]
    tail: List[LambdaArg] = obj.args[1:]

    if head.mem in ["quote", "'"]:
        assert (len(tail) == 1)
        return tail[0].val

    if head.mem == 'eval':
        assert (len(tail) == 1)
        return eval_obj(ctx, eval_obj(ctx, tail[0].val))

    tail_copy: List[LambdaArg] = deepcopy(tail)
    for i, arg in enumerate(tail):
        # todo: check context for assignment symbols
        assign = head.mem in [':=', '=', '+=', '*='] and i == 0
        shortc = head.mem in ['&&', '||']
        if not (assign or shortc):
            tail_copy[i].val = eval_obj(ctx, arg.val)

    args = ((sym, process_lambda(ctx, sym, head, tail_copy))
        for sym in ctx.scope.get_sym(head.mem))
    args = ((sym, arg) for sym, arg in args if arg is not None)
    symb, args = next(args, (None, None))

    if args is None:
        raise SemError(err_unknown_symbol(ctx, head))

    fun = symb.mem
    if isinstance(fun, Expr) and fun.head == ExprToken.Block:
        # this is an expression block
        ctx.push_scope()
        for key, arg in args.items():
            ctx.scope.add_sym(key, arg)
        res = eval_obj(ctx, fun)
        ctx.pop_scope()
        return res

    if hasattr(fun, '__call__'):
        # this is a built in function
        return fun(ctx, args)


def eval_atom(ctx: Context, obj: Obj):
    head = obj
    symbol = ctx.scope.get_sym_next(head.mem)
    if symbol is None:
        raise SemError(err_unknown_symbol(ctx, head))
    return symbol


def eval_obj(ctx: Context, obj: Obj):
    # todo: still need to check type of each arg (Tuple<Atom?, Obj>)
    if isinstance(obj, Lambda):
        return add_lambda(ctx, obj)
    elif isinstance(obj, Expr):
        if obj.head == ExprToken.Call:
            return eval_call(ctx, obj)
        elif obj.head == ExprToken.Pragma:
            return eval_pragma(ctx, obj)
        elif obj.head == ExprToken.Block:
            return eval_block(ctx, obj)
    elif isinstance(obj, Obj):
        if obj.typ == T_ATOM:
            return eval_atom(ctx, obj)
        elif obj.typ in [T_STRING_LITERAL, T_INT_LITERAL]:
            # convert literal to a literal convertible
            return obj
        else:
            return obj
    raise SemError(err_unknown(ctx, f"Cannot evluate object {obj}: {sexpr(obj)}"))
