#!/usr/bin/env python3

import sys
from os import path as path

from vitamin.corelib import *
from vitamin.interpreter import *
from vitamin.parser_antlr import parse_file
from vitamin.parser_expr import make_parser, parse
from vitamin.structure import *
from vitamin.utils import topological_sort


# todo: these should definitely be somewhere else

def operatorgroup_order(groups: Dict[str, OpGroupDir]) -> int:
    """
    Assigns a precedence to each group based on their relations.
    The precedence is an integer from range [1, inf).

    return_type: The highest precedence assigned
    """
    # TODO: Maybe check precedence relations without explicitly assigning precedence number
    graph = {name: [] for name in groups.keys()}
    for group in groups.values():
        if group.gt: graph[group.gt].append(group.name)
        if group.lt: graph[group.name].append(group.lt)
    order = topological_sort(graph)
    for i, group in enumerate(order):
        groups[group].prec = i + 1
    return len(order)


def pragma_operatorcompile(ctx: Context, args):
    operatorgroup_order(ctx.groups)
    ctx.ops = operator_parse(ctx.groups, ctx.opdirs)
    ctx.expr_parser = make_parser(ctx.ops)
    ctx.post_macro = True


def operator_parse(groups: Dict[str, OpGroupDir], ops: List[OpDir]) -> List[Op]:
    """
    Combines OpGroupDir and OpDir directives into Op ojects.
    """
    operators = []
    for directive in ops:
        group = groups[directive.group]
        for name in directive.names:
            op = Op(name, group.kind, group.prec)
            operators.append(op)
    return operators


def main(argv):
    sys.setrecursionlimit(10000)
    input_path = argv[1]
    ast = parse_file(input_path)

    ctx = Context()
    ctx.file = open(input_path)
    ctx.file_name = input_path
    ctx.path = [path.dirname(input_path)]
    ctx.scope = Scope({})
    ctx.ast = ast
    ctx.expr_parser = make_parser([])

    ctx.pragmas = {
        'operatorcompile': Lambda(
            'operatorcompile', pragma_operatorcompile, []),
        'operatorgroup': Lambda(
            'operatorgroup', pragma_operatorgroup,
            [('name', T_ATOM), ('kind', T_ATOM), ('gt', T_ATOM, C_NIL), ('lt', T_ATOM, C_NIL)]),
        'operator': Lambda(
            'operator', pragma_operator,
            [('group', T_ATOM), ('names', T_ATOM)], variadic='names'),
    }

    G_NUMERIC = Typ('T', gen=['T'])
    G_ANY = Typ('T', gen=['T'])

    import vitamin.core as core

    def add_fun(name, func, args, ret=T_VOID, var=None):
        obj = Lambda(name, func, args, returns=ret, variadic=var)
        ctx.scope.add_sym(name, obj)

    def add_sym(name, obj):
        ctx.scope.add_sym(name, obj)

    add_sym('true', C_TRUE)
    add_sym('false', C_FALSE)
    add_sym('nil', C_NIL)
    add_sym('Any', T_ANY)
    add_sym('Nothing', T_NOTHING)
    add_sym('()', T_VOID)
    add_sym('Expr', T_EXPR)
    add_sym('Atom', T_ATOM)
    add_sym('Int', T_INT)
    add_sym('Type', T_TYPE)
    add_sym('String', T_STRING)
    add_sym('StringLiteral', T_STRING_LITERAL)
    add_sym('IntLiteral', T_INT_LITERAL)
    add_sym('RealLiteral', T_REAL_LITERAL)

    add_fun('-', f_sub, [('x', T_INT), ('y', T_INT)], ret=T_INT)
    add_fun('-', f_neg, [('x', T_INT)], ret=T_INT)
    add_fun('=', f_assign, [('x', T_ATOM), ('y', G_ANY)], ret=G_ANY)
    add_fun(':=', f_declare, [('x', T_ATOM), ('y', T_ANY)], ret=G_ANY)
    add_fun('+', f_add, [('x', T_INT), ('y', T_INT)], ret=T_INT)
    add_fun('*', f_mul, [('x', T_INT), ('y', T_INT)], ret=T_INT)
    add_fun('==', f_equals, [('x', T_INT), ('y', T_INT)], ret=T_BOOL)
    add_fun('!', f_not, [('x', T_BOOL)], ret=T_BOOL)
    add_fun('&&', f_and, [('x', T_BOOL), ('y', T_BOOL)], ret=T_BOOL)
    add_fun('||', f_or, [('x', T_BOOL), ('y', T_BOOL)], ret=T_BOOL)
    add_fun('>', f_gt, [('x', T_INT), ('y', T_INT)], ret=T_BOOL)
    add_fun('typeof', f_typeof, [('x', T_ATOM)], ret=T_STRING)
    add_fun('printr', f_printr, [('x', T_STRING)])

    # start interpreting file (practically still compile time)
    ctx.post_macro = False
    ctx.node_index = 0
    while ctx.node_index < len(ctx.ast.args):
        expr = ctx.ast.args[ctx.node_index]

        try:
            ctx.push_expr(expr)
            ctx.expr_parser.ctx = ctx
            expr = ctx.ast.args[ctx.node_index] = parse(ctx.expr_parser, ctx.expr)
        except ParserError as e:
            print(e)
            ctx.node_index += 1
            continue
        finally:
            ctx.pop_expr()

        ctx.push_expr(expr)
        eval_transform(ctx, ctx.expr)
        try:
            pass
        except SemError as e:
            print(e)
            return 1
        finally:
            ctx.pop_expr()

        ctx.node_index += 1

    return 0


if __name__ == '__main__':
    main(['vitamin', 'sample/main.vc'])
