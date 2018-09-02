RED = "\x1B[31m"
GRN = "\x1B[32m"
YEL = "\x1B[33m"
BLU = "\x1B[34m"
MAG = "\x1B[35m"
CYN = "\x1B[36m"
WHT = "\x1B[37m"
RST = "\x1B[0m"

@dataclass
class Point:
    y: int
    x: int

@dataclass
class Segment:
    start: Point
    stop: Point


def context_stop_point(context):
    point = Point(context.start.line, context.start.column + 1)
    if context.start == context.stop:
        point.x += len(context.getText()) - 1
    return point

def context_start_point(context):
    return Point(context.stop.line, context.stop.column + 1)

def context_segment(context):
    return Segment(context.start_point(), context.stop_point())

def valid_precedence_fields(pairs):
    valid_keys = ['associativity', 'lower_than', 'higher_than']
    seen = set()
    for key, value in pairs:
        if key in seen:
            return False
        if value not in valid_keys:
            return False
        if key == 'associativity' and not valid_associativity(value):
            return False
        seen.add(key)

def valid_associativity(value):
    return value in ['Left', 'Right']

def valid_fixity(value):
    return value in ['Prefix', 'Suffix', 'Infix', 'Assignment']

def formatted_line(line: str, y_fmt: str):
    return f"{y_fmt}|  {line}"

def highlight_row(hi: Segment, line: str, y: int, y_fmt: str):
    arrow = " "
    if hi.start.y <= y <= hi.stop.y:
        arrow = f"{RED}>{RST}"
    return f"{y_fmt}|{arrow} {line}"

def highlight_col(hi: Segment, line: str, y: int, y_fmt: str):
    hx0, hx1 = hi.start.x, hi.stop.x
    hy0, hy1 = hi.start.y, hi.stop.y

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
    y_fmt = ' ' * len(y_fmt)
    if not squiggles: return None
    return f"{y_fmt}   {RED}{squiggles}{RST}"

def source_excerpt(source: str, seg: Segment, hi = None, hi_col = True):
    # text columns are 1-indexed
    if hi: hi.start.x -= 1
    max_digits = len(str(seg.stop.y))
    y = seg.start.y
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

