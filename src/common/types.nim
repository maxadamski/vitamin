import options, tables
import exp, utils

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
        HoldVal, RecVal, RecTypeVal, UnionTypeVal, InterTypeVal,
        TypeVal, NumVal, ExpVal, MemVal, FunVal,
        FunTypeVal, UniqueVal,
        SymbolVal, SymbolTypeVal, SetTypeVal, NeuVal,
        #OpaqueVal

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
        is_opaque*: bool
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

        of SetTypeVal, UnionTypeVal, InterTypeVal:
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

        #of OpaqueVal:
        #    disp_name*: string
        #    result*: Val
        #    bindings*: seq[(string, Val)]

        of HoldVal, SymbolVal, SymbolTypeVal:
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

func noun*(v: Val): string =
    case v.kind
    of SymbolVal: "symbol"
    of SymbolTypeVal: "type"
    of HoldVal: "variable"
    of NeuVal: "unevaluated call"
    of SetTypeVal: "set type"
    of UniqueVal: "value"
    #of OpaqueVal: ""
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