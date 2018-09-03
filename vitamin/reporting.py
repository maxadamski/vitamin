from .structure import Loc, Span

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


def report(f, ast, hi=None):
    if not hi: hi = ast.span
    hi_lines = hi.stop.line - hi.start.line + 1
    t = excerpt(f, ast.span)
    print(decorated(t, ast.span, hi=hi, hi_col=hi_lines == 1))


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


def warn_duplicate_operatorgroup(file, node):
    print(f"-? OVERRIDING PRECEDENCE")
    print(f"you are overriding precedence definitions for the operator group '{name}'")
    print(f"this is very dangerous and may cause compilation errors")
    report(file, node, node.span)


def err_bad_operatorgroup(file, node):
    print(f"-- UNKNOWN GROUP")
    print(f"'{group}' is not a registered operator group")
    report(file, node, node.args[0].span)


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


def err_function_not_variadic(file, call, arg):
    print(f"-- UNEXPECTED VARARG")
    print(f"this function doesn't take variable arguments, but got '{arg}'")
    report(file, call, arg.span)
