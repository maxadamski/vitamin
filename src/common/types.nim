import tables, sequtils, strutils
import exp, utils

{.warning[ProveInit]: off.}

type
    Var* = object
        val*, typ*: Opt[Val]
        site*: Opt[Exp]
        opaque*: bool
        arg*: bool
        capture*: bool
        definition*: Exp

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
        uses*: Table[string, seq[tuple[typ: Val, exp: Exp, ctx: Ctx]]]
        depth*: int

    EvalMode* {.pure.} = enum
        Default, Norm, Unwrap

    Ctx* = ref object
        env*: Env
        eval_mode*: EvalMode
        site_stack*: seq[Exp]
        call_stack*: seq[TraceCall]
        values*: seq[Val]
        names*: seq[string]
        types*: seq[Val]

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
        fields*: Table[string, RecField]

    Rec* = object
        ctx*: Ctx
        values*: Table[string, Val]

    BuiltinFunProc* = proc(ctx: Ctx, args: seq[Val]): Val

    BuiltinFun* = object
        fun*: BuiltinFunProc
        name*: string

    FunParam* = object
        name*: string
        typ*: Exp
        variadic_typ*: Exp
        default*: Opt[Exp]
        quoted*: bool
        keyword*: bool
        variadic*: bool

    FunTyp* = object
        ctx*: Ctx
        params*: seq[FunParam]
        result*: Exp
        #autoapply*: bool
        autoexpand*: bool

    FunInfo* = object
        #name*: string # may be empty (anonymous function)
        #typ*: Opt[FunTyp] # cannot be none at invocation
        discard

    Fun* = object
        params*: seq[string]
        body*: Exp
        ctx*: Ctx # closure context

    Mem* = object
        buf*: pointer

    ValTag* = enum
        NeverVal, OpaqueVal, NeuVal, RecVal, RecTypeVal, UnionTypeVal, InterTypeVal,
        TypeVal, ExpVal, MemVal, FunVal, FunTypeVal, ListLit, InterruptVal, BuiltinFunVal
        NumLit, StrLit, I8, U8, I64, U64

    ValObj* = object
        case kind*: ValTag
        of NeverVal, InterruptVal:
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
        of BuiltinFunVal:
            builtin_fun*: BuiltinFun
        of NumLit, StrLit:
            lit*: string
        of MemVal:
            mem*: Mem
        of OpaqueVal, NeuVal, ExpVal:
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
    of BuiltinFunVal: "builtin function"
    of InterruptVal: "interrupt"
    of I8, I64: "integer"
    of U8, U64: "unsigned integer"
    of ListLit: "list literal"
    of NumLit: "number literal"
    of StrLit: "string literal"
    of MemVal: "memory"
    of NeuVal: "stuck value"
    of OpaqueVal: "opaque value"
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

func str*(x: RecField): string =
    if x.name != "":
        result &= x.name & ": "
    result &= x.typ.str
    if not x.default.is_nil:
        result &= " = " & x.default.str

func str*(x: RecTyp): string =
    "Record{" & x.fields.values.to_seq.map(str).join(", ") & "}"

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
    of BuiltinFunVal: "<builtin " & v.builtin_fun.name & ">"
    of NeverVal: "unreachable"
    of InterruptVal: "interrupt"
    of OpaqueVal, NeuVal, ExpVal: v.exp.str
    of I8: $v.i8
    of U8: $v.u8
    of I64: $v.i64
    of U64: $v.u64
    of NumLit, StrLit: v.lit
    of ListLit: "[" & v.values.join(" ") & "]"
    of MemVal: "Memory(...)"
    of TypeVal:
        if v.level == 0: "Type" else: "Type" & $v.level
    of UnionTypeVal, InterTypeVal:
        let op = if v.kind == UnionTypeVal: " | " else: " & "
        if v.values.len == 0:
            return if v.kind == UnionTypeVal: "Never" else: "Any"
        v.values.map(str).join(op)
    of FunVal:
        "λ " & v.fun.params.join(" ") & " => ..."
    of FunTypeVal: v.fun_typ.str
    of RecVal: v.rec.str
    of RecTypeVal: v.rec_typ.str

#
# Context
#

func extend*(env: Env): Env =
    Env(parent: env, depth: env.depth + 1)

func extend*(ctx: Ctx, new_env = true, eval_mode: EvalMode): Ctx =
    Ctx(
        env: if new_env: ctx.env.extend() else: ctx.env,
        #env: ctx.env,
        eval_mode: eval_mode,
        site_stack: ctx.site_stack,
        call_stack: ctx.call_stack,
        names: ctx.names,
        types: ctx.types,
        values: ctx.values,
    )

func extend*(ctx: Ctx, new_env = true): Ctx =
    ctx.extend(new_env, ctx.eval_mode)

proc assume*(env: Env, name: string, typ: Val, site = None[Exp](), arg = false, definition = term()) =
    env.vars[name] = Var(val: None[Val](), typ: Some(typ), site: site, arg: arg, definition: definition)

proc define*(env: Env, name: string, val, typ: Val, site = None[Exp](), opaque = false, arg = false) =
    env.vars[name] = Var(val: Some(val), typ: Some(typ), site: site, opaque: opaque, arg: arg)

proc value_by_index*(ctx: Ctx, i: int): Val =
    ctx.values[ctx.values.high - i]

proc type_by_index*(ctx: Ctx, i: int): Val =
    ctx.types[ctx.values.high - i]

proc index_by_name*(ctx: Ctx, name: string): int =
    for level in countdown(ctx.names.high, 0):
        if ctx.names[level] == name:
            return ctx.names.high - level
    return -1

proc find*(env: Env, name: string): Env =
    var env = env
    while env != nil:
        if name in env.vars: return env
        env = env.parent
    nil

#proc use*(env: Env, record: Rec) =
#    env.uses[]

proc site*(ctx: Ctx): Exp =
    if ctx.site_stack.len > 0:
        ctx.site_stack[^1]
    else:
        term()

proc push_call*(ctx: Ctx, site: Exp, infer = false) =
    ctx.call_stack.add(TraceCall(site: site, infer: infer))

proc pop_call*(ctx: Ctx) =
    discard ctx.call_stack.pop()

proc use*(env: Env, name: string, typ: Val, exp: Exp, ctx: Ctx) =
    let x = (typ, exp, ctx)
    if name notin env.uses:
        env.uses[name] = @[x]
    else:
        env.uses[name] &= x

#[
proc push_value*(ctx: Ctx, val: Val) =
    ctx.values.add(val)

proc pop_value*(ctx: Ctx) =
    discard ctx.values.pop()

proc push_type*(ctx: Ctx, name: string, typ: Val) =
    ctx.names.add(name)
    ctx.types.add(typ)

proc pop_type*(ctx: Ctx) =
    discard ctx.names.pop()
    discard ctx.types.pop()
]#
