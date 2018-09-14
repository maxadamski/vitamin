"""
This file contains definitions of built-in functions and directives

They assume correct input, because if an error is encountered, they
will not get called at all. (The exception being eval)
"""

from .interpreter import *
from .analyzer import *


def f_assign(ctx, args: Dict[str, Obj]):
    # check if symbol already exists
    # if yes, check if symbol is a variable and it's type matches
    x, y = unpack_args(args, ['x', 'y'])
    symbol = ctx.scope.get_sym_next(x.mem)
    if symbol is None:
        raise SemError(err_eval__assign_undeclared(ctx))
    if symbol.constant:
        raise SemError(err_eval__assign_to_constant(ctx))
    symbol.mem = y.mem
    return symbol


def f_declare(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    if x.mem in ctx.scope.symbols:
        raise SemError(err_eval__redeclare_variable(ctx))
    ctx.scope.add_sym(x.mem, y)
    return y


def f_printr(ctx, args: Dict[str, Obj]):
    x, = unpack_args(args, ['x'])
    if isinstance(x, Expr):
        print(str(x), end='')
    else:
        print(x.mem, end='')
    return C_VOID


def f_mul(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    return Obj(T_INT, x.mem * y.mem)


def f_add(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    return Obj(T_INT, x.mem + y.mem)


def f_sub(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    return Obj(T_INT, x.mem - y.mem)


def f_typeof(ctx, args: Dict[str, Obj]):
    x, = unpack_args(args, ['x'])
    return Obj(T_ANY, x.typ)


def f_neg(ctx, args: Dict[str, Obj]):
    x, = unpack_args(args, ['x'])
    return Obj(T_INT, -x.mem)


def f_equals(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    return C_TRUE if x.mem == y.mem else C_FALSE


def f_gt(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    return C_TRUE if x.mem > y.mem else C_FALSE


def f_not(ctx, args: Dict[str, Obj]):
    x, = unpack_args(args, ['x'])
    return C_TRUE if x.mem == C_FALSE.mem else C_FALSE


def f_and(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    x = eval_obj(ctx, x)
    if x.mem == C_FALSE.mem: return C_FALSE
    y = eval_obj(ctx, y)
    return y.mem


def f_or(ctx, args: Dict[str, Obj]):
    x, y = unpack_args(args, ['x', 'y'])
    x = eval_obj(ctx, x)
    if x.mem == C_TRUE.mem: return C_TRUE
    y = eval_obj(ctx, y)
    return y.mem


def pragma_operator(ctx: Context, args: Dict[str, Obj]):
    group, names = unpack_args(args, ['group', 'names'])
    if group.mem not in ctx.groups:
        print(warn_pragma_operator_unknown_group(ctx, group))
    obj = OpDir(group.mem, [name.mem for name in names.mem])
    ctx.opdirs.append(obj)


def pragma_operatorgroup(ctx: Context, args: Dict[str, Obj]):
    name, kind, gt, lt = unpack_args(args, ['name', 'kind', 'gt', 'lt'])
    if name.mem in ctx.groups:
        print(warn_pragma_operatorgroup_duplicate(ctx, name))
    obj = OpGroupDir(name.mem, kind.mem, gt=gt.mem, lt=lt.mem)
    ctx.groups[name.mem] = obj

# todo: think aboot how #load should work

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
