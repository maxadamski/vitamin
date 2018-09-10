"""
This file contains definitions of built-in functions and directives

They assume correct input, because if an error is encountered, they
will not get called at all. (The exception being eval)

todo: first finish eval
todo: move 'eval' to another file, and call from here it in 'f_eval'
"""

from .analyzer import *


def eval(ctx: Context, obj: Obj):
    head_sym = None

    if isinstance(obj, Expr) and obj.head == ExprToken.Pragma:
        head, args = obj.args[0], obj.args[1:]
        spec = ctx.pragmas.get(head.mem, None)
        if spec is None:
            raise SemError(err_unknown_pragma(ctx, obj))
        # todo: still need to check type of each arg (Tuple<Atom?, Obj>)
        args = process_lambda_args(ctx, spec, head.mem, args)
        return spec.mem(ctx, args)

    elif isinstance(obj, Expr) and obj.head == ExprToken.Call:
        head, args = obj.args[0], obj.args[1:]
        head_sym = ctx.scope.symbols.get(head.mem, None)
        if head_sym is None:
            raise SemError(err_unknown_symbol(ctx, head))
        if isinstance(head_sym, list) and len(head_sym) > 0:
            # todo: actually resolve name conflict
            head_sym = head_sym[0]
        if not isinstance(head_sym, Lambda):
            # todo: why?
            raise SemError("Cannot apply non-function")

        for i, arg in enumerate(args):
            # fixme: this is kinda sloppy
            is_assignment = i == 0 and head.mem in ['=', '+=', '*=']
            if not is_assignment:
                args[i].val = eval(ctx, arg.val)
        args_dict = process_lambda_args(ctx, head_sym, head.mem, args)
        # todo: do type checking here
        return head_sym.mem(ctx, args_dict)

    elif isinstance(obj, Obj):
        if obj.typ == T_ATOM:
            head = obj
            head_sym = ctx.scope.symbols.get(head.mem, None)
            if head_sym is None:
                raise SemError(err_unknown_symbol(ctx, head))

            return head_sym

        else:
            return obj

    # fixme: write an informative generic message in reporting
    raise SemError(f"Cannot evluate object {obj}")


def f_assign(ctx, args: Dict[str, Obj]):
    # check if symbol already exists
    # if yes, check if symbol is a variable and it's type matches
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    ctx.scope.symbols[lhs.mem] = eval(ctx, rhs)
    return rhs


def f_print(ctx, args: Dict[str, Obj]):
    arg, = unpack_args(args, ['value'])
    res = eval(ctx, arg)
    print(res.mem)


def f_mul(ctx, args: Dict[str, Obj]):
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    return Obj(T_INT, eval(ctx, lhs).mem * eval(ctx, rhs).mem)


def f_add(ctx, args: Dict[str, Obj]):
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    return Obj(T_INT, eval(ctx, lhs).mem + eval(ctx, rhs).mem)


def f_sub(ctx, args: Dict[str, Obj]):
    lhs, rhs = unpack_args(args, ['lhs', 'rhs'])
    return Obj(T_INT, eval(ctx, lhs).mem - eval(ctx, rhs).mem)


def f_neg(ctx, args: Dict[str, Obj]):
    x, = unpack_args(args, ['x'])
    return Obj(T_INT, -eval(ctx, x).mem)


def pragma_operator(ctx: Context, args: Dict[str, Obj]):
    group, names = unpack_args(args, ['group', 'names'])
    if group.mem not in ctx.groups:
        print(warn_pragma_operator_unknown_group(ctx, ctx.expr, group))
    obj = OpDir(group.mem, [name.mem for name in names.mem])
    ctx.opdirs.append(obj)


def pragma_operatorgroup(ctx: Context, args: Dict[str, Obj]):
    name, kind, gt, lt = unpack_args(args, ['name', 'kind', 'gt', 'lt'])
    if name.mem in ctx.groups:
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
