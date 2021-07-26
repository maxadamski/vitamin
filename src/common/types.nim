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
            fields*: seq[RecField]

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

    RecSlot* = object
        name*: string
        typ*: Exp
        default*: Opt[Exp]
        typ_inferred_from_default*: bool
        typ_inferred_from_position*: bool

    RecField* = object
        name*: string
        val*, typ*: Val

# Nim, why so much boilerplate :(

func Unique*(inner: Val): Val =
    Val(kind: UniqueVal, inner: inner)

func Universe*(level: int): Val =
    Val(kind: TypeVal, level: 0)

func Box*(x: Fun): Val =
    Val(kind: FunVal, fun: x)

func Box*(x: Exp): Val =
    Val(kind: ExpVal, exp: x)

func Box*(x: Neu): Val =
    Val(kind: NeuVal, neu: x)

func Number*(num: int): Val =
    Val(kind: NumVal, num: num)

func Hold*(name: string): Val =
    Val(kind: HoldVal, name: name)

func UnionType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: UnionTypeVal, values: @values)

func InterType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: InterTypeVal, values: @values)

func Record*(fields: varargs[RecField]): Val =
    Val(kind: RecVal, fields: @fields)

func RecordType*(slots: varargs[RecSlot], extensible = false, extension = None(Exp)): Val =
    Val(kind: RecTypeVal, rec_typ: RecTyp(slots: @slots, extensible: extensible or extension.is_some, extension: extension))

func LambdaType*(params: varargs[FunParam], ret: Exp): FunTyp =
    FunTyp(params: @params, result: ret)

func LambdaType*(typ: FunTyp): Val =
    Val(kind: FunTypeVal, fun_typ: typ)

proc Lambda*(typ: FunTyp, body: Exp, ctx: Ctx): Val =
    Val(kind: FunVal, fun: Fun(typ: Some(typ), body: Left[Exp, BuiltinFunProc](body), ctx: Some(ctx)))

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