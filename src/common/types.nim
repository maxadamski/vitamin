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
        in_macro*: bool
        site_stack*: seq[Exp]
        call_stack*: seq[TraceCall]
        vars*: Table[string, Var]

    VitaminError* = object of CatchableError
        node*: Exp
        env*: Env
        with_trace*: bool

    ValTag* = enum
        HoldVal, RecVal, RecTypeVal, UnionTypeVal, InterTypeVal,
        TypeVal, NumVal, ExpVal, MemVal, FunVal,
        FunTypeVal, BuiltinFunVal, OpaqueVal, UniqueVal,
        SymbolVal, SymbolTypeVal, SetTypeVal #, NeutralVal

    ValObj* = object
        typ*: Opt[Val]

        case kind*: ValTag
        of TypeVal:
            level*: int

        of SetTypeVal, UnionTypeVal, InterTypeVal:
            values*: seq[Val]

        of RecTypeVal:
            slots*: seq[RecSlot]
            extensible*: bool
            extension*: Opt[Exp]

        of RecVal:
            fields*: seq[RecField]

        of FunTypeVal:
            fun_typ*: FunTyp

        of FunVal:
            fun*: Fun

        of OpaqueVal:
            disp_name*: string
            result*: Val
            opaque_fun*: Fun
            bindings*: seq[(string, Val)]

        of HoldVal, SymbolVal, SymbolTypeVal:
            name*: string

        #of NeutralVal:
        #    neu*: Neutral

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

        of UniqueVal:
            inner*: Val

        of BuiltinFunVal:
            builtin_name*: string
            builtin_fun*: BuiltinFun
            builtin_typ*: Opt[FunTyp]

    Val* = ref ValObj not nil

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
        is_macro*: bool

    Fun* = object
        typ*: FunTyp
        body*: Exp
        env*: Opt[Env]

    RecSlot* = object
        name*: string
        typ*: Val
        default*: Opt[Exp]
        typ_inferred_from_default*: bool
        typ_inferred_from_position*: bool

    RecField* = object
        name*: string
        val*, typ*: Val

    BuiltinFun* = proc(env: Env, args: seq[Val]): Val