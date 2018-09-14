"""
This file provides the means to generate error messages

The message functions return a string generated by 'err_template'
Each error message function begins with 'err_'
Each warning message function begins with 'warn_'
"""

from .structure import *

RED = "\x1B[31m"
GRN = "\x1B[32m"
YEL = "\x1B[33m"
BLU = "\x1B[34m"
MAG = "\x1B[35m"
CYN = "\x1B[36m"
WHT = "\x1B[37m"
RST = "\x1B[0m"


# Generating the error message

def excerpt(f, span):
    """Returns excerpt from the file including the beggining of the line"""
    f.seek(span.start.byte)
    offset = 0
    while f.read(1) != '\n':
        f.seek(span.start.byte - offset)
        offset += 1
    return f.read(len(span) + offset)


def report(f, ast, hi=None):
    """
    The 'report' function automatically decides on the
    error highlighting style, and applies it to the source code.
    """
    if hi is None: hi = ast.span
    hi_lines = hi.stop.line - hi.start.line + 1
    t = excerpt(f, ast.span)
    return decorated(t, ast.span, hi=hi, hi_col=hi_lines == 1)


def formatted_line(line: str, y_fmt: str):
    """
    Prepend a line number (already formatted) to a line of code
    """
    return f"{y_fmt}|  {line}"


def highlight_row(hi: Span, line: str, y: int, y_fmt: str):
    """
    Prepend a line number (already formatted) to a line of code
    Also insert a red arrow if the whole line is erroneous
    """
    arrow = " "
    if hi.start.line <= y <= hi.stop.line:
        arrow = f"{RED}>{RST}"
    return f"{y_fmt}|{arrow} {line}"


def highlight_col(hi: Span, line: str, y: int, y_fmt: str):
    """
    Prepend a line number (already formatted) to a line of code
    Also insert red arrows under the erroneous part of the line
    """
    # text lines and columns are 1-indexed
    hx0, hx1 = hi.start.char - 1, hi.stop.char - 1
    hy0, hy1 = hi.start.line, hi.stop.line

    pad, red = 0, 0
    if y == hy0 == hy1:
        pad, red = hx0, hx1 - hx0
    elif y == hy0:
        pad, red = hx0, len(line) - hx0
    elif y == hy1:
        red = hx1
    elif hy0 < y < hy1:
        red = len(line)

    squiggles = ' ' * pad + '^' * red
    if not squiggles: return ''

    y_fmt = ' ' * len(y_fmt)
    return f"{y_fmt}   {RED}{squiggles}{RST}"


def decorated(source: str, span: Span, hi=None, hi_col=True):
    """
    By decoration I mean the pretty line numbers,
    red underlines under errors and
    arrows to the right of the line number
    """
    max_digits = len(str(span.stop.line))
    y = span.start.line
    output = ''
    for i, line in enumerate(source.splitlines()):
        y_fmt = str(y).zfill(max_digits)
        if hi is None:
            output += formatted_line(line, y_fmt)
        elif hi_col:
            output += formatted_line(line, y_fmt) + '\n'
            output += highlight_col(hi, line, y, y_fmt)
        else:
            output += highlight_row(hi, line, y, y_fmt)
        output += '\n'
        y += 1
    return output


def err_template(ctx, expr, hi, header, description, hints=None):
    """
    The 'err_template' combines the decorated code,
    an error title (and maybe id number?),
    error description, and hints.
    Finally the complete human readable message is returned.
    """
    code = report(ctx.file, expr, hi=hi)
    header = f"-- {header.upper()} "
    file = f" [{ctx.file_name}:{expr.span.start.line}:{expr.span.start.char}]"
    padding = "-" * (80 - len(header) - len(file))
    result = f"{header}{padding}{file}\n\n{description}\n\n{code}"
    if hints:
        result += "\n"
        for hint in hints:
            fmt = '\n      '.join(hint.split('\n'))
            result += f"hint: {fmt}\n"
    return result


# Error messages

def err_parser_null_unexpected_token(ctx: Context, t):
    return err_template(
        ctx, ctx.expr, t.val.span, "parser error",
        f"expected a primary or prefix operator, but got {t.val.typ} '{t.val.mem}'")


def err_parser_left_unexpected_token(ctx: Context, t):
    return err_template(
        ctx, ctx.expr, t.val.span, "parser error",
        f"expected an infix or suffix operator, but got {t.val.typ} '{t.val.mem}'")


def err_parser_null_bad_precedence(ctx: Context, t, last):
    message = \
        f"violated precedence contract: '{t.key}' cannot follow '{last.key}' in this context.\n" + \
        f"check operator associativity and precedence relations to debug this error."
    hints = [
        f"a prefix operator of higher precedence precedes a prefix operator of lower precedence.\n" +
        f"fix trivially by reversing the operator order",
        f"the same non-associative prefix operator may be used in succession.\n" +
        f"fix trivially by putting the subexpression in parentheses"
    ]
    return err_template(
        ctx, ctx.expr, t.val.span, "parser error", message, hints=hints)


def err_parser_left_bad_precedence(ctx: Context, t, last):
    message = \
        f"violated precedence contract: '{t.key}' cannot appear in this context.\n" + \
        f"check operator associativity and precedence relations to debug this error."

    hints = [
        f"the same non-associative infix/suffix operator may be used in succession\n" +
        f"fix trivially by putting the subexpression in parentheses"
    ]
    return err_template(
        ctx, ctx.expr, t.val.span, "parser error", message, hints=hints)


def err_parser_null_not_registered(ctx: Context, t):
    return err_template(
        ctx, ctx.expr, t.val.span, "parser error",
        f"'{t.key}' can't be used as a prefix operator")


def err_parser_left_not_registered(ctx: Context, t):
    return err_template(
        ctx, ctx.expr, t.val.span, "parser error",
        f"'{t.key}' can't be used as a infix or suffix operator")


def err_pragma_load_search_failed(ctx, hi: Obj, file_path: str):
    return err_template(ctx, ctx.expr, hi.span, "file error",
        f"file '{file_path}' could not be found")


def err_pragma_load_file_does_not_exist(ctx, hi: Obj, file_path: str):
    return err_template(ctx, ctx.expr, hi.span, "file error",
        f"file '{file_path}' does not exist")


def warn_pragma_operatorgroup_duplicate(ctx, hi: Obj):
    return err_template(ctx, ctx.expr, hi.span, "overriding operator group",
        f"this is very dangerous and may cause compilation errors")


def warn_pragma_operator_unknown_group(ctx, hi: Obj):
    return err_template(ctx, ctx.expr, hi.span, "unknown operator group",
        f"adding operator to an undefined operator group")


def err_unknown_pragma(ctx, hi: Obj):
    return err_template(ctx, ctx.expr, hi.span, "unknown directive",
        f"this is not a known compiler directive")


def err_unknown_symbol(ctx, hi: Obj):
    return err_template(ctx, ctx.expr, hi.span, "unknown symbol",
        f"this is a reference to an undefined name")


def err_lambda__arg_type(ctx, hi: Obj, exp_typ: Typ, got_typ: Typ):
    return err_template(ctx, ctx.expr, hi.span, "type mismatch",
        f"lambda expects argument of type '{exp_typ}', but got '{got_typ}'")


def err_lambda__pos_count_mismatch(ctx, got_count: int, exp_count: int):
    return err_template(ctx, ctx.expr, ctx.expr.span, "signature mismatch",
        f"lambda takes {exp_count} positional arguments, but got {got_count}")


def err_lambda__key_count_mismatch(ctx, got_count: int, exp_count: int):
    return err_template(ctx, ctx.expr, ctx.expr.span, "signature mismatch",
        f"lambda takes {exp_count} keyword arguments, but got {got_count}")


def err_lambda__not_variadic(ctx, hi):
    return err_template(ctx, ctx.expr, hi.span, "unexpected argument",
        "lambda doesn't take variadic arguments")


def err_lambda__unknown_keyword(ctx, hi, spec):
    keys = ', '.join(spec.keywords)
    return err_template(ctx, ctx.expr, hi.span, "unexpected argument",
        f"lambda doesn't take this keyword argument",
        hints=[f"the following keywords are valid: {keys}",
            f"original signature '{spec}'"])


def err_lambda__duplicate_keyword(ctx, hi):
    return err_template(ctx, ctx.expr, hi.span, "unexpected argument",
        f"keyword argument is duplicated")


def err_lambda__argument_order(ctx, hi, spec):
    return err_template(ctx, ctx.expr, hi.span, "unexpected argument",
        f"keyword arguments must be placed after positional arguments",
        hints=[f"original signature signature '{spec}'"])


def err_no_operators(ctx):
    return err_template(ctx, ctx.expr, ctx.expr.span, "no operators",
        f"without any operators defined only primary expressions can be parsed\n" +
        f"define operators with #operator(group), and compile with #operatorcompile")


def err_eval__redeclare_variable(ctx):
    return err_template(ctx, ctx.expr, ctx.expr.span, "variable redefinition",
        f"cannot redeclare this variable in current scope")


def err_eval__assign_undeclared(ctx):
    return err_template(ctx, ctx.expr, ctx.expr.span, "variable redefinition",
        f"cannot assign to an undeclared variable")


def err_eval__assign_to_constant(ctx):
    return err_template(ctx, ctx.expr, ctx.expr.span, "constant reassignment",
        f"cannot assign to a constant")


def err_unknown(ctx, message):
    return err_template(ctx, ctx.expr, ctx.expr.span, "unknown error", message)
