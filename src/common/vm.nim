import options, tables, strutils, sequtils, algorithm
import exp, utils, error, types

{.experimental: "notnil".}
{.warning[ProveInit]: off.}

func str*(v: Val): string

func `$`*(x: Val): string = x.str

proc equal*(x, y: Val): bool

# Nim, why so much boilerplate :(

func Number*(num: int): Val =
    Val(kind: NumVal, num: num)

func Hold*(name: string): Val =
    Val(kind: HoldVal, name: name)

#func VNeu*(neu: Neutral): Val = Val(kind: NeutralVal, neu: neu)

func UnionType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: UnionTypeVal, values: @values)

func InterType*(values: varargs[Val]): Val =
    if values.len == 1: return values[0]
    Val(kind: InterTypeVal, values: @values)

func SetType*(values: varargs[Val]): Val =
    Val(kind: SetTypeVal, values: @values)

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

func extend*(env: Env): Env =
    Env(parent: env)

func extend*(ctx: Ctx): Ctx =
    Ctx(
        env: ctx.env.extend(),
        site_stack: ctx.site_stack,
        call_stack: ctx.call_stack,
    )

func assume*(env: Env, name: string, typ: Val, site = None[Exp]()) =
    env.vars[name] = Var(val: None[Val](), typ: Some(typ), site: site)

func assume*(env: Env, name: string, typ: Val, site: Exp) =
    env.assume(name, typ, Some(site))

func define*(env: Env, name: string, val, typ: Val, site = None[Exp]()) =
    env.vars[name] = Var(val: Some(val), typ: Some(typ), site: site)

func define*(env: Env, name: string, val, typ: Val, site: Exp) =
    env.define(name, val, typ, Some(site))

func find*(env: Env, name: string): Env =
    if name in env.vars:
        env
    elif env.parent != nil:
        env.parent.find(name)
    else:
        nil

func site*(ctx: Ctx): Exp =
    if ctx.site_stack.len > 0:
        ctx.site_stack[^1]
    else:
        term()

func push_call*(ctx: Ctx, site: Exp, infer = false) =
    ctx.call_stack.add(TraceCall(site: site, infer: infer))

func pop_call*(ctx: Ctx) =
    discard ctx.call_stack.pop()

func get*(env: Env, name: string): Opt[Var] =
    if name in env.vars:
        Some(env.vars[name])
    elif env.parent != nil:
        env.parent.get(name)
    else:
        None[Var]()

func get_assumed*(env: Env, name: string): Opt[VarAssumed] =
    let variable = env.get(name).or_else:
        return None[VarAssumed]()
    let typ = variable.typ.or_else:
        return None[VarAssumed]()
        #raise error(ctx.site, "Expected variable {name} to be assumed or defined at this point. {ctx.site.src}".fmt)
    Some(VarAssumed(val: variable.val, typ: typ, site: variable.site))

proc get_defined*(env: Env, name: string): Opt[VarDefined] =
    let variable = env.get(name).or_else:
        return None[VarDefined]()
    let typ = variable.typ.or_else:
        return None[VarDefined]()
        #raise error(ctx.site, "Expected variable {name} to be typed at this point. {ctx.site.src}".fmt)
    let val = variable.val.or_else:
        return None[VarDefined]()
        #raise error(ctx.site, "Expected variable {name} to be defined at this point. {ctx.site.src}".fmt)
    Some(VarDefined(val: val, typ: typ, site: variable.site))

proc sets_inter*(xs, ys: seq[Val]): seq[Val] =
    for x in xs:
        if ys.any_it(equal(x, it)):
            result.add(x)

proc value_union*(xs, ys: seq[Val]): seq[Val] =
    result = xs
    for y in ys:
        if result.all_it(not equal(it, y)):
            result.add(y)

proc value_inter*(xs, ys: seq[Val]): seq[Val] =
    sets_inter(xs, ys)

proc value_set*(xs: seq[Val]): seq[Val] =
    for x in xs:
        if result.any_it(equal(x, it)):
            continue
        result.add(x)

proc sets_equal*(xs, ys: seq[Val]): bool =
    if xs.len != ys.len: return false
    for x in xs:
        block inner:
            for y in ys:
                if equal(x, y):
                    break inner
            return false
    true

proc norm_union*(args: varargs[Val]): Val =
    var sets: seq[Val]
    var types: seq[Val]
    for outer in args:
        var outer = outer
        # recursively normalize unions
        if outer.kind == UnionTypeVal:
            outer = norm_union(outer.values)
        case outer.kind
        of UnionTypeVal:
            # flatten union
            for inner in outer.values:
                case inner.kind
                of SetTypeVal:
                    sets.add(inner)
                else:
                    types.add(inner)
        of InterTypeVal:
            # X|Any = Any
            if outer.values.len == 0:
                return InterType()
            types.add(outer)
        of SetTypeVal:
            sets.add(outer)
        else:
            types.add(outer)

    # compute the union of value set types
    types = types.value_set
    if sets.len > 0:
        let values = sets.map_it(it.values).foldl(value_union(a, b))
        types.add(SetType(values.value_set))

    UnionType(types)

proc norm_inter*(args: varargs[Val]): Val =
    var sets: seq[Val]
    var types: seq[Val]
    var unions: seq[Val]
    for outer in args:
        var outer = outer
        # recursively normalize intersections
        if outer.kind == InterTypeVal:
            outer = norm_inter(outer.values)
        case outer.kind
        of InterTypeVal:
            # flatten intersections
            for inner in outer.values:
                case inner.kind
                of SetTypeVal:
                    sets.add(inner)
                else:
                    types.add(inner)
        of UnionTypeVal:
            # X&Never = Never
            if outer.values.len == 0:
                return UnionType()
            unions.add(outer)
        of SetTypeVal:
            sets.add(outer)
        else:
            types.add(outer)

    types = types.value_set

    # compute the intersection of value set types
    if sets.len > 0:
        let values = sets.map_it(it.values).foldl(value_inter(a, b))
        types.add(SetType(values))
    result = InterType(types)

    # intersections are distributive over unions
    if unions.len > 0:
        var inters: seq[Val]
        for union in unions:
            for union_val in union.values:
                inters.add(norm_inter(union_val, result))
        return norm_union(inters)
    return result

proc args_equal(xs, ys: seq[Arg]): bool =
    if xs.len != ys.len: return false
    for x in xs:
        if not ys.any_it(it == x): return false
    true

proc equal(x, y: Neu): bool =
    if x.args.len != y.args.len or not equal(x.head, y.head):
        return false
    for (u, v) in zip(x.args, y.args):
        if not equal(u, v):
            return false
    true

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

proc equal(x, y: Fun): bool =
    x.name == y.name

proc `==`*(x, y: RecTyp): bool =
    if x.slots.len != y.slots.len: return false
    let n = x.slots.len
    let sx = x.slots.sorted_by_it(it.name)
    let sy = y.slots.sorted_by_it(it.name)
    for i in 0..<n:
        if sx[i].name != sy[i].name or not equal(sx[i].typ, sy[i].typ): return false
    return true

proc `$`*(x: RecTyp): string =
    var res: seq[string]
    for s in x.slots:
        var repr = ""
        if s.name != "":
            repr &= s.name & ": "
        repr &= s.typ.str
        s.default.if_some(default):
            repr &= " = " & $default
        res.add(repr)
    "Record(" & res.join(", ") & ")"

proc equal*(x, y: Val): bool =
    #echo "{x.noun} {x} ?= {y.noun} {y}".fmt
    if x.kind == SetTypeVal and y.kind == UnionTypeVal or
       x.kind == UnionTypeVal and y.kind == SetTypeVal:
        if x.values.len == 0 and y.values.len == 0:
            return true
    if x.kind != y.kind: return false
    if x == y: return true
    case x.kind
    of TypeVal:
        x.level == y.level
    of UniqueVal:
        x == y
    of HoldVal, SymbolVal:
        x.name == y.name
    of SetTypeVal, UnionTypeVal, InterTypeVal:
        sets_equal(x.values, y.values)
    of FunTypeVal:
        equal(x.fun_typ, y.fun_typ)
    #of OpaqueVal:
    #    if x.disp_name != y.disp_name:
    #        return false
    #    for (x_name, x_val) in x.bindings:
    #        var found = false
    #        for (y_name, y_val) in y.bindings:
    #            if x_name == y_name:
    #                if equal(x_val, y_val):
    #                    found = true 
    #                    break
    #                else:
    #                    return false
    #        if not found:
    #            return false 
    #    return true
    of FunVal:
        equal(x.fun, y.fun)
    of RecVal:
        if x.fields.len != y.fields.len: return false
        for xf in x.fields:
            var found = false
            for yf in y.fields:
                if xf.name == yf.name:
                    if equal(xf.val, yf.val):
                        found = true 
                        break
                    else:
                        return false
            if not found:
                return false 
        return true

    of RecTypeVal:
        return x.rec_typ == y.rec_typ
    #of CastVal:
    #    return equal(x.val, y.val)
    of NumVal:
        return x.num == y.num
    of ExpVal:
        return x.exp == y.exp
    of NeuVal:
        equal(x.neu, y.neu)
    else:
        raise error(term(), "Equality for {x.noun} {x} and {y.noun} {y} not implemented".fmt)


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
    of SymbolVal, SymbolTypeVal:
        v.name

    of HoldVal:
        v.name

    of NeuVal:
        v.neu.str

    of SetTypeVal:
        "Set(" & v.values.map(str).join(", ") & ")"

    of UniqueVal:
        "Unique(" & v.inner.str & ")"

    #of CastVal:
    #    v.typ.str & "(" & v.val.str & ")"

    of NumVal:
        $v.num

    of MemVal:
        "Memory(...)"

    of ExpVal:
        "Expr(" & v.exp.str & ")"
        #case v.exp.kind:
        #of expAtom:
        #    v.exp.str
        #of expTerm:
        #    let exprs = v.exp.exprs
        #    if exprs.len == 0:
        #        "()"
        #    else:
        #        exprs[0].str & "(" & v.exp.tail.map(str).join(", ") & ")"

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

    #of OpaqueVal:
    #    var name = if v.disp_name != "": v.disp_name else: "Lambda(...)"
    #    var args: seq[string]
    #    for (key, val) in v.bindings:
    #        args.add(val.str)
    #    name & "(" & args.join(", ") & ")"

    of FunTypeVal:
        var prefix = ""
        if v.fun_typ.is_pure: prefix &= "pure "
        if v.fun_typ.is_opaque: prefix &= "opaque "
        if v.fun_typ.is_macro: prefix &= "macro "
        var params: seq[string]
        for param in v.fun_typ.params:
            var s = param.name
            if not param.did_infer_typ: s &= ": " & param.typ.str
            param.default.if_some(default):
                s &= " = " & $default
            params.add(s)
        prefix & "(" & params.join(", ") & ") -> " & v.fun_typ.result.str

    of RecVal:
        var res: seq[string]
        for x in v.fields:
            let prefix = if x.name == "": "" else: x.name & "="
            res.add(prefix & x.val.str)
        "(" & res.join(", ") & ")"

    of RecTypeVal:
        $v.rec_typ
