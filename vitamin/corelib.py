from os import path as path
from typing import *

from vitamin.parser_antlr import parse_file
from vitamin.reporting import *
from vitamin.structure import *
from vitamin.analyzer import *


def eval(ctx: Context, obj: Object):
    head_sym = None

    if isinstance(obj, Expr):
        head = obj.args[0]
        tail = obj.args[1:]
        head_sym = ctx.scope.symbols.get(head.mem, None)
        if head_sym is None:
            raise SemError(err_unknown_symbol(ctx, head))
        if not isinstance(head_sym, Lambda):
            raise SemError("Cannot apply non-function")

        args: List[Object] = []
        for i, arg in enumerate(tail):
            if i == 0 and head.mem in ['=', '+=', '*=']:
                args.append(arg)
            else:
                args.append(eval(ctx, arg))

        args_dict: Dict[str, Object] = {}
        for key, arg in zip(head_sym.keywords, args):
            args_dict[key] = arg

        # print(f"apply({head}, {', '.join(map(str, args))})")

        return head_sym.mem(ctx, args_dict)

        raise SemError(f"eval(Expr) not implemented")

    if isinstance(obj, Object):

        if obj.typ == T_ATOM:
            head = obj
            head_sym = ctx.scope.symbols.get(head.mem, None)
            if head_sym is None:
                raise SemError(err_unknown_symbol(ctx, head))

            return head_sym

        else:
            return obj

        raise SemError(f"eval(Object) not implemented")

    if isinstance(obj, PragmaExpr):
        spec = ctx.pragmas.get(obj.name, None)
        if spec is None:
            raise SemError(err_unknown_pragma(ctx, obj))
        return call_pragma(ctx, obj, spec)

    raise SemError(f"Cannot evluate object {obj}")


def f_assign(ctx, args: Dict[str, Object]):
    # check if symbol already exists
    # if yes, check if symbol is a variable and it's type matches
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    ctx.scope.symbols[lhs.mem] = eval(ctx, rhs)
    return rhs


def f_print(ctx, args: Dict[str, Object]):
    arg, = unpack_args(args, ['value'])
    res = eval(ctx, arg)
    print(res.mem)


def f_mul(ctx, args: Dict[str, Object]):
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    return Object(T_INT, eval(ctx, lhs).mem * eval(ctx, rhs).mem)


def f_add(ctx, args: Dict[str, Object]):
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    return Object(T_INT, eval(ctx, lhs).mem + eval(ctx, rhs).mem)


def pragma_operator(ctx: Context, args: Dict[str, Object]):
    group, names = unpack_args(args, ['group', 'names'])
    if group.mem not in ctx.groups:
        print(warn_unknown_operatorgroup(ctx, ctx.expr, group))
    for name in names.mem:
        obj = OpDir(group.mem, [name.mem])
        ctx.opdirs.append(obj)


def pragma_operatorgroup(ctx: Context, args: Dict[str, Object]):
    name, kind, gt, lt = unpack_args(args, ['name', 'kind', 'gt', 'lt'])
    if name in ctx.groups:
        print(warn_duplicate_operatorgroup(ctx, ctx.expr, name))
    obj = OpGroupDir(name.mem, kind.mem, gt=gt.mem, lt=lt.mem)
    ctx.groups[name.mem] = obj

# def d_load(ctx, file, node, args, kwargs, varargs):
#    file_path = args[0]
#    # drop string delimiters
#    file_path = file_path[1:-1]
#
#    # if we have a concrete path, just check if it exitsts
#    if path.dirname(file_path) and not path.isfile(file_path):
#        err_file_does_not_exist(file, node)
#        return
#
#    # otherwise we have to search for the file
#    found = []
#    for lpath in ctx.LPATH:
#        fp = path.join(lpath, file_path)
#        if path.isfile(fp):
#            found.append(fp)
#
#    if not found:
#        err_file_search_failed(file, node)
#        return
#
#    file_path = found[0]
#    with open(file_path) as f:
#        print('-- reading', file_path)
#        file_ast = parse_file(file_path)
#        for i, node in enumerate(file_ast.nodes):
#            ctx.ast.nodes.insert(ctx.current_node + i + 1, node)
