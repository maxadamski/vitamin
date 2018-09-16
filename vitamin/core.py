from dataclasses import dataclass, field
from enum import Enum, unique
from typing import *

from vitamin.structure import Context, C_TRUE, C_VOID, Obj
import vitamin.structure as structure
from vitamin.reporting import *


class CoreObj(Obj):
    def __init__(self):
        super().__init__(None, 'Expr')


class Expr(CoreObj):
    pass


class Decl(Expr):
    pass


@dataclass
class Call(Expr):
    head: Expr
    tail: List[Expr]


@dataclass
class Cond(Expr):
    cond: Expr
    if_t: Expr
    if_f: Expr


@dataclass
class Let(Decl):
    name: str
    expr: Expr


@dataclass
class Set(Expr):
    name: str
    expr: Expr


@dataclass
class Get(Expr):
    name: str


@dataclass
class Quote(Expr):
    expr: Expr


@dataclass
class Lambda(Expr):
    head: List[str]
    body: List[Expr]


def core_eval(ctx: Context, expr: Obj, tail_call=False) -> Obj:
    if isinstance(expr, Call):
        head = core_eval(ctx, expr.head)
        if isinstance(head, Lambda):
            assert len(head.head) == len(expr.tail)
            if not tail_call: ctx.push_scope()
            for arg, exp in zip(head.head, expr.tail):
                ctx.scope.let(arg, core_eval(ctx, exp))
            result = C_VOID
            N = len(head.body)
            for i, lambda_expr in enumerate(head.body):
                result = core_eval(ctx, lambda_expr, tail_call=i == N - 1)
            if not tail_call: ctx.pop_scope()
            return result
        elif isinstance(head, structure.Lambda):
            args = [core_eval(ctx, arg) for arg in expr.tail]
            return head.mem(ctx, dict(zip(head.keywords, args)))
        else:
            assert False
    elif isinstance(expr, Cond):
        result = core_eval(ctx, expr.cond)
        if result == C_TRUE:
            return core_eval(ctx, expr.if_t, tail_call=tail_call)
        else:
            return core_eval(ctx, expr.if_f, tail_call=tail_call)
    elif isinstance(expr, Let):
        name = expr.name[1:-1] if expr.name.startswith("`") else expr.name
        result = core_eval(ctx, expr.expr)
        ctx.scope.let(name, result)
        return result
    elif isinstance(expr, Set):
        name = expr.name[1:-1] if expr.name.startswith("`") else expr.name
        result = core_eval(ctx, expr.expr)
        status = ctx.scope.set(name, result)
        if status is None:
            raise SemError(err_unknown_symbol(ctx, ctx.expr) + f"({name})")
        return result
    elif isinstance(expr, Get):
        name = expr.name[1:-1] if expr.name.startswith("`") else expr.name
        result = ctx.scope.get(name)
        if result is None:
            raise SemError(err_unknown_symbol(ctx, ctx.expr) + f"({name})")
        return result
    elif isinstance(expr, Quote):
        return expr.expr
    elif isinstance(expr, Lambda):
        return expr
    elif isinstance(expr, Obj):  # A leaf value
        return expr

    assert False
