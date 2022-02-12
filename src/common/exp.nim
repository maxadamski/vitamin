import options, strutils, strformat, sequtils, re, utils

type
    Position* = object
        start_line*, start_char*, stop_line*, stop_char*: int
        file*: ref string

    AtomTag* = enum
        aRes, aInd, aDed, aCnt, aPar, aSym, aLit, aNum, aStr, aWs, aNl, aCom, aEsc

    ExpTag* = enum
        expTerm, expAtom

    Exp* = object
        case kind*: ExpTag
        of expTerm:
            exprs*: seq[Exp]
        of expAtom:
            value*: string
            tag*: AtomTag
            pos*: Option[Position]
            index*, level*: int

func len*(x: Exp): int =
    if x.kind == expAtom: return -1
    x.exprs.len

func is_atom*(x: Exp): bool =
    x.kind == expAtom

func is_nil*(x: Exp): bool =
    x.kind == expTerm and x.exprs.len == 0

func `[]`*(x: Exp, index: int): lent Exp =
    x.exprs[index]

func mref*(x: var Exp, index: int): ptr Exp =
    addr x.exprs[index]

func `[]=`*(x: var Exp, index: int, value: Exp) =
    x.exprs[index] = value

template `[]`*[A, B](x: Exp, slice: HSlice[A, B]): seq[Exp] =
    x.exprs[slice]

func `&=`*(x: var Exp, value: Exp) =
    x.exprs &= value

func `==`*(x: Exp, y: Exp): bool =
    if x.kind != y.kind: return false
    case x.kind
    of expAtom:
        if x.tag == aRes or y.tag == aRes:
            x.tag == y.tag and x.value == y.value
        else:
            x.value == y.value
    of expTerm:
        if x.exprs.len != y.exprs.len: return false
        for (xe, ye) in zip(x.exprs, y.exprs):
            if xe != ye:
                return false
        true

func is_literal*(x: Exp): bool =
    x.kind == expAtom and x.tag in {aNum, aStr, aLit}

func is_whitespace*(x: Exp): bool =
    x.kind == expAtom and x.tag in {aWs, aNl, aInd, aDed, aCnt, aCom}

func is_reserved*(x: Exp): bool =
    x.kind == expAtom and x.tag == aRes

func is_comment*(x: Exp): bool =
    x.kind == expAtom and x.tag == aCom

func is_atom*(x: Exp, value: string): bool =
    x.kind == expAtom and x.value == value

func is_token*(x: Exp, value: string): bool =
    x.kind == expAtom and x.value == value

func is_token*(x: Exp, values: open_array[string]): bool =
    x.kind == expAtom and x.value in values

func is_term*(x: Exp): bool =
    x.kind == expTerm

func is_term*(x: Exp, len: int): bool =
    x.kind == expTerm and x.exprs.len == len

func is_term_prefix*(x: Exp, len: int): bool =
    x.kind == expTerm and x.exprs.len >= len

func has_prefix*(x: Exp, token: string): bool =
    x.len >= 1 and x[0].is_token(token)

func has_prefix_any*(x: Exp, tokens: open_array[string]): bool =
    x.len >= 1 and x[0].is_token(tokens)

func head*(x: Exp): Exp = x.exprs[0]

func tail*(x: Exp): seq[Exp] = x.exprs[1 .. ^1]

iterator mexprs*(x: var Exp): tuple[key: int, val: var Exp] =
    for (i, xx) in x.exprs.mpairs:
        yield (i, xx)

func atom*(x: string, tag: AtomTag = aSym, pos = none(Position), index = -1, level = -1): Exp =
    Exp(kind: expAtom, value: x, tag: tag, pos: pos, index: index, level: level)

func atom*(x: string, tag: AtomTag = aSym, pos: Position): Exp =
    atom(x, tag, some(pos))

func reserved_atom*(x: string): Exp =
    atom(x, tag=aRes)

func term*(x: seq[Exp]): Exp =
    Exp(kind: expTerm, exprs: x)

func term*(x: varargs[Exp]): Exp =
    term(x.toSeq)

func pos*(y, x, yy, xx: int, file: ref string = nil): Position =
    Position(start_line: y, start_char: x, stop_line: yy, stop_char: xx, file: file)

func concat*(xs: varargs[Exp]): Exp =
    var exprs: seq[Exp]
    for x in xs:
        case x.kind
        of expAtom: exprs.add(x)
        of expTerm: exprs &= x.exprs
    term(exprs)

proc append*(x: Exp, y: varargs[Exp]): Exp =
    # FIXME: remove this evil function
    var res = if x.kind == expAtom: term(x) else: x
    res.exprs &= y
    res

func merge*(positions: seq[Position]): Position =
    assert positions.len > 0
    result = positions[0]
    for pos in positions:
        if pos.file != nil:
            result.file = pos.file
        if pos.start_line < result.start_line:
            result.start_line = pos.start_line
            result.start_char = pos.start_char
        elif pos.start_line == result.start_line:
            result.start_char = min(result.start_char, pos.start_char)
        if pos.stop_line > result.stop_line:
            result.stop_line = pos.stop_line
            result.stop_char = pos.stop_char
        elif pos.stop_line == result.stop_line:
            result.stop_char = max(result.stop_char, pos.stop_char)

func calculate_position*(node: Exp): Option[Position] =
    case node.kind
    of expAtom:
        node.pos
    of expTerm:
        var positions = node.exprs.map_it(it.calculate_position).filter_it(it.is_some).map_it(it.get)
        if positions.len == 0: return none(Position)
        return some(positions.merge)

func str*(x: Exp): string =
    case x.kind
    of expAtom:
        if x.tag == aInd: return "$IND"
        if x.tag == aDed: return "$DED"
        if x.tag == aCnt: return "$CNT"
        if x.tag == aWs: return "$WS"
        if x.tag == aNl: return "$NL"
        if x.tag == aRes: return "\e[4m" & x.value & "\e[0m"
        if x.tag == aStr: return x.value.my_escape
        if x.tag == aNum: return x.value
        if x.value.match(re"[ ;,(){}\[\]]"):
            return "`" & x.value & "`"
        else:
            if x.index != -1:
                return "{x.value}^{x.index}".fmt
            else:
                return x.value
    of expTerm:
        return "(" & x.exprs.map(str).join(" ")  & ")"

proc core_to_pretty*(exp: Exp, level=0): string =
    case exp.kind
    of expAtom:
        result &= exp.str
    of expTerm:
        if exp.has_prefix("Core/block"):
            let indent = "  ".repeat(level)
            result &= "(Core/block\n"
            for stat in exp.tail:
                result &= indent & "  " & stat.core_to_pretty(level+1) & "\n"
            result &= indent & ")"
        else:
            result &= "(" & exp.exprs.map_it(it.core_to_pretty(level)).join(" ") & ")"

func `$`*(x: Exp): string = x.str