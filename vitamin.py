#!/usr/bin/env python3

from vitamin.parser_antlr import parse_file
from vitamin.parser_expr import make_parser, parse
from vitamin.structure import *

import sys
from pprint import pprint
from typing import *


def main(argv):
    input_path = argv[1]
    print('reading', input_path)
    ast = parse_file(input_path)
    #pprint(ast.nodes)


    # operator tables
    groups = {}
    ops = []

    def d_load(args: List[AST]):
        pass

    def d_operatorgroup(args: List[AST]):
        name = args[0].value
        kind = args[1].value
        group = operatorgroup(name, kind)
        for arg in args[2:]:
            if arg.keyword.value == 'gt':
                group.gt = arg.value.value
            if arg.keyword.value == 'lt':
                group.lt = arg.value.value
        groups[name] = group

    def d_operator(args: List[Constant]):
        group = args[0].value
        names = [x.value for x in args[1:]]
        for name in names:
            ops.append(operator(group, name))

    directives = {
        'load': d_load,
        'operatorgroup': d_operatorgroup,
        'operator': d_operator,
    }

    # search top level
    for node in ast.nodes:
        if isinstance(node, Directive):
            if node.name.value in directives:
                directives[node.name.value](node.args)

    # process operator tables
    operatorgroup_order(groups)
    # now we have real operator tables!
    ops = operator_parse(groups, ops)
    # create a reusable expression parser
    expr_parser = make_parser(ops)

    for node in ast.nodes:
        if isinstance(node, ListExpr):
            print(parse(expr_parser, node))



if __name__ == '__main__':
    main(sys.argv)

