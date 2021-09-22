import options, strutils, sequtils, re

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
        of expAtom:
            value*: string
            tag*: AtomTag
            pos*: Option[Position]
        of expTerm:
            exprs*: seq[Exp]

func len*(x: Exp): int =
    if x.kind == expAtom: return -1
    x.exprs.len

func is_atom*(x: Exp): bool =
    x.kind == expAtom

func is_nil*(x: Exp): bool =
    x.kind == expTerm and x.exprs.len == 0

func `[]`*(x: Exp, index: int): Exp =
    x.exprs[index]

template `[]`*[A, B](x: Exp, slice: HSlice[A, B]): seq[Exp] =
    x.exprs[slice]

func `[]=`*(x: var Exp, index: int, value: Exp) =
    x.exprs[index] = value

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

func atom*(x: string, tag: AtomTag = aSym, pos: Position): Exp =
    Exp(kind: expAtom, value: x, tag: tag, pos: some(pos))

func atom*(x: string, tag: AtomTag = aSym, pos: Option[Position]): Exp =
    Exp(kind: expAtom, value: x, tag: tag, pos: pos)

func atom*(x: string, tag: AtomTag = aSym): Exp =
    Exp(kind: expAtom, value: x, tag: tag, pos: none(Position))

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

func str*(x: Exp): string

func join*(x: Exp, sep: string): string =
    assert x.kind == expTerm
    x.exprs.map(str).join(sep)

func str_ugly_rec(x: Exp): string =
    case x.kind
    of expTerm: return "(" & x.exprs.map(str_ugly_rec).join(" ")  & ")"
    of expAtom: return x.str

func str_ugly*(x: Exp): string =
    x.str_ugly_rec

func str_group0(x: Exp): string = x.join(" ")

func str_group1(x: Exp): string = x.exprs.map(str_group0).join(", ")

func str_group2(x: Exp): string = x.exprs.map(str_group1).join("; ")

func str*(x: Exp): string =
    case x.kind
    of expAtom:
        if x.tag == aInd: return "$IND"
        if x.tag == aDed: return "$DED"
        if x.tag == aCnt: return "$CNT"
        if x.tag == aWs: return "$WS"
        if x.tag == aNl: return "$NL"
        if x.tag == aRes: return "\e[4m" & x.value & "\e[0m"
        if x.tag == aStr: return x.value
        if x.tag == aNum: return x.value
        if x.value.match(re"[ ;,(){}\[\]]"):
            return "`" & x.value & "`"
        else:
            return x.value
    of expTerm:
        return x.str_ugly


proc `$`*(x: Exp): string =
    x.str
