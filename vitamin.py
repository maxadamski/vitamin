#!/usr/bin/env python3

from vitamin.analyzer import *
from vitamin.corelib import *
from vitamin.parser_antlr import parse_file
from vitamin.parser_expr import make_parser, parse, ParserError
from vitamin.reporting import *
from vitamin.structure import *
from vitamin.utils import topological_sort

import os.path as path
import sys


def operatorgroup_order(groups: Dict[str, OpGroupDir]) -> int:
    """
    Assigns a precedence to each group based on their relations.
    The precedence is an integer from range [1, inf).

    returns: The highest precedence assigned
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
        'operatorcompile': Lambda(pragma_operatorcompile, []),
        'operatorgroup': Lambda(pragma_operatorgroup,
            [('name', T_ATOM), ('kind', T_ATOM), ('gt', T_ATOM, C_NIL), ('lt', T_ATOM, C_NIL)]),
        'operator': Lambda(pragma_operator,
            [('group', T_ATOM), ('names', T_ATOM)], varargs=True),
    }

    ctx.scope.symbols = {
        'true': C_TRUE,
        'false': C_FALSE,
        'nil': C_NIL,
        '()': T_VOID,
        'Expr': T_EXPR,
        'Atom': T_ATOM,
        'Any': T_ANY,
        'Int': T_INT,
        'StringLiteral': T_STRING_LITERAL,
        'IntLiteral': T_INT_LITERAL,
        'RealLiteral': T_REAL_LITERAL,
        '=': Lambda(f_assign,
            [('lhs', T_ATOM), ('rhs', T_INT)], returns=T_INT),
        '+': Lambda(f_add,
            [('lhs', T_INT), ('rhs', T_INT)], returns=T_INT),
        '*': Lambda(f_mul,
            [('lhs', T_INT), ('rhs', T_INT)], returns=T_INT),
        'print': Lambda(f_print,
            [('value', T_INT)]),
    }

    # start interpreting file
    ctx.node_index = 0
    while ctx.node_index < len(ctx.ast.args):
        ctx.expr = ctx.ast.args[ctx.node_index]

        try:
            ctx.expr_parser.ctx = ctx
            ctx.expr = ctx.ast.args[ctx.node_index] = parse(ctx.expr_parser, ctx.expr)
        except ParserError as e:
            print(e)
            ctx.node_index += 1
            continue

        try:
            eval(ctx, ctx.expr)
        except SemError as e:
            print(ctx.expr)
            print(e)
            return 1

        ctx.node_index += 1


if __name__ == '__main__':
    main(['vitamin', 'sample/main.vc'])
