import options, tables
import exp, utils

{.warning[ProveInit]: off.}

type
    Var* = object
        val*, typ*: Opt[Val]
        site*: Opt[Exp]

    VarDefined* = object
        val*, typ*: Val
        site*: Opt[Exp]

    VarAssumed* = object
        typ*: Val
        val*: Opt[Val]
        site*: Opt[Exp]

    TraceCall* = object
        site*: Exp
        # call during type inference
        infer*: bool

    Env* = ref object
        parent*: Env
        vars*: Table[string, Var]

    Ctx* = ref object
        env*: Env
        site_stack*: seq[Exp]
        call_stack*: seq[TraceCall]

    VitaminError* = object of CatchableError
        node*: Exp
        ctx*: Ctx
        with_trace*: bool

    ValTag* = enum
        HoldVal, NeuVal, UniqueVal, RecVal, RecTypeVal,
        UnionTypeVal, InterTypeVal,
        TypeVal, NumVal, ExpVal, MemVal, FunVal, FunTypeVal


    RecSlot* = object
        name*: string
        typ*: Exp
        default*: Opt[Exp]
        typ_inferred_from_default*: bool
        typ_inferred_from_position*: bool

    RecField* = object
        name*: string
        val*, typ*: Val

    Rec* = object
        fields*: seq[RecField]

    RecTyp* = object
        slots*: seq[RecSlot]
        extensible*: bool
        extension*: Opt[Exp]

    BuiltinFunProc* = proc(ctx: Ctx, args: seq[Val]): Val

    FunParam* = object
        name*: string
        typ*: Exp
        default*: Opt[Exp]
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
        is_pure*: bool
        is_total*: bool
        is_macro*: bool

    Fun* = object
        name*: string # may be empty (anonymous function)
        body*: Either[Exp, BuiltinFunProc]
        typ*: Opt[FunTyp] # cannot be none at invocation
        ctx*: Opt[Ctx] # closure context
        builtin*: bool

    ValObj* = object
        typ*: Opt[Val]

        case kind*: ValTag
        of TypeVal:
            level*: int

        of UnionTypeVal, InterTypeVal:
            values*: seq[Val]

        of RecTypeVal:
            rec_typ*: RecTyp

        of RecVal:
            rec*: Rec

        of FunTypeVal:
            fun_typ*: FunTyp

        of FunVal:
            fun*: Fun

        of UniqueVal:
            inner*: Val

        of HoldVal:
            name*: string

        of NeuVal:
            neu*: Neu

        of NumVal:
            num*: int

        of MemVal:
            mem_ptr*: Val
            mem_typ*: Val
            wr*, rd*, imm*: bool

        of ExpVal:
            exp*: Exp 

    Val* = ref ValObj not nil

    Neu* = ref object
        head*: Val
        args*: seq[Val]

    Arg* = object
        name*: string
        value*: Val
        keyword*: bool

# Nim, why so much boilerplate :(

func Box*(x: Exp): Val = Val(kind: ExpVal, exp: x)
func Box*(x: Neu): Val = Val(kind: NeuVal, neu: x)
func Box*(x: int): Val = Val(kind: NumVal, num: x)
func Box*(x: Fun): Val = Val(kind: FunVal, fun: x)
func Box*(x: FunTyp): Val = Val(kind: FunTypeVal, fun_typ: x)
func Box*(x: Rec): Val = Val(kind: RecVal, rec: x)
func Box*(x: RecTyp): Val = Val(kind: RecTypeVal, rec_typ: x)

func Unique*(inner: Val): Val =
    Val(kind: UniqueVal, inner: inner)

func Universe*(level: int): Val =
    Val(kind: TypeVal, level: 0)

func UnionType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: UnionTypeVal, values: @values)

func InterType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: InterTypeVal, values: @values)

func Hold*(name: string): Val =
    Val(kind: HoldVal, name: name)

func MakeRec*(fields: varargs[RecField]): Rec =
    Rec(fields: @fields)

func MakeRecTyp*(slots: varargs[RecSlot], extensible = false, extension = None(Exp)): RecTyp =
    RecTyp(slots: @slots, extensible: extensible or extension.is_some, extension: extension)

func MakeFun*(typ: FunTyp, body: Exp, ctx: Ctx): Fun =
    Fun(typ: Some(typ), body: Left[Exp, BuiltinFunProc](body), ctx: Some(ctx))

func MakeFunTyp*(params: varargs[FunParam], ret: Exp): FunTyp =
    FunTyp(params: @params, result: ret)

# end of constructors

func noun*(v: Val): string =
    case v.kind
    of HoldVal: "variable"
    of NeuVal: "unevaluated call"
    of UniqueVal: "unique value"
    of NumVal: "number"
    of MemVal: "memory"
    of ExpVal: "expression"
    of TypeVal: "type"
    of UnionTypeVal: "union type"
    of InterTypeVal: "intersection type"
    of FunVal: "function"
    of FunTypeVal: "function type"
    of RecVal: "record"
    of RecTypeVal: "record type"

#
# Pretty-printing
#

func str*(v: Val): string

func `$`*(x: Val): string = x.str

func bold*(x: Exp): string = x.str.bold

func bold*(x: Val): string = x.str.bold

func str*(x: RecTyp): string =
    var res: seq[string]
    for s in x.slots:
        var repr = ""
        if s.name != "":
            repr &= s.name & ": "
        repr &= s.typ.str
        s.default.if_some(default):
            repr &= " = " & default.str
        res.add(repr)
    "Record(" & res.join(", ") & ")"

func str*(x: FunTyp): string =
    var prefix = ""
    if x.is_pure: prefix &= "pure "
    if x.is_macro: prefix &= "macro "
    var params: seq[string]
    for param in x.params:
        var s = param.name
        if not param.did_infer_typ: s &= ": " & param.typ.str
        param.default.if_some(default):
            s &= " = " & $default
        params.add(s)
    prefix & "(" & params.join(", ") & ") -> " & x.result.str

func str*(x: Rec): string =
    var res: seq[string]
    for f in x.fields:
        let prefix = if f.name == "": "" else: f.name & "="
        res.add(prefix & f.val.str)
    "(" & res.join(", ") & ")"

func str*(x: Arg): string =
    if not x.keyword: return x.value.str
    x.name & "=" & x.value.str

func str*(x: Neu): string =
    let head = if x.head.kind == FunVal and x.head.fun.name != "":
        x.head.fun.name
    else:
        x.head.str
    head & "(" & x.args.map(str).join(", ") & ")"

func str*(v: Val): string =
    case v.kind
    of HoldVal: "?" & v.name
    of NeuVal: v.neu.str
    of UniqueVal: "Unique(" & v.inner.str & ")"
    of NumVal: $v.num
    of MemVal: "Memory(...)"
    of ExpVal: "Expr(" & v.exp.str & ")"
    of TypeVal:
        if v.level == 0: "Type" else: "Type" & $v.level
    of UnionTypeVal, InterTypeVal:
        let op = if v.kind == UnionTypeVal: " | " else: " & "
        if v.values.len == 0:
            return if v.kind == UnionTypeVal: "Never" else: "Any"
        "(" & v.values.map(str).join(op) & ")"
    of FunVal:
        if v.fun.name.len > 0:
            v.fun.name
        else:
            "<lambda>"
    of FunTypeVal: v.fun_typ.str
    of RecVal: v.rec.str
    of RecTypeVal: v.rec_typ.str
