import options, tables
import exp, utils

{.warning[ProveInit]: off.}

type
    Var* = object
        val*, typ*: Opt[Val]
        site*: Opt[Exp]
        opaque*: bool
        arg*: bool
        capture*: bool

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
        depth*: int

    EvalMode* {.pure.} = enum
        Default, Norm, Unwrap

    Ctx* = ref object
        env*: Env
        eval_mode*: EvalMode
        site_stack*: seq[Exp]
        call_stack*: seq[TraceCall]

    VitaminError* = object of CatchableError
        node*: Exp
        ctx*: Ctx
        with_trace*: bool
        prefix*: string

    RecField* = object
        name*: string
        typ*: Exp
        default*: Exp # optional

    RecTyp* = object
        fields*: seq[RecField]
        extensible*: bool

    Rec* = object
        values*: Table[string, Val]

    BuiltinFunProc* = proc(ctx: Ctx, args: seq[Val]): Val

    FunParam* = object
        name*: string
        typ*: Exp
        variadic_typ*: Exp
        default*: Opt[Exp]
        quoted*: bool
        keyword*: bool
        variadic*: bool

    FunTyp* = object
        params*: seq[FunParam]
        result*: Exp
        #autoapply*: bool
        autoexpand*: bool

    FunInfo* = object
        #name*: string # may be empty (anonymous function)
        #typ*: Opt[FunTyp] # cannot be none at invocation
        discard

    Fun* = object
        body*: Either[Exp, BuiltinFunProc]
        ctx*: Opt[Ctx] # closure context
        builtin*: bool

    Mem* = object
        buf*: pointer

    ValTag* = enum
        NeverVal, NeuVal, RecVal, RecTypeVal, UnionTypeVal, InterTypeVal,
        TypeVal, ExpVal, MemVal, FunVal, FunTypeVal, ListLit
        NumLit, StrLit, I8, U8, I64, U64

    ValObj* = object
        case kind*: ValTag
        of NeverVal:
            discard
        of I8:
            i8*: int8
        of U8:
            u8*: uint8
        of I64:
            i64*: int64
        of U64:
            u64*: uint64
        of TypeVal:
            level*: int
        of ListLit, UnionTypeVal, InterTypeVal:
            values*: seq[Val]
        of RecTypeVal:
            rec_typ*: RecTyp
        of RecVal:
            rec*: Rec
        of FunTypeVal:
            fun_typ*: FunTyp
        of FunVal:
            fun*: Fun
        of NumLit, StrLit:
            lit*: string
        of MemVal:
            mem*: Mem
        of NeuVal, ExpVal:
            exp*: Exp 

    Val* = ref ValObj not nil

# Nim, why so much boilerplate :(

func Box*(x: Exp): Val = Val(kind: ExpVal, exp: x)
func Box*(x: Fun): Val = Val(kind: FunVal, fun: x)
func Box*(x: FunTyp): Val = Val(kind: FunTypeVal, fun_typ: x)
func Box*(x: Rec): Val = Val(kind: RecVal, rec: x)
func Box*(x: RecTyp): Val = Val(kind: RecTypeVal, rec_typ: x)

func Universe*(level: int): Val =
    Val(kind: TypeVal, level: 0)

func UnionType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: UnionTypeVal, values: @values)

func InterType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: InterTypeVal, values: @values)

func Neu*(exp: Exp): Val =
    Val(kind: NeuVal, exp: exp)

func Neu*(str: string): Val =
    Val(kind: NeuVal, exp: atom(str))

func is_never*(x: Val): bool = x.kind == NeverVal

#[
func MakeRec*(fields: varargs[RecField]): Rec =
    Rec(fields: @fields)

func MakeRecTyp*(slots: varargs[RecSlot], extensible = false, extension = None(Exp)): RecTyp =
    RecTyp(slots: @slots, extensible: extensible or extension.is_some, extension: extension)

func MakeFun*(typ: FunTyp, body: Exp, ctx: Ctx): Fun =
    Fun(typ: Some(typ), body: Left[Exp, BuiltinFunProc](body), ctx: Some(ctx))

func MakeFunTyp*(params: varargs[FunParam], ret: Exp): FunTyp =
    FunTyp(params: @params, result: ret)
]#

func MakeListLit*(values: varargs[Val]): Val =
    Val(kind: ListLit, values: @values)

# end of constructors

func noun*(v: Val): string =
    case v.kind
    of NeverVal: "unreachable"
    of I8, I64: "integer"
    of U8, U64: "unsigned integer"
    of ListLit: "list literal"
    of NumLit: "number literal"
    of StrLit: "string literal"
    of MemVal: "memory"
    of NeuVal: "neutral value"
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
    for s in x.fields:
        var repr = ""
        if s.name != "":
            repr &= s.name & ": "
        repr &= s.typ.str
        if not s.default.is_nil:
            repr &= " = " & s.default.str
        res &= repr
    "Record(" & res.join(", ") & ")"

func str*(x: FunTyp, ret = true): string =
    var params: seq[string]
    for param in x.params:
        var s = param.name
        s &= ": "
        if param.variadic: s &= "@variadic "
        if param.quoted: s &= "@quoted "
        s &= param.typ.str
        param.default.if_some(default):
            s &= " = " & $default
        params.add(s)
    var res_str = " -> "
    if x.autoexpand: res_str &= "@expand "
    res_str &= x.result.str
    result = "(" & params.join(", ") & ")"
    if ret: result &= res_str

func str*(x: Rec): string =
    var res: seq[string]
    for (name, val) in x.values.pairs:
        res.add(name & "=" & val.str)
    "(" & res.join(", ") & ")"

func str*(v: Val): string =
    case v.kind
    of NeverVal: "unreachable"
    of NeuVal: v.exp.str
    of I8: $v.i8
    of U8: $v.u8
    of I64: $v.i64
    of U64: $v.u64
    of NumLit, StrLit: v.lit
    of ListLit: "[" & v.values.map(str).join(" ") & "]"
    of MemVal: "Memory(...)"
    of ExpVal: v.exp.str_ugly
    of TypeVal:
        if v.level == 0: "Type" else: "Type" & $v.level
    of UnionTypeVal, InterTypeVal:
        let op = if v.kind == UnionTypeVal: " | " else: " & "
        if v.values.len == 0:
            return if v.kind == UnionTypeVal: "Never" else: "Any"
        v.values.map(str).join(op)
    of FunVal:
        if v.fun.body.is_left: "<lambda>" else: "<builtin>"
    of FunTypeVal: v.fun_typ.str
    of RecVal: v.rec.str
    of RecTypeVal: v.rec_typ.str
