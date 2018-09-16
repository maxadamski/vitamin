from dataclasses import dataclass, field
from enum import Enum, unique
from typing import *

from vitamin.structure import Context, C_TRUE, C_VOID, Obj
import vitamin.structure as structure


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


def core_eval(ctx: Context, expr: Obj) -> Obj:
    if isinstance(expr, Call):
        head = core_eval(ctx, expr.head)
        if isinstance(head, Lambda):
            assert len(head.head) == len(expr.tail)
            ctx.push_scope()
            for arg, exp in zip(head.head, expr.tail):
                ctx.set_slot(arg, core_eval(ctx, exp))
            result = C_VOID
            for lambda_expr in head.body:
                result = core_eval(ctx, lambda_expr)
            ctx.pop_scope()
            return result
        elif isinstance(head, structure.Lambda):
            args = [core_eval(ctx, arg) for arg in expr.tail]
            return head.mem(ctx, dict(zip(head.keywords, args)))
        else:
            assert False
    elif isinstance(expr, Cond):
        result = core_eval(ctx, expr.cond)
        if result == C_TRUE:
            return core_eval(ctx, expr.if_t)
        else:
            return core_eval(ctx, expr.if_f)
    elif isinstance(expr, Let):
        result = core_eval(ctx, expr.expr)
        ctx.set_slot(expr.name, result)
        return result
    elif isinstance(expr, Set):
        result = core_eval(ctx, expr.expr)
        ctx.set_slot(expr.name, result)
        return result
    elif isinstance(expr, Get):
        result = ctx.get_slot(expr.name)
        return result
    elif isinstance(expr, Quote):
        return expr.expr
    elif isinstance(expr, Lambda):
        return expr
    else:  # A leaf value
        return expr
