from typing import *
from .structure import *

RED = "\x1B[31m"
GRN = "\x1B[32m"
YEL = "\x1B[33m"
BLU = "\x1B[34m"
MAG = "\x1B[35m"
CYN = "\x1B[36m"
WHT = "\x1B[37m"
RST = "\x1B[0m"


def excerpt_exact(f, span):
    f.seek(span.start.byte)
    return f.read(len(span))


def excerpt(f, span):
    """Returns excerpt from the file including the beggining of the line"""
    f.seek(span.start.byte)
    offset = 0
    while f.read(1) != '\n':
        f.seek(span.start.byte - offset)
        offset += 1
    return f.read(len(span) + offset)


def reports(f, ast, hi=None):
    if not hi: hi = ast.span
    hi_lines = hi.stop.line - hi.start.line + 1
    t = excerpt(f, ast.span)
    return decorated(t, ast.span, hi=hi, hi_col=hi_lines == 1)


def report(f, ast, hi=None):
    print(report(f, ast, hi))


def formatted_line(line: str, y_fmt: str):
    return f"{y_fmt}|  {line}"


def highlight_row(hi: Span, line: str, y: int, y_fmt: str):
    arrow = " "
    if hi.start.line <= y <= hi.stop.line:
        arrow = f"{RED}>{RST}"
    return f"{y_fmt}|{arrow} {line}"


def highlight_col(hi: Span, line: str, y: int, y_fmt: str):
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
    max_digits = len(str(span.stop.line))
    y = span.start.line
    output = ''
    for i, line in enumerate(source.splitlines()):
        y_fmt = str(y).zfill(max_digits)
        if not hi:
            output += formatted_line(line, y_fmt)
        elif hi_col:
            output += formatted_line(line, y_fmt) + '\n'
            output += highlight_col(hi, line, y, y_fmt)
        else:
            output += highlight_row(hi, line, y, y_fmt)
        output += '\n'
        y += 1
    return output


def print_report(title, description, excerpt, solution):
    print(f"-- {title} --\n")
    print(description + '\n')
    print(excerpt)
    print(solution + '\n')


def err_file_search_failed(file, node):
    print(f"-- LOAD ERROR")
    print(f"file '{file_path}' could not be found")
    report(file, node, node.span)


def err_file_does_not_exist(file, node):
    print(f"-- LOAD ERROR")
    print(f"file '{file_path}' does not exist")
    report(file, node, node.span)


def err_bad_directive(main, node):
    print('-- UNKNOWN DIRECTIVE\n')
    report(main, node, hi=node.name.span)


def err_template(ctx, expr, hi, header, description):
    code = reports(ctx.file, expr, hi=hi)
    header = header.upper()
    return f"-- {header}\n{description}\n{code}"


def warn_duplicate_operatorgroup(ctx, hi: Object):
    return err_template(ctx, ctx.expr, hi.span, "overriding operator group",
                        f"this is very dangerous and may cause compilation errors")


def warn_unknown_operatorgroup(ctx, hi: Object):
    return err_template(ctx, ctx.expr, hi.span, "unknown operator group",
                        f"adding operotor to an undefined operator group")


def err_unknown_pragma(ctx, hi: Object):
    return err_template(ctx, ctx.expr, hi.span, "unknown directive",
                        f"this is not a known compiler directive")


def err_unknown_symbol(ctx, hi: Object):
    return err_template(ctx, ctx.expr, hi.span, "unknown symbol",
                        f"this is a reference to an undefined name")


def err_pragma_arg_type(ctx, hi: Object, exp_typ: Typ, got_typ: Typ):
    return err_template(ctx, ctx.expr, hi.span, "type mismatch",
                        f"directive expects argument of type '{exp_typ}', but got '{got_typ}'")


def err_pragma_not_enough_args(ctx, exp_count: int, got_count: int):
    return err_template(ctx, ctx.expr, ctx.expr.span, "missing arguments",
                        f"directive takes {exp_count} positional arguments, but got {got_count}")


def err_pragma_not_variadic(ctx):
    return err_template(ctx, ctx.expr, ctx.expr.span, "unexpected argument",
                        "directive doesn't take variadic arguments")


def err_pragma_bad_key_arg(ctx, hi):
    return err_template(ctx, ctx.expr, hi.span, "unexpected argument",
                        f"directive doesn't take this keyword argument")


def err_pragma_dup_key_arg(ctx, hi):
    return err_template(ctx, ctx.expr, hi.span, "unexpected argument",
                        f"keyword argument is duplicated")


def err_pragma_key_before_pos(ctx, hi):
    return err_template(ctx, ctx.expr, hi.span, "unexpected argument",
                        f"keyword arguments must be after positional arguments")

def err_no_operators(ctx):
    return err_template(ctx, ctx.expr, ctx.expr.span, "no operators",
        f"without any operators defined only primary expressions can be parsed\n" +
        f"define operators with #operator(group), and compile with #operatorcompile")
