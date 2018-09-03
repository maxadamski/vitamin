#!/usr/bin/env python3

import os.path as path
import sys

from vitamin.analyzer import *
from vitamin.corelib import d_load, f_assign, f_print, f_mul, d_operator, d_operatorgroup, eval
from vitamin.parser_antlr import parse_file
from vitamin.parser_expr import make_parser, parse
from vitamin.reporting import *
from vitamin.structure import Function, Scope, Context, operatorgroup, operator, Op, DirectiveSpec
from vitamin.utils import topological_sort


def operatorgroup_order(groups: Dict[str, operatorgroup]) -> int:
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


def operator_parse(groups: Dict[str, operatorgroup], ops: List[operator]) -> List[Op]:
    """
    Combines operatorgroup and operator directives into Op ojects.
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
    print('-- reading', input_path)
    ast = parse_file(input_path)
    main = open(input_path)
    LPATH = [path.dirname(input_path)]

    ctx = Context()
    ctx.directives['operatorgroup'] = DirectiveSpec('operatorgroup', d_operatorgroup, [NAME, NAME],
                                                    {'gt': NAME, 'lt': NAME}, None)
    ctx.directives['operator'] = DirectiveSpec('operator', d_operator, [NAME], {}, CONSTANT)
    ctx.directives['load'] = DirectiveSpec('load', d_load, [STRING], {}, [])

    ctx.scope = Scope({})
    ctx.scope.symbols['print'] = Function('print', pos_args=[INT], builtin=f_print)
    ctx.scope.symbols['='] = Function('=', pos_args=[NAME], builtin=f_assign)
    ctx.scope.symbols['*'] = Function('*', pos_args=[INT, INT], ret_type=[INT], builtin=f_mul)

    # search top level
    ctx.LPATH = LPATH
    ctx.ast = ast
    ctx.current_node = 0
    while ctx.current_node < len(ast.nodes):
        node = ast.nodes[ctx.current_node]
        if isinstance(node, Directive):
            name = node.name.mem
            spec = ctx.directives.get(name, None)
            if not spec:
                err_bad_directive(main, node)

            args = analyze_directive(spec, main, node)
            # TODO: do something if spec fails
            if args: spec.call(ctx, main, node, *args)
        ctx.current_node += 1

    # process operator tables
    operatorgroup_order(ctx.groups)
    ctx.ops = operator_parse(ctx.groups, ctx.opdirs)
    ctx.expr_parser = make_parser(ctx.ops)

    # pprint(ast)
    print('\n-- start program')

    for i, node in enumerate(ast.nodes):
        if isinstance(node, ListExpr):
            # TODO: handle parse errors
            expr = ast.nodes[i] = parse(ctx.expr_parser, node)
            eval(ctx, main, expr)


if __name__ == '__main__':
    main(sys.argv)
