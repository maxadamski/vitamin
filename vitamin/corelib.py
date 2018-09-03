from os import path as path

from vitamin.parser_antlr import parse_file
from vitamin.reporting import err_file_does_not_exist, err_file_search_failed, err_bad_operatorgroup, \
    warn_duplicate_operatorgroup, report
from vitamin.structure import operator, operatorgroup, ExprNode, Constant, SYMBOL, NAME, ExprLeaf, NUMBER


def eval(ctx, file, node):
    if isinstance(node, ExprNode):
        func, args = node.head, node.tail

        if isinstance(func, Constant) and func.typ in [SYMBOL, NAME]:
            sym = ctx.scope.symbols.get(func.mem, None)

            if not sym:
                print(f"-- UNKNOWN SYMBOL")
                print(f"'{func.mem}' is not a registered symbol")
                report(file, node, func.span)
                return

            ret_args = sym.builtin(ctx, file, ctx.scope, node, sym, args, {}, [])
            # TODO: what if we return one argument
            return ret_args

    if isinstance(node, ExprLeaf):
        value = node.head

        if value.typ in [NAME, SYMBOL]:
            return value.mem

        elif value.typ == NUMBER:
            return int(value.mem)

        else:
            report(file, node, node.span)
            raise ValueError('Cannot evaluate leaf!')


def d_load(ctx, file, node, args, kwargs, varargs):
    file_path = args[0]
    # drop string delimiters
    file_path = file_path[1:-1]

    # if we have a concrete path, just check if it exitsts
    if path.dirname(file_path) and not path.isfile(file_path):
        err_file_does_not_exist(file, node)
        return

    # otherwise we have to search for the file
    found = []
    for lpath in ctx.LPATH:
        fp = path.join(lpath, file_path)
        if path.isfile(fp):
            found.append(fp)

    if not found:
        err_file_search_failed(file, node)
        return

    file_path = found[0]
    with open(file_path) as f:
        print('-- reading', file_path)
        file_ast = parse_file(file_path)
        for i, node in enumerate(file_ast.nodes):
            ctx.ast.nodes.insert(ctx.current_node + i + 1, node)


def f_assign(ctx, file, scope, node, spec, pos_args, key_args, var_args):
    # check if symbol already exists
    # check if symbol type matches
    lhs, rhs = pos_args
    rhs = eval(ctx, file, rhs)
    ctx.scope.symbols[lhs.head.mem] = rhs


def f_print(ctx, file, scope, node, spec, pos_args, key_args, var_args):
    rhs = eval(ctx, file, pos_args[0])
    print(rhs)


def f_mul(ctx, file, scope, node, spec, pos_args, key_args, var_args):
    lhs = eval(ctx, file, pos_args[0])
    rhs = eval(ctx, file, pos_args[1])
    return lhs * rhs


def d_operator(ctx, file, node, args, kwargs, varargs):
    group = args[0]
    if group not in ctx.groups:
        err_bad_operatorgroup(file, node)
        return
    for name in varargs:
        ctx.opdirs.append(operator(group, [name]))


def d_operatorgroup(ctx, file, node, args, kwargs, varargs):
    name, kind = args
    gt, lt = kwargs.get('gt', None), kwargs.get('lt', None)
    group = operatorgroup(name, kind, gt=gt, lt=lt)
    if name in ctx.groups:
        warn_duplicate_operatorgroup(file, node)
    ctx.groups[name] = group
