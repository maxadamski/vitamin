from vitamin.reporting import report, err_function_not_variadic
from .structure import *


def type_of(ast):
    return ast.typ


def types_match(typ, exp):
    if exp == CONSTANT:
        return typ in [SYMBOL, NAME, STRING, NUMBER]
    return typ == exp


def analyze_directive(spec, f_main, node: Directive):
    # x check number of positional arguments
    # x check if varargs are after positional arguments
    # x check if kwargs are after positional arguments
    # check if kwarg argument is known
    # check types of arguments

    # directive spec:
    args, kwargs, varargs = spec.args, spec.kwargs, spec.varargs
    # collect valid arguments
    out_args, out_kwargs, out_varargs = [], {}, []
    # count processed arguments
    n_args, n_kwargs, n_varargs = 0, 0, 0

    for arg in node.args:
        col = None  # pointer to argument destination
        key = None  # dict key if destination is dict
        val = None  # constant ast
        exp = None  # expected type of val

        if isinstance(arg, Constant) and n_args < len(args):
            exp = args[n_args]
            col = out_args
            val = arg
            n_args += 1

        elif isinstance(arg, Constant):
            exp = varargs
            col = out_varargs
            val = arg
            n_varargs += 1

            # check if we take varargs
            if not varargs:
                err_function_not_variadic(f_main, node, arg)
                error = True
                return False

        elif isinstance(arg, KeywordArgument):
            key = arg.keyword.mem
            col = out_kwargs
            val = arg.value
            n_kwargs += 1

            # check if kwarg argument is known
            if key not in kwargs:
                keys = ', '.join(kwargs.keys())
                print(f"-- UNKNOWN KEYWORD ARGUMENT")
                print(f"expected keyword argument in [{keys}] but got '{key}'")
                report(f_main, node, arg.keyword.span)
                return False

            exp = kwargs[key]

            # check if kwarg is not a duplicate
            if key in out_kwargs:
                print(f"-- DUPLICATE KEYWORD ARGUMENT")
                report(f_main, node, arg.keyword.span)
                return False

        typ = type_of(val)
        if not types_match(typ, exp):
            print(f"-- MISMATCHED TYPE")
            print(f"expected argument with type '{exp}' but got '{typ}'")
            report(f_main, node, arg.span)
            return False

        if key:
            col[key] = val.mem
        else:
            col.append(val.mem)

    if n_args < len(args):
        print(f"-- NOT ENOUGH ARGUMENTS")
        print(f"expected {len(args)} positional arguments but got {n_args}")
        report(f_main, node, node.span)
        return False

    return out_args, out_kwargs, out_varargs
