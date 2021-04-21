import options, tables, strutils, sequtils, sets

type
    FunParam* = object
        name*: string
        typ*: Option[Exp]
        default*: Option[Exp]
        autopass*: bool
        autoquote*: bool
        keyword*: bool
        variadic*: bool
        lazy*: bool

    FunTyp* = object
        params*: seq[FunParam]
        result*: Exp
        autocurry*: bool
        opaque*: bool
        pure*: bool
        is_macro*: bool

    Fun* = object
        id*: uint32
        typ*: FunTyp
        body*: Exp
        env*: Env

    RecSlot* = object
        name*: string
        typ*: Val
        default*: Option[Exp]
        typ_inferred_from_default*: bool
        typ_inferred_from_position*: bool

    RecField* = object
        name*: string
        val*: Val

    Mem* = object
        val: ptr Val
        count: int
        mutable: bool

    BuiltinFun* = proc(args: openArray[Val]): Val

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

    ValTag* = enum
        HoldVal, CastVal, RecVal, RecTypeVal, UnionTypeVal, InterTypeVal, TypeVal, NumVal,
        ExpVal, ExpTypeVal, MemVal, FunVal, FunTypeVal, BuiltinFunVal,
        OpaqueVal, OpaqueFunVal

    Val* = ref object
        case kind*: ValTag
        of RecVal:
            fields*: seq[RecField]
        of HoldVal:
            name*: string
        of NumVal:
            num*: int
        of MemVal:
            mem*: Mem
        of ExpVal:
            exp*: Exp
        of ExpTypeVal:
            discard
        of FunVal:
            fun*: Fun
        of OpaqueFunVal:
            disp_name*: string
            result*: Val
            opaque_fun*: Fun
            bindings*: seq[(string, Val)]
        of TypeVal:
            level*: int
        of CastVal:
            val*, typ*: Val
        of OpaqueVal:
            inner*: Val
        of UnionTypeVal, InterTypeVal:
            types*: seq[Val]
        of RecTypeVal:
            slots*: seq[RecSlot]
        of FunTypeVal:
            fun_typ*: FunTyp
        of BuiltinFunVal:
            builtin_fun*: BuiltinFun

    Var* = object
        val*, typ*: Val
        is_defined*: bool

    Env* = ref object
        parent*: Env
        vars*: Table[string, Var]

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

func is_literal*(x: Exp): bool = x.kind == expAtom and x.tag in {aNum, aStr, aLit}
func is_whitespace*(x: Exp): bool = x.kind == expAtom and x.tag in {aWs, aNl, aInd, aDed, aCnt, aCom}
func is_token*(x: Exp, value: string): bool = x.kind == expAtom and x.value == value
func is_term*(x: Exp): bool = x.kind == expTerm
func is_term*(x: Exp, len: int): bool = x.kind == expTerm and x.exprs.len == len
func is_term_prefix*(x: Exp, len: int): bool = x.kind == expTerm and x.exprs.len >= len
func tail*(x: Exp): seq[Exp] = x.exprs[1 .. ^1]

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

func pos*(y, x, yy, xx: int, file: ref string = nil): Position =
    Position(start_line: y, start_char: x, stop_line: yy, stop_char: xx, file: file)

proc extend*(env: Env): Env =
    Env(parent: env)

func len*(x: Exp): int =
    if x.kind == expAtom: return -1
    x.exprs.len

func `[]`*(x: Exp, index: int): Exp =
    x.exprs[index]

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

func str*(x: uint64): string =
    var res = x.to_hex
    if x < 0x100000000'u64:
        res = res[8 .. ^1]
    "0x" & res

proc str*(v: Val): string =
    case v.kind
    of HoldVal: v.name
    of OpaqueVal: "Opaque(" & v.inner.str & ")"
    of CastVal: v.typ.str & "(" & v.val.str & ")"
    of NumVal: $v.num
    of MemVal: "Memory(" & cast[uint64](v.mem.val).str & ")"
    of ExpVal: "Expr(" & v.exp.str & ")"
    of ExpTypeVal: "Expr"
    of BuiltinFunVal: "Builtin-Lambda()"
    of TypeVal:
        if v.level == 0: "Type" else: "Type" & $v.level
    of UnionTypeVal, InterTypeVal:
        let op = if v.kind == UnionTypeVal: "|" else: "&"
        if v.types.len == 0:
            return if v.kind == UnionTypeVal: "Any" else: "Never"
        v.types.map(str).join(op)
    of FunVal: "Lambda(" & v.fun.id.str & ")"
    of OpaqueFunVal:
        var name = if v.disp_name != "": v.disp_name else: "Lambda(" & v.opaque_fun.id.str & ")"
        var args: seq[string]
        for (key, val) in v.bindings:
            args.add(val.str)
        name & "(" & args.join(", ") & ")"
    of FunTypeVal:
        var prefix = ""
        if v.fun_typ.pure: prefix &= "pure "
        if v.fun_typ.opaque: prefix &= "opaque "
        #if v.fun_typ.is_macro: prefix &= "macro "
        var params: seq[string]
        for param in v.fun_typ.params:
            var s = param.name
            if param.typ.is_some: s &= ": " & param.typ.get.str
            if param.default.is_some: s &= " = " & param.default.get.str
            params.add(s)
        prefix & "(" & params.join(", ") & ") -> " & v.fun_typ.result.str
    of RecVal:
        var res: seq[string]
        for x in v.fields:
            let prefix = if x.name == "": "" else: x.name & "="
            res.add(prefix & x.val.str)
        "(" & res.join(", ") & ")"
    of RecTypeVal:
        var res: seq[string]
        for x in v.slots:
            var repr = ""
            if x.name != "": repr &= x.name & ": "
            repr &= x.typ.str
            if x.default.is_some: repr &= " = " & x.default.get.str
            res.add(repr)
        "Record(" & res.join(", ") & ")"

proc `$`*(x: Exp): string =
    x.str

proc `$`*(x: Val): string =
    x.str
