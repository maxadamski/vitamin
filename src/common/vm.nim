import options, tables, strutils, sequtils, algorithm
import exp, utils, error

type
    Var* = object
        val*, typ*: Val
        is_defined*: bool
        is_placeholder*: bool
        definition*: Option[Exp]

    Env* = ref object
        parent*: Env
        vars*: Table[string, Var]

    ValTag* = enum
        HoldVal, RecVal, RecTypeVal, UnionTypeVal, InterTypeVal,
        TypeVal, NumVal, ExpVal, MemVal, FunVal,
        FunTypeVal, BuiltinFunVal, OpaqueVal, OpaqueFunVal,
        SymbolVal, SymbolTypeVal, SetTypeVal

    Val* = ref object
        typ*: Option[Val]

        case kind*: ValTag
        of TypeVal:
            level*: int

        of SetTypeVal, UnionTypeVal, InterTypeVal:
            values*: seq[Val]

        of RecTypeVal:
            slots*: seq[RecSlot]
            extensible*: bool
            extension*: Option[Exp]

        of RecVal:
            fields*: seq[RecField]

        of FunTypeVal:
            fun_typ*: FunTyp

        of FunVal:
            fun*: Fun

        of OpaqueFunVal:
            disp_name*: string
            result*: Val
            opaque_fun*: Fun
            bindings*: seq[(string, Val)]

        of HoldVal, SymbolVal, SymbolTypeVal:
            name*: string

        of NumVal:
            num*: int

        of MemVal:
            mem_ptr*: Val
            mem_typ*: Val
            wr*, rd*, imm*: bool

        of ExpVal:
            exp*: Exp

        #of CastVal:
        #    val*, typ*: Val

        of OpaqueVal:
            inner*: Val

        of BuiltinFunVal:
            builtin_fun*: BuiltinFun
            builtin_typ*: FunTyp


    NeutralTag* = enum NVar, NApp

    Neutral* = ref object
        case kind*: NeutralTag
        of NVar:
            name*: string
        of NApp:
            head*: Neutral
            args*: seq[Arg]

    Arg* = object
        name*: string
        value*: Val
        keyword*: bool

    FunParam* = object
        name*: string
        typ*: Exp
        default*: Option[Exp]
        did_infer_typ*: bool
        searched*: bool
        quoted*: bool
        keyword*: bool
        variadic*: bool
        lazy*: bool

    FunTyp* = object
        params*: seq[FunParam]
        result*: Exp
        #autoapply*: bool
        is_opaque*: bool
        is_pure*: bool
        is_macro*: bool

    Fun* = object
        typ*: FunTyp
        body*: Exp
        env*: Option[Env]

    RecSlot* = object
        name*: string
        typ*: Val
        default*: Option[Exp]
        typ_inferred_from_default*: bool
        typ_inferred_from_position*: bool

    RecField* = object
        name*: string
        val*, typ*: Val

    BuiltinFun* = proc(env: Env, args: seq[Val]): Val

func str*(v: Val): string

func `$`*(x: Val): string = x.str

proc equal*(x, y: Val): bool

# Nim, why so much boilerplate :(

func Number*(num: int): Val =
    Val(kind: NumVal, num: num)

func Hold*(name: string): Val =
    Val(kind: HoldVal, name: name)

func VExp*(exp: Exp): Val =
    Val(kind: ExpVal, exp: exp)

func Opaque*(inner: Val): Val =
    Val(kind: OpaqueVal, inner: inner)

func Universe*(level: int): Val =
    Val(kind: TypeVal, level: 0)

func UnionType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: UnionTypeVal, values: @values)

func InterType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: InterTypeVal, values: @values)

func Record*(fields: varargs[RecField]): Val =
    Val(kind: RecVal, fields: @fields)

func RecordType*(slots: varargs[RecSlot], extensible = false, extension = none(Exp)): Val =
    Val(kind: RecTypeVal, slots: @slots, extensible: extensible or extension.is_some, extension: extension)

func LambdaType*(params: varargs[FunParam], ret: Exp): FunTyp =
    FunTyp(params: @params, result: ret)

func LambdaType*(typ: FunTyp): Val =
    Val(kind: FunTypeVal, fun_typ: typ)

proc Lambda*(typ: FunTyp, body: Exp, env: Env): Val =
    Val(kind: FunVal, fun: Fun(typ: typ, body: body, env: some(env)))

# end of constructors

func extend*(env: Env): Env =
    Env(parent: env)

func assume*(env: Env, name: string, typ: Val) =
    env.vars[name] = Var(val: Hold(name), typ: typ, is_defined: true)

func declare*(env: Env, name: string, val, typ: Val) =
    env.vars[name] = Var(val: val, typ: typ, is_defined: true)

func get_opt*(env: Env, name: string): Option[Var] =
    if name in env.vars:
        some(env.vars[name])
    elif env.parent != nil:
        env.parent.get_opt(name)
    else:
        none(Var)

proc sets_inter*(xs, ys: seq[Val]): seq[Val] =
    for x in xs:
        block inner:
            for y in ys:
                if equal(x, y):
                    result.add(x)
                    break inner

proc is_subtype*(x, y: Val): bool =
    # is x a subtype of y
    if equal(x, y): return true
    if y.kind == UnionTypeVal and y.values.len == 0: return true
    if y.kind == UnionTypeVal: return y.values.any_it(equal(x, it))
    if y.kind == InterTypeVal and y.values.len == 0: return false
    if y.kind == SetTypeVal: return sets_inter(x.values, y.values).len > 0
    return false

proc sets_equal*(xs, ys: seq[Val]): bool =
    if xs.len != ys.len: return false
    for x in xs:
        block inner:
            for y in ys:
                if equal(x, y):
                    break inner
            return false
    true

proc args_equal(xs, ys: seq[Arg]): bool =
    if xs.len != ys.len: return false
    for x in xs:
        if not ys.any_it(it == x): return false
    true

proc equal(x, y: Neutral): bool =
    if x.kind != y.kind: return false
    case x.kind:
    of NVar: x.name == y.name
    of NApp: equal(x.head, y.head) and args_equal(x.args, y.args)

proc equal*(x, y: Exp): bool =
    if x.kind != y.kind: return false
    case x.kind
    of expAtom: x.value == y.value
    of expTerm:
        if x.len != y.len: return false
        for (a, b) in zip(x.exprs, y.exprs):
            if not equal(a, b): return false
        return true

proc equal(x, y: FunTyp): bool =
    if x.params.len != y.params.len: return false
    if not equal(x.result, y.result): return false
    for (a, b) in zip(x.params, y.params):
        if not (a.name == b.name and equal(a.typ, b.typ)): return false
    true

proc equal*(x, y: Val): bool =
    if x.kind != y.kind: return false
    if x == y: return true
    case x.kind
    of TypeVal:
        x.level == y.level
    of OpaqueVal:
        x == y
    of HoldVal, SymbolVal:
        x.name == y.name
    of SetTypeVal, UnionTypeVal, InterTypeVal:
        sets_equal(x.values, y.values)
    of OpaqueFunVal:
        equal(x.opaque_fun.typ, y.opaque_fun.typ) and x.bindings == y.bindings
        #equal(x.opaque_fun.typ, y.opaque_fun.typ) and x.bindings == y.bindings
    of FunVal:
        #equal(x.fun.typ, x.fun.typ)
        x == y
    of RecTypeVal:
        if x.slots.len != y.slots.len: return false
        let n = x.slots.len
        let sx = x.slots.sorted_by_it(it.name)
        let sy = y.slots.sorted_by_it(it.name)
        for i in 0..<n:
            if sx[i].name != sy[i].name or not equal(sx[i].typ, sy[i].typ): return false
        return true
    #of CastVal:
    #    return equal(x.val, y.val)
    of NumVal:
        return x.num == y.num
    else:
        raise error(term(), "Equality for {x} and {y} ({x.kind}) not implemented".fmt)


func str*(x: Arg): string =
    if not x.keyword: return x.value.str
    x.name & "=" & x.value.str

func str*(x: Neutral): string =
    case x.kind
    of NVar:
        x.name
    of NApp:
        x.head.str & "(" & x.args.map(str).join(", ") & ")"

func str*(v: Val): string =
    case v.kind
    of HoldVal, SymbolVal, SymbolTypeVal:
        v.name

    of SetTypeVal:
        "Set(" & v.values.map(str).join(", ") & ")"

    of OpaqueVal:
        "Opaque(" & v.inner.str & ")"

    #of CastVal:
    #    v.typ.str & "(" & v.val.str & ")"

    of NumVal:
        $v.num

    of MemVal:
        "Memory(...)"

    of ExpVal:
        "Expr(" & v.exp.str & ")"

    of BuiltinFunVal:
        "Builtin-Lambda()"

    of TypeVal:
        if v.level == 0: "Type" else: "Type" & $v.level

    of UnionTypeVal, InterTypeVal:
        let op = if v.kind == UnionTypeVal: " | " else: " & "
        if v.values.len == 0:
            return if v.kind == UnionTypeVal: "Any" else: "Never"
        v.values.map(str).join(op)

    of FunVal:
        "Lambda(...)"

    of OpaqueFunVal:
        var name = if v.disp_name != "": v.disp_name else: "Lambda(...)"
        var args: seq[string]
        for (key, val) in v.bindings:
            args.add(val.str)
        name & "(" & args.join(", ") & ")"

    of FunTypeVal:
        var prefix = ""
        if v.fun_typ.is_pure: prefix &= "pure "
        if v.fun_typ.is_opaque: prefix &= "opaque "
        if v.fun_typ.is_macro: prefix &= "macro "
        var params: seq[string]
        for param in v.fun_typ.params:
            var s = param.name
            if not param.did_infer_typ: s &= ": " & param.typ.str
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
