from .reporting import *
from .structure import *


def lambda_check_type(ctx: Context, args: Dict[str, Object], spec: Lambda):
    #if not isinstance(val, typ):
    #    raise SemError(err_pragma_arg_type(ctx, expr, arg, typ, type(val)))
    return True


def pragma_parse_expr(ctx: Context, expr: PragmaExpr, spec: Lambda) -> Dict[str, Object]:
    # check the number of positional arguments
    # check if key_arg and var_arg is after pos_args
    # check if key_arg is known
    # check if pragma is variadic
    # check if argument type matches
    args: Dict[str, Object] = {}

    if expr.argc < spec.arity:
        raise SemError(err_pragma_not_enough_args(ctx, spec.arity, expr.argc))

    if expr.argc > spec.fullarity and not spec.varargs:
        raise SemError(err_pragma_not_variadic(ctx))

    if spec.varargs:
        args[spec.varkey] = Object(T_ARRAY, [], literal=True)

    for i, arg in enumerate(expr.args):
        val = arg.val
        if arg.key:
            key = arg.key.mem
            if key not in spec.keywords:
                raise SemError(err_pragma_bad_key_arg(ctx, arg))
            if key in args:
                raise SemError(err_pragma_dup_key_arg(ctx, arg))
            args[key] = val
        elif spec.varargs and i >= spec.arity - 1:
            args[spec.varkey].mem.append(val)
        else:
            args[spec.keys[i]] = val

    for key, obj in spec.default.items():
        if key not in args:
            args[key] = obj

    lambda_check_type(ctx, args, spec)
    return args


def call_pragma(ctx: Context, expr: PragmaExpr, spec: Lambda):
    args = pragma_parse_expr(ctx, expr, spec)
    return spec.mem(ctx, args)
