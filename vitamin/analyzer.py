"""
This file contains functions checking if the semantics of an expression are valid.
"""

from typing import *
from .reporting import *
from .structure import *


def process_lambda_type(ctx: Context, spec: Lambda, name: str, args: Dict[str, Obj]):
    # todo: actually do type checking
    return True


def process_lambda_args(ctx: Context, spec: Lambda, name: str, args: List[LambdaArg]) -> Dict[str, Obj]:
    """
    Type checking needs to be done separately!
    """
    res: Dict[str, Obj] = {}

    P, K = spec.pos_count, spec.key_count
    p, k, v = 0, 0, 0

    if spec.variadic is not None:
        # todo: use a typed array
        res[spec.variadic] = Obj(T_ARRAY, [])

    for i, arg in enumerate(args):
        if p < P:
            # first parse only positional arguments
            if arg.is_keyword:
                raise SemError(err_lambda__argument_order(ctx, arg, spec))
            # no need to check bounds as p < P <= N
            res[spec.keywords[p]] = arg.val
            p += 1

        elif arg.is_keyword:
            # parse keyword arguments
            key = arg.key.mem
            if key not in spec.keywords:
                raise SemError(err_lambda__unknown_keyword(ctx, arg, spec))
            if key in res:
                raise SemError(err_lambda__duplicate_keyword(ctx, arg))
            res[key] = arg.val
            k += 1

        else:
            # parse variadic arguments
            if spec.variadic is None:
                raise SemError(err_lambda__not_variadic(ctx, arg))
            res[spec.variadic].mem.append(arg.val)
            v += 1

    if not p == P:
        raise SemError(err_lambda__pos_count_mismatch(ctx, p, P))

    if not 0 <= k <= K:
        raise SemError(err_lambda__key_count_mismatch(ctx, k, K))

    # now insert default arguments
    for param in spec.param:
        if param.key not in res:
            res[param.key] = param.val

    return res


def process_lambda(ctx, symbol: Obj, head: Obj, args: List[LambdaArg]) -> Optional[Dict[str, Obj]]:
    if not isinstance(symbol, Lambda):
        # todo: why not?
        raise SemError(err_unknown(ctx, f"Cannot apply non-function {symbol}"))

    try:
        args = process_lambda_args(ctx, symbol, symbol.name, args)
        # todo: do type checking here
        return args
    except SemError:
        return None
