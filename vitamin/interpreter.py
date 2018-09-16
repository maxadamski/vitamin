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


def add_lambda(ctx, obj: Lambda):
    # add lambda to context
    ctx.scope.add_sym(obj.name, obj)
    return obj


def eval_block(ctx, obj: Expr):
    # evaluate block statement by statement
    ret = C_VOID
    N = len(obj.args)
    for i, expr in enumerate(obj.args):
        tail = i == N - 1
        ctx.push_expr(expr)
        # todo: also a tail call if is preceded by return
        ret = eval_obj(ctx, expr, tail_call=tail)
        ctx.pop_expr()
    return ret


def eval_call(ctx, obj: Expr, tail_call=False):
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
        # if is a tail call, mark local symbols as expired
        if not tail_call: ctx.push_scope()
        for key, arg in args.items():
            ctx.scope.set_sym(key, arg)
        res = eval_obj(ctx, fun)
        if not tail_call: ctx.pop_scope()
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


def eval_obj(ctx: Context, obj: Obj, tail_call=False):
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
    core.core_eval(ctx, core_transform(ctx, obj))
