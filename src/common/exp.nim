import options, strutils, sequtils

type
    Position* = object
        start_line*, start_char*, stop_line*, stop_char*: int
        file*: ref string

    AtomTag* = enum
        aInd, aDed, aCnt, aPar, aSym, aLit, aNum, aStr, aWs, aNl, aCom, aEsc

    ExpTag* = enum
        expAtom, expTerm

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

func `[]=`*(x: var Exp, index: int, value: Exp) =
    x.exprs[index] = value

func is_literal*(x: Exp): bool =
    x.kind == expAtom and x.tag in {aNum, aStr, aLit}

func is_whitespace*(x: Exp): bool =
    x.kind == expAtom and x.tag in {aWs, aNl, aInd, aDed, aCnt, aCom}

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

func tail*(x: Exp): seq[Exp] = x.exprs[1 .. ^1]

func atom*(x: string, tag: AtomTag = aSym, pos: Position): Exp =
    Exp(kind: expAtom, value: x, tag: tag, pos: some(pos))

func atom*(x: string, tag: AtomTag = aSym, pos: Option[Position]): Exp =
    Exp(kind: expAtom, value: x, tag: tag, pos: pos)

func atom*(x: string, tag: AtomTag = aSym): Exp =
    Exp(kind: expAtom, value: x, tag: tag, pos: none(Position))

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
    var res = if x.kind == expAtom: term(x) else: x
    res.exprs &= y
    res

func merge_position*(pos: seq[Position]): Option[Position] =
    if pos.len == 0: return none(Position)
    var start_line = pos[0].start_line
    var start_char = pos[0].start_char
    var stop_line = pos[0].stop_line
    var stop_char = pos[0].stop_char
    var file = pos[0].file
    for x in pos:
        if x.file != nil: file = x.file
        if x.start_line <= start_line:
            start_line = x.start_line
            start_char = min(start_char, x.start_char)
        if x.stop_line >= stop_line:
            stop_line = x.stop_line
            stop_char = max(stop_char, x.stop_char)
    some(pos(start_line, start_char, stop_line, stop_char, file))

func calculate_position*(node: Exp): Option[Position] =
    case node.kind
    of expAtom:
        node.pos
    of expTerm:
        node.exprs.map_it(it.calculate_position).filter_it(it.is_some).map_it(it.get).merge_position

func str*(x: Exp): string

func join*(x: Exp, sep: string): string =
    assert x.kind == expTerm
    x.exprs.map(str).join(sep)

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
        if x.tag == aStr: return "\"" & x.value & "\""
        if ' ' in x.value or '{' in x.value or '}' in x.value:
            return "`" & x.value & "`"
        else:
            return x.value
    of expTerm:
        if x.exprs.len >= 3 and x.exprs[0].is_token("()"):
            return x.exprs[1].str & "(" & x.exprs[2 .. ^1].map(str).join(", ") & ")"
        elif x.exprs.len >= 2 and x.exprs[0].is_token("[]"):
            return x.exprs[1].str & "[" & x.exprs[2 .. ^1].map(str).join(", ") & "]"
        elif x.exprs.len >= 2 and x.exprs[0].is_token("Record"):
            return x.exprs[0].str & "(" & x.exprs[1].str_group2 & ")"
        elif x.exprs.len >= 1 and x.exprs[0].is_token("(_)"):
            return "(" & x.exprs[1].str_group2 & ")"
        elif x.exprs.len >= 1 and x.exprs[0].is_token("[_]"):
            return "[" & x.exprs[1].str_group2 & "]"
        else:
            return "{" & x.exprs.map(str).join(" ") & "}"

func str_ugly*(x: Exp): string =
    case x.kind
    of expTerm: return "{" & x.exprs.map(str_ugly).join(" ")  & "}"
    of expAtom: return x.str

proc `$`*(x: Exp): string =
    x.str
