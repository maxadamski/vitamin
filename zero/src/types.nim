import options, tables, strutils, strformat, sequtils, sets

type
    Fun* = object
        args: seq[string]
        body: Exp
        env: ref Env

    Mem* = object
        val: ptr Val
        count: int
        mutable: bool

    BuiltinFun* = proc(args: openArray[Val]): Val

    Position* = object
        start_line*, start_char*, stop_line*, stop_char*: int
        file*: ref string

    AtomTag* = enum
        aInd, aDed, aCnt, aPar, aSym, aNum, aStr, aWs, aNl, aCom, aEsc

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

    ValTag* = enum
        vNum, vExp, vMem, vFun, vBuiltinFun

    Val* = object
        case kind*: ValTag
        of vNum: num*: int
        of vExp: exp*: Exp
        of vMem: mem*: Mem
        of vFun: fun*: Fun
        of vBuiltinFun: builtin_fun*: BuiltinFun

    Var* = object
        val*, typ*: Val

    Env* = object
        parent*: ref Env
        vars*: Table[string, Var]

    ExpStream* = object
        items*: seq[Exp]
        index*: int

    ResultTag = enum ErrorResult, OkResult

    Result*[E, R] = object
        case kind*: ResultTag
        of ErrorResult:
            error*: E
        of OkResult:
            value*: R

func is_error*[E, R](x: Result[E, R]): bool = x.kind == ErrorResult
func is_ok*[E, R](x: Result[E, R]): bool = x.kind == OkResult
func get_error*[E, R](x: Result[E, R]): E = x.error
func get*[E, R](x: Result[E, R]): R = x.value
func opt_error*[E, R](x: Result[E, R]): Option[E] =
    if x.is_error: some(x.error) else: none(E)
func opt*[E, R](x: Result[E, R]): Option[R] =
    if x.is_ok: some(x.value) else: none(R)
func error*[E, R](x: E): Result[E, R] = Result[E, R](kind: ErrorResult, error: x)
func ok*[E, R](x: R): Result[E, R] = Result[E, R](kind: OkResult, value: x)

func is_literal*(x: Exp): bool =
    x.kind == expAtom and x.tag in {aNum, aStr}

func is_whitespace*(x: Exp): bool =
    x.kind == expAtom and x.tag in {aWs, aNl, aInd, aDed, aCnt, aCom}

func is_token*(x: Exp, value: string): bool =
    x.kind == expAtom and x.value == value

func is_term*(x: Exp): bool =
    x.kind == expTerm

func is_term*(x: Exp, len: int): bool =
    x.kind == expTerm and x.exprs.len == len

proc mkstream*(items: seq[Exp]): ExpStream =
    ExpStream(items: items, index: 0)

proc eos*(self: ExpStream): bool =
    self.index >= self.items.len

proc peek_opt*(self: ExpStream, ind: bool = false): Option[Exp] =
    var i = self.index
    while not ind and i < self.items.len and  self.items[i].is_whitespace:
        i += 1
    if i < self.items.len:
        some(self.items[i])
    else:
        none(Exp)

proc next_opt*(self: var ExpStream, ind: bool = false): Option[Exp] =
    var i = self.index
    while not ind and i < self.items.len and self.items[i].is_whitespace:
        i += 1
    if i >= self.items.len: return none(Exp)
    let item = self.items[i]
    self.index = i + 1
    some(item)

proc peek*(self: ExpStream, ind: bool = false): Exp = 
    self.peek_opt(ind=ind).get

proc next*(self: var ExpStream, ind: bool = false): Exp =
    self.next_opt(ind=ind).get

proc expect_raw*(self: ExpStream, token: string): bool =
    if self.index >= self.items.len: return false
    let e = self.items[self.index]
    return e.kind == expAtom and e.value == token

proc expect*(self: ExpStream, token: string, tag: Option[AtomTag] = none(AtomTag), ind: bool = false): bool =
    if self.eos: return false
    let e = self.peek(ind=ind or token.starts_with("$"))
    return e.kind == expAtom and e.value == token and (tag.is_none or e.tag == tag.get)

proc expect_in*(self: ExpStream, tokens: HashSet[string], ind: bool = false): bool =
    let e = self.peek_opt(ind=ind or tokens.any_it(it.starts_with("$")))
    if e.is_none: return false
    return e.get.kind == expAtom and e.get.value in tokens

proc expect_notin*(self: ExpStream, tokens: HashSet[string], ind: bool = false): bool =
    if self.eos: return false
    let e = self.peek(ind=ind or tokens.any_it(it.starts_with("$")))
    return e.kind == expAtom and e.value notin tokens

proc eat_atom*(self: var ExpStream, token: string, tag: Option[AtomTag] = none(AtomTag)): Option[Exp] =
    let ind = token.starts_with("$")
    if not self.expect(token, tag, ind=ind):
        return none(Exp)
    self.next_opt(ind=ind)


template mkval*(x: int): Val = Val(kind: vNum, num: x)
template mkval*(x: Exp): Val = Val(kind: vExp, exp: x)
template mkval*(x: Mem): Val = Val(kind: vMem, mem: x)
template mkval*(x: Fun): Val = Val(kind: vFun, fun: x)
template mkval*(x: BuiltinFun): Val = Val(kind: vBuiltinFun, builtin_fun: x)

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

func to_string(x: Exp): string =
    case x.kind
    of expAtom:
        if x.tag == aInd: return "$IND"
        if x.tag == aDed: return "$DED"
        if x.tag == aCnt: return "$CNT"
        if x.tag == aWs: return "$WS"
        if x.tag == aNl: return "$NL"
        if ' ' in x.value or x.value == "{" or x.value == "}":
            return "`" & x.value & "`"
        else:
            return x.value
    of expTerm:
        if x.exprs.len >= 2 and x.exprs[0].is_token("call"):
            return x.exprs[1].to_string & "(" & x.exprs[2 .. ^1].map(to_string).join(", ") & ")"
        elif x.exprs.len >= 1 and x.exprs[0].is_token("group"):
            return "(" & x.exprs[1 .. ^1].map(to_string).join(", ") & ")"
        else:
            return "{" & x.exprs.map(to_string).join(" ") & "}"

func `$`*(x: Exp): string =
    to_string(x)

func pos*(y, x, yy, xx: int, file: ref string = nil): Position =
    Position(start_line: y, start_char: x, stop_line: yy, stop_char: xx, file: file)

proc extend*(env: ref Env): ref Env =
    var child = new Env
    child.parent = env
    child

func concat*(x: Exp, y: Exp): Exp =
    if x.kind == expTerm and y.kind == expTerm: return term(x.exprs & y.exprs)
    if x.kind == expAtom and y.kind == expAtom: return term(x, y)
    if x.kind == expTerm and y.kind == expAtom: return concat(x, term(y))
    if x.kind == expAtom and y.kind == expTerm: return concat(term(x), y)

proc append*(x: Exp, y: varargs[Exp]): Exp =
    if x.kind == expTerm:
        var z = x
        z.exprs &= y
        return z
    echo "left operand of append must be a term, but found {x}".fmt
    quit(1)

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
