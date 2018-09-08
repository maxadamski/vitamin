"""
This file contains definitions of built-in functions and directives

They assume correct input, because if an error is encountered, they
will not get called at all. (The exception being eval)

todo: move 'eval' to another file, and call it in 'f_eval'
"""

from .analyzer import *


def eval(ctx: Context, obj: Object):
    head_sym = None

    if isinstance(obj, Expr):
        head = obj.args[0]
        tail = obj.args[1:]
        head_sym = ctx.scope.symbols.get(head.mem, None)
        if head_sym is None:
            raise SemError(err_unknown_symbol(ctx, head))
        if isinstance(head_sym, list) and len(head_sym) > 0:
            # todo: actually resolve name conflict
            head_sym = head_sym[0]
        if not isinstance(head_sym, Lambda):
            # todo: why?
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

    if isinstance(obj, Object):

        if obj.typ == T_ATOM:
            head = obj
            head_sym = ctx.scope.symbols.get(head.mem, None)
            if head_sym is None:
                raise SemError(err_unknown_symbol(ctx, head))

            return head_sym

        else:
            return obj

    if isinstance(obj, PragmaExpr):
        spec = ctx.pragmas.get(obj.name, None)
        if spec is None:
            raise SemError(err_unknown_pragma(ctx, obj))
        return call_pragma(ctx, obj, spec)

    # todo: why?
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


def f_sub(ctx, args: Dict[str, Object]):
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    return Object(T_INT, eval(ctx, lhs).mem - eval(ctx, rhs).mem)


def f_neg(ctx, args: Dict[str, Object]):
    x, = unpack_args(args, ['x'])
    return Object(T_INT, -eval(ctx, x).mem)


def pragma_operator(ctx: Context, args: Dict[str, Object]):
    group, names = unpack_args(args, ['group', 'names'])
    if group.mem not in ctx.groups:
        print(warn_pragma_operator_unknown_group(ctx, ctx.expr, group))
    for name in names.mem:
        obj = OpDir(group.mem, [name.mem])
        ctx.opdirs.append(obj)


def pragma_operatorgroup(ctx: Context, args: Dict[str, Object]):
    name, kind, gt, lt = unpack_args(args, ['name', 'kind', 'gt', 'lt'])
    if name in ctx.groups:
        print(warn_pragma_operatorgroup_duplicate(ctx, ctx.expr, name))
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
