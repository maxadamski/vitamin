import options, tables, sets, sequtils, strformat, strutils
import common/[exp, error, utils, types]

type
    TypedExp = tuple[exp: Exp, typ: Val]

# TODO: Allow access to the expression stack in macros

{.warning[ProveInit]: off.}
#{.experimental: "codeReordering".}

#
# Boilerplate forward declarations :/
#

proc is_subtype*(ctx: Ctx, x, y: Val): bool

# check : surface type -> core
proc check*(ctx: Ctx, exp: Exp, typ: Opt[Val] = None(Val)): TypedExp

# synth : surface -> core type
proc check*(ctx: Ctx, exp: Exp, typ: Val): TypedExp = ctx.check(exp, Some(typ))

# eval : core -> value
proc eval*(ctx: Ctx, exp: Exp): Val

# reify : value -> core
func reify*(val: Val): Exp

# equal : value value -> core
func `==`*(x, y: Val): bool

func equal*(x, y: Val): bool = x == y

proc infer_type*(ctx: Ctx, exp: Exp): Val =
    ctx.check(exp).typ

proc unwrap*(ctx: Ctx, exp: Exp): Val =
    let new_ctx = ctx.extend(new_env=false, eval_mode=EvalMode.Unwrap)
    new_ctx.eval(exp)

proc norm*(ctx: Ctx, exp: Exp): Exp =
    let new_ctx = ctx.extend(new_env=false, eval_mode=EvalMode.Norm)
    new_ctx.eval(exp).reify

proc norm_all*(ctx: Ctx, exps: seq[Exp]): seq[Exp] =
    exps.map_it(ctx.norm(it))

proc eval_all*(ctx: Ctx, exps: seq[Exp]): seq[Val] =
    exps.map_it(ctx.eval(it))

proc eval_core*(ctx: Ctx, exp: Exp): Val =
    ctx.eval(exp)

proc eval_surface*(ctx: Ctx, exp: Exp): Val =
    #echo "eval surface " & exp.str
    let local = ctx.extend()
    let (core_exp, _) = local.check(exp)
    ctx.eval(core_exp)

#
# Glooobals
#

var next_gensym_id = 0
var next_name_uid: Table[string, int]
let type0* = Universe(0)
let type1* = Universe(1)
let never* = UnionType()
let unreachable* = Val(kind: NeverVal)
let unit* = Box(Rec())
let unit_type* = Box(RecTyp())
let expr_type* = UnionType(Neu("Atom".atom), Neu("Term".atom))
let never_type* = UnionType()
let any_type* = InterType()
var BUILTINS = initTable[string, Val]()

proc gensym(prefix = "__"): string =
    next_gensym_id += 1
    return prefix & $next_gensym_id

proc genuid(name: string): int =
    if name notin next_name_uid:
        next_name_uid[name] = 0
    result = next_name_uid[name]
    next_name_uid[name] += 1

func strip_quotes(s: string): string =
    s[1 ..< ^1]

func basic_str(x: string): string =
    x.strip_quotes.multi_replace(("\\n", "\n"), ("\\t", "\t"), ("\\\"", "\""), ("\\'", "'"))


#
# Unions & intersections
#

func sets_inter*(xs, ys: seq[Val]): seq[Val] =
    for x in xs:
        if ys.any_it(x == it):
            result.add(x)


func value_union*(xs, ys: seq[Val]): seq[Val] =
    result = xs
    for y in ys:
        if result.all_it(it != y):
            result.add(y)


func value_inter*(xs, ys: seq[Val]): seq[Val] =
    sets_inter(xs, ys)


func value_set*(xs: seq[Val]): seq[Val] =
    for x in xs:
        if result.any_it(x == it):
            continue
        result.add(x)


func sets_equal*(xs, ys: seq[Val]): bool =
    if xs.len != ys.len: return false
    for x in xs:
        block inner:
            for y in ys:
                if x == y:
                    break inner
            return false
    true


func norm_union*(args: varargs[Val]): Val =
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
                types.add(inner)
        of InterTypeVal:
            # X|Any = Any
            if outer.values.len == 0:
                return InterType()
            types.add(outer)
        else:
            types.add(outer)

    UnionType(types.value_set)


func norm_inter*(args: varargs[Val]): Val =
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
                types.add(inner)
        of UnionTypeVal:
            # X&Never = Never
            if outer.values.len == 0:
                return UnionType()
            unions.add(outer)
        else:
            types.add(outer)

    result = InterType(types.value_set)

    # intersections are distributive over unions
    if unions.len > 0:
        var inters: seq[Val]
        for union in unions:
            for union_val in union.values:
                inters.add(norm_inter(union_val, result))
        return norm_union(inters)
    return result


proc eval_union*(ctx: Ctx, args: seq[Val]): Val =
    if args[0].kind != ListLit:
        raise error("Runtime error: {args[0]} is not a list.".fmt)
    let args = args[0].values
    if args.len == 0: return UnionType()
    if args.len == 1: return args[0]
    return norm_union(args)


proc eval_inter*(ctx: Ctx, args: seq[Val]): Val =
    if args[0].kind != ListLit:
        raise error("Runtime error: {args[0]} is not a list.".fmt)
    let args = args[0].values 
    if args.len == 0: return InterType()
    if args.len == 1: return args[0]
    return norm_inter(args)


#
# Value equality & subtyping
#

func `==`*(x, y: Exp): bool =
    if x.kind != y.kind: return false
    case x.kind
    of expAtom:
        x.value == y.value
    of expTerm:
        if x.len != y.len: return false
        for (a, b) in zip(x.exprs, y.exprs):
            if a != b: return false
        return true


func `==`(x, y: Fun): bool =
    x == y


func `==`(x, y: FunTyp): bool =
    if x.params.len != y.params.len: return false
    var (a_res, b_res) = (x.result, y.result)
    for i, (ai, bi) in zip(x.params, y.params):
        var (a_typ, b_typ) = (ai.typ, bi.typ)
        #for j, (aj, bj) in zip(x.params[0 ..< i], y.params[0 ..< i]):
            #a_typ = substitute(a_typ, aj.name, reserved_atom($j))
            #b_typ = substitute(b_typ, bj.name, reserved_atom($j))
        if a_typ != b_typ: return false
        #a_res = substitute(a_res, ai.name, reserved_atom($i))
        #b_res = substitute(b_res, bi.name, reserved_atom($i))
    a_res == b_res


func `==`(x, y: Rec): bool =
    x.values == y.values


func `==`(x, y: RecTyp): bool =
    if x.fields.len != y.fields.len: return false
    for label in x.fields.keys:
        if label notin y.fields or x.fields[label].typ != y.fields[label].typ: return false
    true


func `==`(x, y: seq[Val]): bool =
    if x.len != y.len: return false
    for (a, b) in zip(x, y):
        if a != b: return false
    true


func `==`*(x, y: Val): bool =
    if x.kind in {OpaqueVal, NeuVal} and y.kind in {OpaqueVal, NeuVal}:
        return x.exp == y.exp
    if x.kind != y.kind: return false
    case x.kind
    of InterruptVal: false
    of NeverVal: true
    of BuiltinFunVal: x.builtin_fun.name == y.builtin_fun.name
    of TypeVal: x.level == y.level
    of UnionTypeVal, InterTypeVal: sets_equal(x.values, y.values)
    of ListLit: x.values == y.values
    of MemVal: x.mem.buf == y.mem.buf
    of FunTypeVal: x.fun_typ == y.fun_typ
    of FunVal: x.fun == y.fun
    of RecVal: x.rec == y.rec
    of RecTypeVal: x.rec_typ == y.rec_typ
    of NumLit, StrLit: x.lit == y.lit
    of OpaqueVal, NeuVal, ExpVal: x.exp == y.exp
    of I8: x.i8 == y.i8
    of U8: x.u8 == y.u8
    of I64: x.i64 == y.i64
    of U64: x.u64 == y.u64


proc unify_lambda_type(ctx: Ctx, x, y: FunTyp): bool =
    if x.params.len != y.params.len: return false
    # FIXME: sort topologically by dependency order
    let xctx = ctx.extend()
    let yctx = ctx.extend()
    for (xp, yp) in zip(x.params, y.params):
        let xt = xctx.eval(xp.typ)
        if not xctx.is_subtype(yctx.eval(yp.typ), xt): return false
        xctx.env.assume(xp.name, xt)
        yctx.env.assume(yp.name, xt)
    return xctx.is_subtype(xctx.eval(x.result), yctx.eval(y.result))


proc is_subtype*(ctx: Ctx, x, y: Val): bool =
    # is x a subtype of y
    #let x = if x.kind == NeuVal: ctx.eval(x.exp) else: x
    #let y = if y.kind == NeuVal: ctx.eval(y.exp) else: y
    if x.kind == y.kind:
        case x.kind
        of UnionTypeVal:
            if x.values == y.values: return true
            return sets_inter(x.values, y.values).len > 0
        of InterTypeVal:
            if x.values == y.values: return true
            return value_set(x.values & y.values).len > x.values.len
        of RecTypeVal:
            # are fields of `y` a subset of fields of `x`
            let x_fields = x.rec_typ.fields
            let y_fields = y.rec_typ.fields
            let local = ctx.extend()
            for label in y_fields.keys:
                if label notin x_fields: return false
                let (fx, fy) = (x_fields[label], y_fields[label])
                let (tx, ty) = (local.eval(fx.typ), local.eval(fy.typ))
                if tx != ty: return false
                local.env.assume(label, tx)
            return true
        of FunTypeVal:
            return ctx.unify_lambda_type(x.fun_typ, y.fun_typ)
        else:
            discard
    if y.kind == UnionTypeVal:
        return y.values.any_it(ctx.is_subtype(x, it))
    if y.kind == InterTypeVal:
        return y.values.all_it(ctx.is_subtype(x, it))
    return x == y


#
# Elaborating type checking
#


proc check_universe_level(ctx: Ctx, exp: Exp): tuple[exp: Exp, level: int] =
    let (core_exp, typ) = ctx.check(exp)
    if typ.kind != TypeVal:
        raise error("Expression {exp} needs to have type Type, but got {typ}. {exp.src}".fmt)
    (core_exp, typ.level)


proc check_universe(ctx: Ctx, exp: Exp): Exp =
    ctx.check_universe_level(exp).exp


proc check_apply_lambda(ctx: Ctx, exp: Exp, want_typ: Opt[Val]): TypedExp =
    let (head, tail) = (exp[0], exp.tail)

    let (head_core, head_typ) = ctx.check(head)
    if head_typ.kind != FunTypeVal:
        raise error("Expression {head} of type {head_typ} is not callable. {head.src}".fmt)
    let head_val = ctx.eval(head_core)

    let UNSET = 0
    let DEFAULT = 1
    let DONE = 2
    let typ = head_typ.fun_typ
    let par_count = typ.params.len
    var par_name = typ.params.map_it(it.name)
    var arg_norm = new_seq[Exp](par_count)
    var par_done = new_seq[int](par_count)
    var arg_done = new_seq[bool](tail.len)
    var par_default = new_seq[bool](par_count)
    var variadic_par = -1
    var variadic_arg : seq[Exp]

    for i, par in typ.params:
        if par.variadic:
            variadic_par = i
            par_done[i] = DEFAULT
        par.default.if_some(arg_default):
            arg_norm[i] = arg_default
            par_done[i] = DEFAULT
            par_default[i] = true

    for i, arg in tail:
        if arg.has_prefix("="):
            if arg[1].kind != expAtom:
                raise ctx.error(exp=arg, msg="Parameter name must be an atom, but got {arg[1].bold}. {exp.src}".fmt)
            let key = arg[1].value
            let val = arg[2]
            let par_index = par_name.find(key)
            if par_index == -1:
                raise ctx.error(exp=arg, msg="No parameter named {key.bold}. {exp.src}".fmt)
            if par_done[par_index] == DONE:
                raise ctx.error(exp=arg, msg="Duplicate argument {key.bold}. {exp.src}".fmt)
            arg_norm[par_index] = val
            par_done[par_index] = DONE
            arg_done[i] = true
            par_default[i] = false

    for i, arg in tail:
        if arg_done[i]: continue
        let par_index = par_done.find(UNSET)
        if par_index == -1:
            if variadic_par == -1:
                raise ctx.error(exp=arg, msg="Extraneous argument {arg.bold}. {exp.src}".fmt)
            variadic_arg.add(arg)
            arg_done[i] = true
            continue
        arg_norm[par_index] = arg
        par_done[par_index] = DONE
        arg_done[i] = true

    for i, par in typ.params:
        if par_done[i] == UNSET:
            raise ctx.error(exp=exp, msg="Missing argument for parameter {par.name.bold} of type {par.typ.bold}. {exp.src}".fmt)

    for i, par in typ.params:
        if par.quoted:
            arg_norm[i] = term(atom("quote"), arg_norm[i])

    if variadic_par != -1 and typ.params[variadic_par].quoted:
        variadic_arg = variadic_arg.map_it(term(atom("quote"), it))

    # evaluate argument in current context
    let ctx = ctx.extend()
    # evaluate parameter type in function definition context
    let local = typ.ctx.extend()
    for i, (arg, par) in zip(arg_norm, typ.params):
        if par.variadic:
            let par = typ.params[variadic_par]
            let variadic_typ = ctx.eval(par.variadic_typ)
            for arg in variadic_arg.mitems:
                let (arg_exp, arg_typ) = ctx.check(arg)
                if not ctx.is_subtype(arg_typ, variadic_typ):
                    raise ctx.error(exp=arg, msg="Value for variadic parameter {par.name.bold} must be of type {variadic_typ.bold}, but got {arg.bold} of type {arg_typ.bold}. {exp.src}".fmt)
                arg = arg_exp
            arg_norm[i] = term(atom("Core/list") & variadic_arg)
            local.env.define(par.name, ctx.eval(arg_norm[i]), local.eval(par.typ))
        elif par_default[i]:
            let par_typ = local.eval(par.typ)
            local.env.define(par.name, ctx.eval(arg), par_typ)
        else:
            let par_typ = local.eval(par.typ)
            #echo fmt"check arg {arg} : {par_typ}"
            let (arg_exp, arg_typ) = ctx.check(arg, par_typ)
            #if not ctx.is_subtype(arg_typ, par_typ):
            #    raise ctx.error(exp=arg, msg="Value for parameter {par.name.bold} must be of type {par_typ.bold}, but got {arg.bold} of type {arg_typ.bold}. {exp.src}".fmt)
            arg_norm[i] = arg_exp
            local.env.define(par.name, ctx.eval(arg_exp), par_typ) # TODO: De Brujin

    var core_exp = term("Core/apply".atom, term(head_core & arg_norm))
    var result_typ = local.eval(typ.result)

    if want_typ.is_some and not local.is_subtype(result_typ, want_typ.unsafe_get):
        raise type_error("Expected call {exp} to be of type {want_typ.unsafe_get}, but it had type {result_typ}. {exp.src}".fmt)

    if typ.autoexpand:
        let macro_result = ctx.eval(core_exp)
        if macro_result.kind != ExpVal:
            raise compiler_defect("Macro didn't return an expression! Got {macro_result.noun} {macro_result} {exp.src}".fmt)
        (core_exp, result_typ) = ctx.check(macro_result.exp, want_typ)

    return (core_exp, want_typ ?? result_typ)


proc synth_lambda(ctx: Ctx, exp: Exp): TypedExp =
    let ctx = ctx.extend()
    var core_exp = term("Core/lambda".atom)
    var typ : FunTyp
    typ.ctx = ctx

    for typ_part in exp.exprs:
        if typ_part.has_prefix("#param"):
            var par = FunParam(name: typ_part[1].value)
            var core_par = term("#param".atom, typ_part[1])
            for par_part in typ_part.exprs:
                if par_part.has_prefix("#type"):
                    par.typ = par_part[1]
                elif par_part.has_prefix("#default"):
                    par.default = Some(par_part[1])
                elif par_part.is_atom("#quoted"):
                    par.quoted = true
                    core_par &= par_part
                elif par_part.has_prefix("#variadic"):
                    par.variadic = true
                    par.variadic_typ = ctx.check_universe(par_part[1])
                    core_par &= term("#variadic".atom, par.variadic_typ)

            var default_typ = None(Val)
            if par.default.is_some:
                let (e, t) = ctx.check(par.default.unsafe_get)
                core_par &= term("#default".atom, e)
                default_typ = Some(t)

            if par.typ.is_nil:
                if par.default.is_none:
                    raise error("Type of parameter {par.name} is ambiguous in this context. {typ_part.src}".fmt)
                par.typ = reify(default_typ.unsafe_get)

            par.typ = ctx.check_universe(par.typ)
            core_par &= term("#type".atom, par.typ)

            ctx.env.assume(par.name, ctx.eval(par.typ)) # TODO: De Brujin
            typ.params.add(par)
            core_exp &= core_par
            
        elif typ_part.has_prefix("#result"):
            typ.result = ctx.check_universe(typ_part[1])
            core_exp &= term("#result".atom, typ.result)

        elif typ_part.has_prefix("#body"):
            if typ.result.is_nil:
                let (body, res) = ctx.check(typ_part[1])
                typ.result = reify(res)
                core_exp &= term("#result".atom, typ.result)
                core_exp &= term("#body".atom, body)
            else:
                let body = ctx.check(typ_part[1], ctx.eval(typ.result)).exp
                core_exp &= term("#body".atom, body)
        
        elif typ_part.is_atom("#expand"):
            core_exp &= typ_part
            typ.autoexpand = true
    
    (core_exp, Val(kind: FunTypeVal, fun_typ: typ))


proc check_lambda(ctx: Ctx, exp: Exp, want_typ: Val): Exp =
    type ParamInfo = tuple[name, typ, default: Exp, quoted: bool]
    if want_typ.kind != FunTypeVal:
        raise type_error("{want_typ.noun} {want_typ} is not a function type".fmt)
    let fun_typ = want_typ.fun_typ
    var params : seq[ParamInfo]
    var body, ret : Exp
    var expand = false
    var core = term("Core/lambda".atom)

    for typ_part in exp.exprs:
        if typ_part.has_prefix("#param"):
            var par : ParamInfo
            par.name = typ_part[1]
            for par_part in typ_part.exprs[2 .. ^1]:
                if par_part.has_prefix("#type"): par.typ = par_part[1]
                elif par_part.has_prefix("#default"): par.default = par_part[1]
                elif par_part.is_atom("#quote"): par.quoted = true
            params &= par
        elif typ_part.has_prefix("#body"): body = typ_part[1]
        elif typ_part.has_prefix("#result"): ret = typ_part[1]
        elif typ_part.has_prefix("#expand"): expand = true

    if fun_typ.params.len != params.len:
        raise type_error("Expected function with {fun_typ.params.len} parameters, but got {params.len}. {exp.src}")

    # TODO: De Brujin
    let ctx = ctx.extend()
    let want_ctx = ctx.extend()
    for (want_par, par) in zip(fun_typ.params, params):
        var (name, typ, default, quoted) = par
        var want_typ_val = want_ctx.eval(want_par.typ)
        var typ_val : Val
        if not typ.is_nil:
            typ = ctx.check_universe(typ)
            typ_val = ctx.eval(typ)
            if not ctx.is_subtype(typ_val, want_typ_val):
                raise type_error("Parameter type {typ_val} is not a subtype of {want_typ_val}. {typ}".fmt)
        else:
            typ = want_par.typ
            typ_val = want_typ_val

        if not default.is_nil:
            default = ctx.check(default, typ_val).exp

        ctx.env.assume(name.value, want_typ_val)
        want_ctx.env.assume(want_par.name, want_typ_val)

        var param = term("#param".atom, name)
        if not typ.is_nil: param &= term("#type".atom, typ)
        if not default.is_nil: param &= term("#default".atom, default)
        if quoted: param &= atom("#quoted")
        core &= param

    if ret.is_nil:
        var ret_val : Val
        (body, ret_val) = ctx.check(body)
        ret = ret_val.reify
    else:
        ret = ctx.check_universe(ret)
        body = ctx.check(body, ctx.eval(ret)).exp

    core &= term("#result".atom, fun_typ.result)
    core &= term("#body".atom, body)
    core


proc synth_lambda_type(ctx: Ctx, exp: Exp): TypedExp =
    let ctx = ctx.extend()
    var core = term("Core/Lambda".atom)
    var univ = 0
    for typ_part in exp.exprs:
        if typ_part.has_prefix("#param"):
            var par_name = typ_part[1]
            var core_par = term("#param".atom, par_name)
            var par_typ, par_default : Exp
            for par_part in typ_part[2 .. ^1]:
                if par_part.has_prefix("#type"): par_typ = par_part[1]
                elif par_part.has_prefix("#default"): par_default = par_part[1]
                elif par_part.is_atom("#quoted"): core_par &= par_part
                elif par_part.has_prefix("#variadic"): core_par &= term("#variadic".atom, ctx.check_universe(par_part[1]))
                else: core_par &= par_part
            
            var default_typ = None(Val)
            if not par_default.is_nil:
                let (e, t) = ctx.check(par_default)
                core_par &= term("#default".atom, e)
                default_typ = Some(t)

            if par_typ.is_nil:
                if default_typ.is_none:
                    raise error("Type of parameter {par_name} is ambiguous in this context. {typ_part.src}".fmt)
                par_typ = reify(default_typ.unsafe_get)

            let (par_typ_core, par_typ_universe) = ctx.check_universe_level(par_typ)
            univ = max(univ, par_typ_universe)
            par_typ = par_typ_core
            core_par &= term("#type".atom, par_typ)
            core &= core_par

            ctx.env.assume(par_name.value, ctx.eval(par_typ_core)) # TODO: De Brujin

        elif typ_part.has_prefix("#result"):
            let (ret_typ_core, ret_typ_universe) = ctx.check_universe_level(typ_part[1])
            univ = max(univ, ret_typ_universe)
            core &= term("#result".atom, ret_typ_core)
        
        elif typ_part.is_atom("#expand"):
            core &= typ_part

    (core, Val(kind: TypeVal, level: univ))


proc check_lambda_type(ctx: Ctx, exp: Exp, want_typ: Val): Exp =
    raise compiler_defect("Downwards checking for lambda type {exp} not implemented! {exp.src}".fmt)
    #var core = term("Core/Lambda".atom)
    #core


proc synth_record_type(ctx: Ctx, exp: Exp): tuple[exp: Exp, typ: Val] =
    var core = term("Core/Record".atom)
    var univ = 0
    var ctx = ctx.extend()

    for part in exp.tail:
        if part.has_prefix("#field"):
            let name = part[1]
            var field_core = term("#field".atom, name)
            for field_part in part[2 .. ^1]:
                if field_part.has_prefix("#type"):
                    let (typ_core, typ_univ) = ctx.check_universe_level(field_part[1])
                    univ = max(univ, typ_univ)
                    field_core &= term("#type".atom, typ_core)
                    ctx.env.assume(name.value, ctx.eval(typ_core)) # TODO: De Brujin?

                elif field_part.has_prefix("#default"):
                    let (default_core, default_typ) = ctx.check(field_part[1])
                    # TODO: ensure that default_typ <: field_typ
                    field_core &= term("#default".atom, default_core)
                    ctx.env.assume(name.value, default_typ)

            core &= field_core
        else:
            assert false

    (core, Val(kind: TypeVal, level: univ))


proc check_record_type(ctx: Ctx, exp: Exp, want_typ: Val): Exp =
    raise compiler_defect("Downwards checking for record type {exp} not implemented! {exp.src}".fmt)


proc synth_record(ctx: Ctx, exp: Exp): tuple[exp: Exp, typ: Val] =
    #echo "synth record"
    var core = term("Core/record".atom)
    var rec_typ : RecTyp
    let ctx = ctx.extend()
    for part in exp.tail:
        #echo "   " & $part
        if part.has_prefix("#def"):
            var (name, val, typ) = (part[1], part[2], part[3])
            var val_typ : Val
            if val.is_nil and not typ.is_nil:
                typ = ctx.check_universe(typ)
                val_typ = ctx.eval(typ)
            elif not val.is_nil and typ.is_nil:
                (val, val_typ) = ctx.check(val)
                typ = val_typ.reify
            elif not val.is_nil and not typ.is_nil:
                val_typ = ctx.eval(ctx.check_universe(typ))
                val = ctx.check(val, val_typ).exp
                typ = val_typ.reify

            if not val.is_nil:
                ctx.env.define(name.value, ctx.eval(val), val_typ)
            else:
                ctx.env.assume(name.value, val_typ)
            rec_typ.fields[name.value] = RecField(name: name.value, typ: typ)
            core &= term("#def".atom, name, val, typ)
        else:
            #echo "eval in record " & $part
            discard ctx.eval_surface(part)
    (core, Val(kind: RecTypeVal, rec_typ: rec_typ))


proc check_record(ctx: Ctx, exp: Exp, want_typ: Val): Exp =
    if want_typ.kind != RecTypeVal:
        raise type_error("Can't type check if record is of type {want_typ}, because {want_typ.noun} {want_typ} is not a record type. {exp.src}".fmt)

    result = term("Core/record".atom)
    let ctx = ctx.extend()

    var field_values : Table[string, tuple[name, value, typ: Exp]] 
    for part in exp.tail:
        if part.has_prefix("#def"):
            field_values[part[1].value] = (part[1], part[2], part[3])

    for label, field in want_typ.rec_typ.fields:
        var name, value : Exp
        var want_field_typ = ctx.eval(field.typ)
        var typ : Val
        if field.name notin field_values:
            if field.default.is_nil:
                raise type_error("Missing value for field {field.name} of type {field.typ}. {exp.src}".fmt)
            (name, value, typ) = (field.name.atom, field.default, want_typ)
        else:
            (name, value) = field_values[field.name]
            (value, typ) = ctx.check(value, want_field_typ)

        ctx.env.define(field.name, ctx.eval(value), typ)
        result &= term("#def".atom, name, value, typ.reify)


proc check_apply(ctx: Ctx, exp: Exp, typ: Opt[Val]): TypedExp =
    let (_, head_typ) = ctx.check(exp.head)
    case head_typ.kind
    of FunTypeVal:
        return ctx.check_apply_lambda(exp, typ)
    else:
        raise type_error(msg="Expression {exp.head.bold} of type {head_typ.bold} is not callable. {exp.src}".fmt)


proc check_block*(ctx: Ctx, exp: Exp): Val =
    result = unit_type
    for stat in exp.tail:
        result = ctx.infer_type(stat)


proc check_num(ctx: Ctx, exp: Exp, typ: Val): TypedExp =
    if typ == Neu("Num-Literal".atom): return (exp, Neu("Num-Literal".atom))
    if typ == Neu("I64".atom): return (term("num-i64".atom, exp), Neu("I64".atom))
    if typ == Neu("U64".atom): return (term("num-u64".atom, exp), Neu("U64".atom))
    if typ == Neu("I8".atom): return (term("num-i8".atom, exp), Neu("I8".atom))
    if typ == Neu("U8".atom): return (term("num-u8".atom, exp), Neu("U8".atom))
    raise type_error("Can't convert number literal {exp} to type {typ}. {exp.src}".fmt)

proc check_builtin(ctx: Ctx, exp: Exp, typ: Val): TypedExp =
    if exp[1].kind != expAtom or exp[1].tag != aStr: 
        raise type_error("Builtin must be a string literal. {exp[1].src}".fmt)
    let builtin = exp[1].value.strip_quotes
    if builtin notin BUILTINS:
        raise type_error("No builtin named {builtin}. {exp[1].src}".fmt)
    return (term("Core/builtin".atom, builtin.atom), typ)

proc synth_assume(ctx: Ctx, exp: Exp): TypedExp =
    let name = exp[1].value
    let typ_exp = ctx.check_universe(exp[2])
    let typ_val = ctx.eval(typ_exp)
    ctx.env.assume(name, typ_val, site=Some(exp)) # TODO: De Brujin
    #exp[2] = typ_exp
    return (term("Core/assume".atom, exp[1], typ_val.reify), unit_type)

proc synth_use(ctx: Ctx, exp: Exp): TypedExp =
    let (e, t) = ctx.check(exp[1])
    if t.kind != RecTypeVal:
        raise type_error("Can't use value of type {t}, because it's not a record. {exp[1]}".fmt)
    let record = ctx.eval(e)
    for label, field in t.rec_typ.fields:
        ctx.env.use(label, record.rec.ctx.eval(field.typ), term("Core/member".atom, exp[1], label.atom), record.rec.ctx)
    return (term("Core/use".atom, e), unit)

proc check_name(ctx: Ctx, exp: Exp, name: string, typ = None(Val)): TypedExp =
    if name == "Type":
        return (term("Core/Type".atom, "0".atom(tag=aNum)), type1)

    var env = ctx.env
    var var_typ : Val
    while env != nil:
        if name in env.vars:
            var_typ = env.vars[name].typ.or_else:
                #env.print_env()
                raise type_error("No type for {name}. {exp.src}".fmt)
            break
        elif name in env.uses:
            if typ.is_none:
                if env.uses[name].len > 1:
                    raise type_error("Ambiguous overload {name}.\n\nChoices: {env.uses[name]}. {exp.src}".fmt)
                else:
                    let (member_typ, member_exp, module) = env.uses[name][0]
                    #echo "{member_exp} : {member_typ}".fmt
                    return (member_exp, member_typ)
            let typ = typ.unsafe_get
            for use in env.uses[name]:
                if ctx.is_subtype(use.typ, typ):
                    return (use.exp, typ)
        env = env.parent

    if var_typ == nil:
        raise type_error("Variable {exp.bold} was not declared. {exp.src}".fmt)

    if typ.is_none:
        return (exp, var_typ)
    let typ = typ.unsafe_get
    if not ctx.is_subtype(var_typ, typ):
        raise type_error("Expected value of type {typ.noun} {typ}, but got variable {exp} of type {var_typ.noun} {var_typ}. {exp.src}".fmt)
    return (exp, typ)

proc check_quote(ctx: Ctx, exp: Exp, typ: Val): TypedExp =
    if typ == expr_type: return (exp, expr_type)
    if typ == Neu("Atom".atom) and exp[1].is_atom: return (exp, Neu("Atom".atom))
    if typ == Neu("Term".atom) and exp[1].is_term: return (exp, Neu("Term".atom))
    raise type_error("Expression {exp} is not of type {typ}. {exp.src}".fmt)

proc check*(ctx: Ctx, exp: Exp, typ: Opt[Val] = None(Val)): TypedExp =
    var exp = exp
    case exp.kind:
    of expAtom:
        case exp.tag:
        of aSym, aLit:
            return ctx.check_name(exp, exp.value, typ)
        of aNum:
            let typ = typ.or_else: return (exp, Neu("Num-Literal".atom))
            return ctx.check_num(exp, typ)
        of aStr:
            if typ.is_none or typ.unsafe_get == Neu("Str-Literal".atom): return (exp, Neu("Str-Literal".atom))
            raise type_error("Can't convert string literal {exp} to type {typ}. {exp.src}".fmt)
        else:
            raise type_error("Failed to type check {exp.tag} atom {exp.bold}. {exp.src}".fmt)
    of expTerm:
        if exp.is_nil:
            writeStackTrace()
            raise compiler_defect("Empty term while checking type {typ}".fmt)

        if exp.head.is_atom:
            case exp.head.value:
            of "Core/define", "Core/apply", "Core/block", "Core/case", "Core/quote", "Core/list", "Core/unwrap", "Core/while", "Core/break",
               "Core/Lambda", "Core/lambda", "Core/Record", "Core/record", "Core/member", "Core/builtin", "Core/use":
                writeStackTrace()
                raise compiler_defect("Can't type check core expression {exp}. {exp.src}".fmt)
            of "__builtin__":
                if typ.is_some:
                    return ctx.check_builtin(exp, typ.unsafe_get)
                else:
                    writeStackTrace()
                    raise type_error("Can't infer type of builtin. {exp.src}".fmt)
            of "use":
                return ctx.synth_use(exp)
            of "quote":
                exp[0] = "Core/quote".atom
                if typ.is_some:
                    return ctx.check_quote(exp, typ.unsafe_get)
                else:
                    return (exp, expr_type)
            of "lambda":
                return if typ.is_some:
                    (ctx.check_lambda(exp, typ.unsafe_get), typ.unsafe_get)
                else:
                    ctx.synth_lambda(exp)
            of "Lambda":
                return if typ.is_some:
                    (ctx.check_lambda_type(exp, typ.unsafe_get), typ.unsafe_get)
                else:
                    ctx.synth_lambda_type(exp)
            of "Record":
                return if typ.is_some:
                    (ctx.check_record_type(exp, typ.unsafe_get), typ.unsafe_get)
                else:
                    ctx.synth_record_type(exp)
            of "record":
                return if typ.is_some:
                    (ctx.check_record(exp, typ.unsafe_get), typ.unsafe_get)
                else:
                    ctx.synth_record(exp)
            of ":":
                return ctx.synth_assume(exp)
            of "=":
                let (name_exp, val_exp) = (exp[1], exp[2])
                let name = name_exp.value
                var opaque = false
                for part in exp[3 .. ^1]:
                    if part.is_atom("#opaque"):opaque = true
                var rhs_core : Exp
                var rhs_typ : Val 
                if name in ctx.env.vars and ctx.env.vars[name].typ.is_some:
                    let ass_typ = ctx.env.vars[name].typ.unsafe_get
                    (rhs_core, rhs_typ) = ctx.check(val_exp, ass_typ)
                    if not ctx.is_subtype(rhs_typ, ass_typ):
                        raise type_error("Variable {name} was declared as {ass_typ}, which is incompatible with value {ctx.eval(rhs_core)} of {rhs_typ}. {exp.src}".fmt)
                else:
                    (rhs_core, rhs_typ) = ctx.check(val_exp, typ)
                let rhs_val = ctx.eval(rhs_core)
                ctx.env.define(name, rhs_val, rhs_typ, opaque=opaque) # TODO: De Brujin
                let op = if opaque: "Core/define-opaque" else: "Core/define"
                return (term(op.atom, name_exp, rhs_core, rhs_typ.reify), rhs_typ)

            of "as":
                let lhs = exp[1]
                let rhs = ctx.eval(ctx.check_universe(exp[2]))
                var dst_typ = if rhs.kind == OpaqueVal: ctx.unwrap(rhs.exp) else: rhs
                var lhs_core : Exp
                var src_typ : Val
                (lhs_core, src_typ) = ctx.check(lhs, dst_typ)

                if typ.is_some:
                    var dst_typ2 = typ.unsafe_get
                    if dst_typ2.kind == NeuVal: dst_typ2 = ctx.eval(dst_typ2.exp) # try evaluating if variable became unstuck
                    if dst_typ2.kind == OpaqueVal: dst_typ2 = ctx.unwrap(dst_typ2.exp)
                    if not ctx.is_subtype(dst_typ2, dst_typ):
                        raise type_error("Cast error check {lhs_core} as {dst_typ} : {dst_typ2.noun} {dst_typ2}".fmt)
                    return (lhs_core, typ.unsafe_get)

                elif not ctx.is_subtype(src_typ, dst_typ):
                    raise type_error("You can't cast {lhs.bold} of {src_typ.noun} {src_typ.bold} to {dst_typ.noun} {dst_typ.bold}.\n\n".fmt &
                        "Can't upcast, because {src_typ.bold} is not a subtype of {dst_typ.bold}.\n\n".fmt &
                        "Can't downcast, because there is no evidence, that {lhs.bold} was upcast from type {dst_typ.bold}. {lhs.src}".fmt)

                return (lhs_core, rhs)

            of "case":
                var types : seq[Val]
                var core = term("Core/case".atom, ctx.check(exp[1]).exp)
                for x in exp.exprs[2 .. ^1]:
                    let (pattern, body) = (x[0], x[1])
                    types &= ctx.infer_type(body)
                    core &= term(pattern, body)
                return (core, ctx.eval_union(@[MakeListLit(types)]))
            of "block":
                var exps : seq[Exp]
                var types: seq[Val]
                for exp in exp.tail:
                    let (core_exp, typ) = ctx.check(exp)
                    if not core_exp.is_nil:
                        exps.add(core_exp)
                        types.add(typ)
                if exps.len == 0:
                    return (term(), unit)
                return (term("Core/block".atom & exps), types[^1])

            of ".":
                let (lhs, lhs_typ) = ctx.check(exp[1], typ)
                let rhs = exp[2]
                assert rhs.kind == expAtom
                let field_name = rhs.value
                if lhs_typ.kind != RecTypeVal:
                    raise type_error("Value {exp[1]} of type {lhs_typ} is not a record, so member access is not allowed. {lhs.src}".fmt)
                if field_name notin lhs_typ.rec_typ.fields:
                    raise type_error("Record {exp[1]} has no member {field_name}. {rhs.src}".fmt)
                let field = lhs_typ.rec_typ.fields[field_name]
                let record = ctx.eval(lhs)
                assert record.kind == RecVal
                return (term("Core/member".atom, lhs, rhs), record.rec.ctx.eval(field.typ))

            of "while":
                let (cond, _) = ctx.check(exp[1])
                let (body, _) = ctx.check(exp[2])
                return (term("Core/while".atom, cond, body), never_type)
            of "break":
                return (term("Core/break".atom), never_type)
            of "unwrap":
                let (arg, typ) = ctx.check(exp[1], typ)
                return (term("Core/unwrap".atom, arg), typ)
            else:
                discard
        
        return ctx.check_apply(exp, typ)


#
# Evaluation - computes the value of an expression
#


proc eval_lambda_param(ctx: Ctx, exp: Exp): FunParam =
    result.name = exp[1].value
    var typ : Val
    for part in exp.exprs[2 .. ^1]:
        if part.has_prefix("#type"):
            typ = ctx.eval(part[1])
            result.typ = reify(typ)
        elif part.has_prefix("#default"):
            result.default = Some(ctx.norm(part[1]))
        elif part.has_prefix("#variadic"):
            result.variadic = true
            result.variadic_typ = ctx.norm(part[1])
        elif part == atom("#quoted"):
            result.quoted = true
        elif part == atom("#keyword"):
            result.keyword = true
    assert typ != nil
    ctx.env.assume(result.name, typ, site=Some(exp)) # TODO: De Brujin


proc eval_lambda_type(ctx: Ctx, exp: Exp): FunTyp =
    let ctx = ctx.extend()
    result.ctx = ctx
    #echo "eval Lambda " & exp.str
    for part in exp.tail:
        if part.has_prefix("#param"):
            result.params &= ctx.eval_lambda_param(part)
        elif part.has_prefix("#result"):
            result.result = ctx.norm(part[1])
        elif part.is_atom("#expand"):
            result.autoexpand = true
        else:
            raise runtime_error("Unexpected Core/Lambda form {part.str}. {exp.src}".fmt)


proc eval_lambda(ctx: Ctx, exp: Exp): Fun =
    result.ctx = ctx.extend()
    for part in exp.tail:
        if part.has_prefix("#param"):
            result.params &= part[1].value
        elif part.has_prefix("#body"):
            result.body = part[1]


proc eval_record_type(ctx: Ctx, exp: Exp): RecTyp =
    let local = ctx.extend()
    for part in exp.tail:
        if part.has_prefix("#field"):
            var field : RecField
            field.name = part[1].value
            for part in part[2 .. ^1]:
                if part.has_prefix("#type"): field.typ = part[1]
                elif part.has_prefix("#default"): field.default = part[1]
                else: assert false
            let typ = local.eval(field.typ)
            field.typ = typ.reify
            local.env.assume(field.name, typ, site=Some(part))
            result.fields[field.name] = field
        else:
            assert false


proc eval_record(ctx: Ctx, exp: Exp): Rec =
    let ctx = ctx.extend()
    result.ctx = ctx
    #echo "eval record"
    for part in exp.tail:
        if part.has_prefix("#def"):
            let (name, val, typ) = (part[1], part[2], part[3])
            #echo fmt"   {name} : {typ} = {val}"
            if val.is_nil:
                ctx.env.assume(name.value, ctx.eval(typ))
            else:
                let val = ctx.eval(val)
                result.values[name.value] = val
                ctx.env.vars[name.value] = Var(val: Some(val), typ: Some(ctx.eval(typ)))
        else:
            assert false


proc eval_apply_lambda(ctx: Ctx, fun: Fun, args: seq[Exp]): Val =
    let local_args = fun.ctx
    for (name, it) in zip(fun.params, args):
        local_args.env.vars[name] = Var(val: Some(ctx.eval(it))) # TODO: De Brujin
    let local_body = local_args.extend()
    local_body.eval(fun.body)


proc eval_apply_builtin(ctx: Ctx, builtin: BuiltinFun, args: seq[Exp]): Val =
    builtin.fun(ctx.extend(), args.map_it(ctx.eval(it)))


proc eval_apply(ctx: Ctx, exp: Exp): Val =
    let head = ctx.eval(exp.head)
    case head.kind:
    of BuiltinFunVal:
        ctx.eval_apply_builtin(head.builtin_fun, exp.tail)
    of FunVal:
        ctx.eval_apply_lambda(head.fun, exp.tail)
    of NeuVal, OpaqueVal:
        let res = term("Core/apply".atom, term(reify(head) & exp.tail.map_it(ctx.norm(it))))
        if head.kind == NeuVal: Neu(res) else: Val(kind: OpaqueVal, exp: res)
    else:
        raise ctx.error(exp=exp, msg="Can't evaluate, because {head.kind} {head.bold} is not callable. {exp.src}".fmt)


proc eval_name(ctx: Ctx, exp: Exp): Val =
    let name = exp.value
    let env = ctx.env.find(name)
    if env == nil:
        #writeStackTrace()
        #ctx.print_env()
        raise runtime_error("Variable {exp.bold} is unknown. {exp.src}".fmt)
    let vari = env.vars[name]
    if ctx.eval_mode == EvalMode.Unwrap:
        if vari.val.is_none:
            raise runtime_error("Can't unwrap because {name.bold} is not defined. {exp.src}".fmt)
        return vari.val.unsafe_get
    if vari.opaque:
        return Val(kind: OpaqueVal, exp: exp)
    vari.val ?? Neu(exp)


proc eval_assume(ctx: Ctx, exp: Exp): Val =
    let (name, typ_exp) = (exp[1].value, exp[2])
    let typ = ctx.eval(typ_exp)
    ctx.env.vars[name] = Var(typ: Some(typ))
    return unit

proc eval_define(ctx: Ctx, exp: Exp, opaque = false): Val =
    # TODO: De Brujin
    let (name, val_exp, typ_exp) = (exp[1].value, exp[2], exp[3])
    let typ = ctx.eval(typ_exp)
    let val = ctx.eval(val_exp)
    if name in ctx.env.vars:
        if ctx.env.vars[name].val.is_some:
            raise runtime_error("Already defined {name.bold}".fmt)
        ctx.env.vars[name].val = Some(val)
    else:
        ctx.env.vars[name] = Var(val: Some(val), typ: Some(typ), opaque: opaque)
    return val


proc eval_match(ctx: Ctx, lhs_exp: Exp, rhs_val: Val): bool =
    if lhs_exp.is_token("_"): return true
    let lhs_val = ctx.eval(lhs_exp)
    return lhs_val == rhs_val


proc eval_case(ctx: Ctx, switch_exp: Exp, cases: seq[Exp]): Val =
    let switch = ctx.eval(switch_exp)
    if switch.kind == NeuVal:
        return Neu(term(@["Core/case".atom, ctx.norm(switch_exp)] & cases)) # FIXME: norm cases (special treatment for patterns)
        #raise ctx.error("Can't match on a neutral value {switch_exp.bold}. {switch_exp.src}".fmt)
    for branch in cases:
        #let local = ctx.extend()
        if ctx.eval_match(branch[0], switch):
            return ctx.eval(branch[1])
    writeStackTrace()
    raise runtime_error("Unreachable case {switch.noun} {switch.bold}. {switch_exp.src}".fmt)


proc eval*(ctx: Ctx, exp: Exp): Val =
    case exp.kind
    of expAtom:
        case exp.tag
        of aSym, aLit: return eval_name(ctx, exp)
        of aNum: return Val(kind: NumLit, lit: exp.value)
        of aStr: return Val(kind: StrLit, lit: exp.value.basic_str)
        else: discard
    of expTerm:
        if exp.is_nil:
            return unit # NOP
        if exp.head.is_atom:
            case exp.head.value
            of "Core/Type":
                return Universe(exp[1].value.parse_int)
            of "Core/builtin":
                return BUILTINS[exp[1].value]
            of "Core/assume":
                return ctx.eval_assume(exp)
            of "Core/define":
                return ctx.eval_define(exp)
            of "Core/define-opaque":
                return ctx.eval_define(exp, opaque=true)
            of "Core/use":
                return unit
            of "Core/Lambda":
                return Val(kind: FunTypeVal, fun_typ: ctx.eval_lambda_type(exp))
            of "Core/lambda":
                return Val(kind: FunVal, fun: ctx.eval_lambda(exp))
            of "Core/Record":
                return Val(kind: RecTypeVal, rec_typ: ctx.eval_record_type(exp))
            of "Core/record":
                return Val(kind: RecVal, rec: ctx.eval_record(exp))
            of "Core/apply":
                return ctx.eval_apply(exp[1])
            of "Core/quote":
                return if exp.len == 1: Box(term()) else: Box(exp[1])
            of "Core/block":
                var res = unit
                for stat in exp.tail:
                    res = ctx.eval(stat)
                    if res.kind == InterruptVal:
                        return res
                return res
            of "Core/list":
                return Val(kind: ListLit, values: ctx.eval_all(exp.tail))
            of "Core/case":
                return ctx.eval_case(exp[1], exp.exprs[2 .. ^1])
            of "Core/unwrap":
                return ctx.unwrap(exp[1])
            of "Core/while":
                while true:
                    let cond = ctx.eval(exp[1])
                    if cond.u8 == 0: break
                    let res = ctx.eval(exp[2])
                    if res.kind == InterruptVal: break
                return unit
            of "Core/break":
                return Val(kind: InterruptVal)
            of "Core/member":
                let lhs = ctx.eval(exp[1])
                if lhs.kind == NeuVal:
                    var exp = exp
                    exp[1] = lhs.exp
                    return Neu(exp)
                let rhs = exp[2].value
                if rhs notin lhs.rec.values:
                    return Neu(exp)
                return lhs.rec.values[rhs]
            else:
                discard
    raise compiler_defect("Can't evaluate non-core term {exp.str}. {exp.src}".fmt)


#
# Reification - converts values back to expressions
#

func reify_lambda_param(param: FunParam): Exp =
    result = term("#param".atom, param.name.atom)
    result.exprs &= term("#type".atom, param.typ)
    if param.default.is_some: result.exprs &= term("#default".atom, param.default.unsafe_get)
    if param.variadic: result.exprs &= term("#variadic".atom, param.variadic_typ)
    if param.keyword: result.exprs &= "#keyword".atom
    if param.quoted: result.exprs &= "#quoted".atom


func reify_lambda_type(fun_typ: FunTyp): Exp =
    result.exprs &= "Core/Lambda".atom
    for param in fun_typ.params: result.exprs &= reify_lambda_param(param)
    result.exprs &= term("#result".atom, fun_typ.result)
    if fun_typ.autoexpand: result.exprs &= "#expand".atom


func reify_lambda(fun: Fun): Exp =
    raise runtime_error("Can't reify lambda value {fun}.".fmt)
    #if fun.name.len > 0: return fun.name.atom
    #result.exprs &= "Core/lambda".atom & reify_lambda_type(fun.typ.unsafe_get).tail
    #result.exprs &= term("#body".atom, fun.body.unsafe_left)


func reify_record_field(field: RecField): Exp =
    result = term("#field".atom, field.name.atom, term("#type".atom, field.typ))
    if not field.default.is_nil: result.exprs &= term("#default".atom, field.default)


func reify_record_type(rec_typ: RecTyp): Exp =
    result.exprs &= "Core/Record".atom
    for label, field in rec_typ.fields:
        result.exprs &= reify_record_field(field)


func reify_record(rec: Rec): Exp =
    result.exprs &= "Core/record".atom
    for (name, val) in rec.values.pairs:
        result.exprs &= term("#arg".atom, name.atom, val.reify, term())


func reify_unary_apply(foo: string, arg: Exp): Exp = 
    term("Core/apply".atom, term(foo.atom, arg))


func reify_unary_apply_builtin(foo: string, arg: Exp): Exp = 
    term("Core/apply".atom, term(term("Core/builtin".atom, foo.atom), arg))


func reify*(val: Val): Exp =
    case val.kind
    of NeverVal:
        "unreachable".atom
    of InterruptVal:
        term("Core/break".atom)
    of BuiltinFunVal:
        term("Core/builtin".atom, val.builtin_fun.name.atom)
    of U8:
        reify_unary_apply("num-u8", atom($val.u8, aNum))
    of I8:
        reify_unary_apply("num-i8", atom($val.i8, aNum))
    of U64:
        reify_unary_apply("num-u64", atom($val.u64, aNum))
    of I64:
        reify_unary_apply("num-i64", atom($val.i64, aNum))
    of NumLit:
        atom(val.str, tag=aNum)
    of StrLit:
        atom("\"" & val.str & "\"", tag=aStr)
    of ListLit:
        term("Core/list".atom & val.values.map(reify))
    of TypeVal:
        term("Core/Type".atom, atom($val.level, tag=aNum))
    of ExpVal:
        term("Core/quote".atom, val.exp)
    of OpaqueVal, NeuVal:
        val.exp
    of UnionTypeVal:
        reify_unary_apply_builtin("Union", term("Core/list".atom & val.values.map(reify)))
    of InterTypeVal:
        reify_unary_apply_builtin("Inter", term("Core/list".atom & val.values.map(reify)))
    of FunTypeVal:
        reify_lambda_type(val.fun_typ)
    of FunVal:
        reify_lambda(val.fun)
    of RecTypeVal:
        reify_record_type(val.rec_typ)
    of RecVal:
        reify_record(val.rec)
    of MemVal:
        raise runtime_error("Can't reify {val.noun} {val.bold}.".fmt)


#
# Non-critical builtins
#

proc eval_equals(ctx: Ctx, lhs, rhs: Exp): bool =
    let lhs_typ = ctx.infer_type(lhs)
    let rhs_typ = ctx.infer_type(rhs)
    let lhs_val = ctx.eval(lhs)
    let rhs_val = ctx.eval(rhs)
    if lhs_typ != rhs_typ:
        let exp = term(lhs, rhs)
        raise error(exp, "Can't compare arguments of different types {lhs_val} of {lhs_typ} and {rhs_val} of {rhs_typ}. {exp.src}".fmt)
    lhs_val == rhs_val


proc eval_test(ctx: Ctx, name: string, test: Exp) =
    var core_exp: Exp
    try:
        let local = ctx.extend()
        core_exp = local.check(test)[0]
        discard ctx.eval(core_exp)
        #discard ctx.eval_surface(test)
        stdout.write "test " & name & " \e[32mPASSED\e[0m\n".fmt
    except AssertionDefect:
        echo get_current_exception().getStackTrace()
        stdout.write "test " & name & " \e[31mFAILED\e[0m\n".fmt
    except VitaminError:
        stdout.write "test " & name & " \e[31mFAILED\e[0m\n".fmt
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error)
        stdout.write ">".repeat(10) & "\n" & core_exp.core_to_pretty & "\n" & "<".repeat(10) & "\n"


proc eval_xtest(ctx: Ctx, name: string, body_exp: Exp) =
    echo "test {name} \e[33mSKIPPED\e[0m".fmt


proc eval_assert(ctx: Ctx, exp: Exp) =
    let prefix = "ASSERTION FAILED"
    var cond = exp
    var negate = false
    if cond.has_prefix("not"):
        cond = cond[1]
        negate = true
    let neg = if negate: "not " else: ""
    let neg_neg = if negate: "" else: "not "
    if cond.has_prefix("==") or cond.has_prefix("!="):
        let op = cond[0].value
        let (lhs, actual_typ) = ctx.check(cond[1])
        let (rhs, expected_typ) = ctx.check(cond[2])
        if not ctx.is_subtype(actual_typ, expected_typ):
            raise error(exp, "can't compare {lhs.str} of type {actual_typ.str} ".fmt &
                "with {rhs.str} of type {expected_typ.str}. {exp.src}".fmt)
        let (actual, expected) = (ctx.eval(lhs), ctx.eval(rhs))
        case op
        of "==":
            if not equal(actual, expected):
                raise ctx.error(exp=exp, prefix=prefix, msg="Expected {lhs.bold}\nto equal {rhs.bold}".fmt &
                    "\n     but {actual.bold} != {expected.bold} {exp.src}".fmt)
        of "!=":
            if equal(actual, expected):
                raise ctx.error(exp=exp, prefix=prefix, msg="Expected {lhs.bold}\nto not equal {rhs.bold}".fmt &
                    "\n         but {actual.bold} == {expected.bold} {exp.src}".fmt)
    elif cond.has_prefix("is-subtype"):
        let (lhs, rhs) = (cond[1], cond[2])
        let lhs_val = ctx.eval_surface(lhs)
        let rhs_val = ctx.eval_surface(rhs)
        if not ctx.is_subtype(lhs_val, rhs_val) xor negate:
            raise ctx.error(exp=exp, prefix=prefix, msg="Expected {lhs_val.bold} to {neg}be a subtype of {rhs_val.bold}. {exp.src}".fmt)
    elif cond.has_prefix("error"):
        var cond = cond[1]
        var exp : Exp
        var typ, val : Val
        try:
            (exp, typ) = ctx.check(cond)
            val = ctx.eval(exp)
        except VitaminError:
            discard
        if typ != nil and val != nil:
            raise ctx.error(exp=cond, prefix=prefix, msg="Expected expression {cond.bold} to raise a compile-time error,\n".fmt &
                "but {exp.bold} successfuly evaluated to {val.bold} of type {typ.bold} {cond.src}.".fmt)
    else:
        raise error(exp, "assert doesn't support expressions like {cond.bold} {exp.src}".fmt)


#
# Builtin definitions
#

proc set_builtin_fun(name: string, fun: BuiltinFunProc) =
    BUILTINS[name] = Val(kind: BuiltinFunVal, builtin_fun: BuiltinFun(fun: fun, name: name))

template set_builtin_fun_inline(name: string, stat: untyped): untyped =
    set_builtin_fun name, (proc (ctx {.inject.}: Ctx, args {.inject.}: seq[Val]): Val = stat)

set_builtin_fun "Union", eval_union

set_builtin_fun "Inter", eval_inter

set_builtin_fun_inline "type-of":
    ctx.infer_type(args[0].exp)

set_builtin_fun_inline "assert":
    eval_assert(ctx, args[0].exp)
    unit

set_builtin_fun_inline "test":
    eval_test(ctx, args[0].lit, args[1].exp)
    unit

set_builtin_fun_inline "xtest":
    eval_xtest(ctx, args[0].lit, args[1].exp)
    unit

set_builtin_fun_inline "==":
    if eval_equals(ctx, args[0].exp, args[1].exp):
        return ctx.eval(atom("true"))
    else:
        return ctx.eval(atom("false"))

set_builtin_fun_inline "print":
    stdout.write args[0].values.join(args[1].str) & args[2].str
    return unit

set_builtin_fun_inline "gensym":
    Box(atom(gensym(prefix="__")))

set_builtin_fun_inline "num-i8":
    let num = parse_int(args[0].lit)
    if not (-128 <= num and num <= 127):
        raise ctx.error("Number literal {args[0]} does not fit in the range of type I8. {ctx.src}".fmt)
    Val(kind: I8, i8: int8(num))

set_builtin_fun_inline "num-u8":
    let num = parse_int(args[0].lit)
    if not (0 <= num and num <= 255):
        raise ctx.error("Number literal {args[0]} does not fit in the range of type U8. {ctx.src}".fmt)
    Val(kind: U8, u8: uint8(num))

set_builtin_fun_inline "num-i64":
    try:
        Val(kind: I64, i64: int64(parse_int(args[0].lit)))
    except ValueError:
        raise ctx.error("Number literal {args[0]} does not fit in the range of type I64. {ctx.src}".fmt)

set_builtin_fun_inline "num-u64":
    try:
        let num = parse_uint(args[0].lit)
        Val(kind: U64, u64: uint64(num))
    except ValueError:
        raise ctx.error("Number literal {args[0]} does not fit in the range of type U64. {ctx.src}".fmt)

set_builtin_fun_inline "print-env":
    ctx.print_env(uses=true)