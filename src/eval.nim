import options, tables, sets, sequtils, strformat, strutils, algorithm
import common/[exp, error, utils, types]
import patty
import sugar

# TODO: Allow access to the expression stack in macros

{.warning[ProveInit]: off.}

#
# Boilerplate forward declarations :/
#

proc eval*(ctx: Ctx, exp: Exp): Val
proc dynamic_type*(ctx: Ctx, val: Val): Val
proc dynamic_level*(ctx: Ctx, val: Val): int
proc infer_type*(ctx: Ctx, exp: Exp): Val
proc infer_level*(ctx: Ctx, exp: Exp): int
proc reify*(ctx: Ctx, val: Val): Exp
proc norm*(ctx: Ctx, exp: Exp): Exp
proc unwrap*(ctx: Ctx, exp: Exp): Val
proc expand*(ctx: Ctx, exp: Exp): Exp
proc is_subtype*(ctx: Ctx, x, y: Val): bool
func `==`*(x, y: Val): bool
func equal*(x, y: Val): bool = x == y
proc match_apply_args(ctx: Ctx, exp: Exp): Exp

proc norm_all*(ctx: Ctx, exps: seq[Exp]): seq[Exp] =
    exps.map_it(ctx.norm(it))

proc eval_all*(ctx: Ctx, exps: seq[Exp]): seq[Val] =
    exps.map_it(ctx.eval(it))

proc print_env(ctx: Ctx, skip_top = true, only_args = false) =
    var env = ctx.env
    var level = ctx.env.depth
    while env != nil:
        if skip_top and env.parent == nil: break
        for (k, v) in env.vars.pairs:
            if only_args and not (v.arg or v.capture): continue
            var typ = v.typ.map(str) ?? ""
            var val = v.val.map(str) ?? ""
            if val.len > 0:
                val = " = " & val
                typ = ""
            elif typ.len > 0:
                typ = " : " & typ
            var tag = ""
            if v.capture: tag &= "C"
            if v.arg: tag &= "A"
            echo "({level}) [{tag}] {k}{typ}{val}".fmt
        env = env.parent
        level -= 1

#
# Glooobals
#

var next_gensym_id = 0
var next_name_uid: Table[string, int]
let type0* = Universe(0)
let type1* = Universe(1)
let unit* = Box(MakeRec())
let unit_type* = Box(MakeRecTyp())

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
# Context
#

func extend*(env: Env): Env =
    Env(parent: env, depth: env.depth + 1)

func extend*(ctx: Ctx, new_env = true, eval_mode: EvalMode): Ctx =
    Ctx(
        env: if new_env: ctx.env.extend() else: ctx.env,
        eval_mode: eval_mode,
        site_stack: ctx.site_stack,
        call_stack: ctx.call_stack,
    )

func extend*(ctx: Ctx, new_env = true): Ctx =
    ctx.extend(new_env, ctx.eval_mode)

func assume*(env: Env, name: string, typ: Val, site = None[Exp](), arg = false) =
    env.vars[name] = Var(val: None[Val](), typ: Some(typ), site: site, arg: arg)

func define*(env: Env, name: string, val, typ: Val, site = None[Exp](), opaque = false, arg = false) =
    env.vars[name] = Var(val: Some(val), typ: Some(typ), site: site, opaque: opaque, arg: arg)

func find*(env: Env, name: string): Env =
    var env = env
    while env != nil:
        if name in env.vars: return env
        env = env.parent
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

func lookup*(env: Env, name: string): Opt[Var] =
    let env = env.find(name)
    if env == nil: return None[Var]()
    Some(env.vars[name])

func lookup_type*(env: Env, name: string): Opt[Val] =
    let variable = env.lookup(name).or_else: return None(Val)
    variable.typ

func lookup_value*(env: Env, name: string): Opt[Val] =
    let variable = env.lookup(name).or_else: return None(Val)
    variable.val

#
# Unions & intersections
#

proc sets_inter*(xs, ys: seq[Val]): seq[Val] =
    for x in xs:
        if ys.any_it(x == it):
            result.add(x)

proc value_union*(xs, ys: seq[Val]): seq[Val] =
    result = xs
    for y in ys:
        if result.all_it(it != y):
            result.add(y)

proc value_inter*(xs, ys: seq[Val]): seq[Val] =
    sets_inter(xs, ys)

proc value_set*(xs: seq[Val]): seq[Val] =
    for x in xs:
        if result.any_it(x == it):
            continue
        result.add(x)

proc sets_equal*(xs, ys: seq[Val]): bool =
    if xs.len != ys.len: return false
    for x in xs:
        block inner:
            for y in ys:
                if x == y:
                    break inner
            return false
    true

proc norm_union*(args: varargs[Val]): Val =
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

proc norm_inter*(args: varargs[Val]): Val =
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
    x.name == y.name

func `==`(x, y: FunTyp): bool =
    if x.params.len != y.params.len: return false
    if x.result != y.result: return false
    for (a, b) in zip(x.params, y.params):
        #if a.name != "_" and b.name != "_" and a.name != b.name: return false
        if a.typ != b.typ: return false
    true

func `==`(x, y: Rec): bool =
    if x.fields.len != y.fields.len: return false
    for xf in x.fields:
        var found = false
        for yf in y.fields:
            if xf.name == yf.name:
                if xf.val == yf.val:
                    found = true 
                    break
                else:
                    return false
        if not found:
            return false 
    return true

func `==`(x, y: RecTyp): bool =
    if x.slots.len != y.slots.len: return false
    let n = x.slots.len
    let x_slots = x.slots.sorted_by_it(it.name)
    let y_slots = y.slots.sorted_by_it(it.name)
    for (a, b) in zip(x_slots, y_slots):
        if a.name != b.name or a.typ != b.typ: return false
    return true

func `==`(x, y: seq[Val]): bool =
    if x.len != y.len: return false
    for (a, b) in zip(x, y):
        if a != b: return false
    true

func `==`*(x, y: Val): bool =
    if x.kind != y.kind: return false
    case x.kind
    of TypeVal: x.level == y.level
    of UnionTypeVal, InterTypeVal: sets_equal(x.values, y.values)
    of ListLit: x.values == y.values
    of MemVal: x.mem.buf == y.mem.buf
    of FunTypeVal: x.fun_typ == y.fun_typ
    of FunVal: x.fun == y.fun
    of RecVal: x.rec == y.rec
    of RecTypeVal: x.rec_typ == y.rec_typ
    of NumLit, StrLit: x.lit == y.lit
    of NeuVal, ExpVal: x.exp == y.exp
    of I8: x.i8 == y.i8
    of U8: x.u8 == y.u8
    of I64: x.i64 == y.i64
    of U64: x.u64 == y.u64

proc unify_sigma(ctx: Ctx, x, y: RecTyp): bool =
    if x.slots.len != y.slots.len: return false
    let n = x.slots.len
    # FIXME: sort topologically by dependency order
    let x_slots = x.slots
    let y_slots = y.slots
    let local = ctx.extend()
    for (a, b) in zip(x_slots, y_slots):
        if a.name != b.name: return false
        let a_typ = local.eval(a.typ)
        let b_typ = local.eval(b.typ)
        a.value.if_some(value):
            let a_val = local.eval(value)
            let a_typ = local.eval(a.typ)
            local.env.define(a.name, a_val, a_typ)
        if a_typ != b_typ: return false
    return true

proc is_subtype*(ctx: Ctx, x, y: Val): bool =
    # is x a subtype of y
    let x = if x.kind == NeuVal: ctx.eval(x.exp) else: x
    let y = if y.kind == NeuVal: ctx.eval(y.exp) else: y
    if x.kind == y.kind:
        case x.kind
        of UnionTypeVal:
            return sets_inter(x.values, y.values).len > 0
        of InterTypeVal:
            return value_set(x.values & y.values).len > x.values.len
        of RecTypeVal:
            return ctx.unify_sigma(x.rec_typ, y.rec_typ)
        else:
            discard
    if y.kind == UnionTypeVal:
        return y.values.any_it(ctx.is_subtype(x, it))
    if y.kind == InterTypeVal:
        return y.values.all_it(ctx.is_subtype(x, it))
    x == y

#
# Lambdas
#

proc get_typ*(ctx: Ctx, val: Fun): FunTyp =
    val.typ.or_else:
        raise ctx.error("Type of lambda {val.name.bold} must be assumed before usage! {ctx.src}".fmt)

proc make_lambda_param(ctx: Ctx, param: Exp): FunParam =
    var (name, typ_exp, val_exp) = (param[0], param[1], param[2])
    if name.is_nil:
        name = atom("_")
    if not name.is_atom:
        raise ctx.error(exp=name, msg="Lambda parameter name must be an Atom, but got Term {name}. {name.src}".fmt)

    var val = None(Exp)
    var variadic_container = None(Exp)
    var typ: Val
    var quoted = false
    var variadic = false
    var lazy = false
    var did_infer_typ = false
    var searched = false

    if not typ_exp.is_nil:
        typ_exp = ctx.expand(typ_exp)
        while typ_exp.has_prefix_any(["quoted", "variadic", "lazy"]):
            case typ_exp[0].value
            of "quoted":
                typ_exp = typ_exp[1]
                quoted = true
            of "variadic":
                variadic = true
                if typ_exp.len == 3:
                    variadic_container = Some(typ_exp[1])
                    typ_exp = typ_exp[2]
                else:
                    typ_exp = typ_exp[1]
            of "lazy":
                typ_exp = typ_exp[1]
                lazy = true
            typ_exp = ctx.expand(typ_exp)

        #if variadic:
            #let container = variadic_container ?? atom("List")
            #typ_exp = term(container, typ_exp)
            #typ_exp = atom("List-Literal")

        typ = ctx.eval(typ_exp)

    if val_exp.is_token("_"):
        searched = true
    elif not val_exp.is_nil:
        val = Some(val_exp)
        var val_typ = ctx.infer_type(val_exp)
        if typ_exp.is_nil:
            did_infer_typ = true
            typ = val_typ
        elif not ctx.is_subtype(val_typ, typ):
            raise ctx.error(exp=param, msg="Value of {val_typ} can't be used as a default value for parameter of {typ}. {param.src}".fmt)

    elif typ_exp.is_nil:
        raise ctx.error(exp=param, msg="You have to provide a type or default value for function parameters. {param.src}".fmt)

    ctx.env.assume(name.value, typ, arg=true)

    FunParam(
        name: name.value,
        typ: ctx.reify(typ),
        default: val,
        did_infer_typ: did_infer_typ,
        quoted: quoted,
        variadic: variadic,
        lazy: lazy,
        searched: searched,
    )

proc make_lambda_type(ctx: Ctx, params: seq[Exp], ret: Exp, body: Exp): tuple[typ: FunTyp, ctx: Ctx] =
    let local = ctx.extend(eval_mode=EvalMode.Norm)

    # TODO: ensure that params form a DAG, and add params in topological order
    # assume all params in the environment
    var param_list: seq[FunParam]
    for param in params:
        param_list.add(local.make_lambda_param(param))

    var ret_exp = ret
    var is_macro = false
    var did_infer_result = false

    if not ret_exp.is_nil:
        ret_exp = local.expand(ret_exp)
        if ret_exp.has_prefix("expand"):
            ret_exp = ret_exp[1]
            is_macro = true
        ret_exp = local.norm(ret_exp)

    if not body.is_nil:
        let body_typ = local.infer_type(body)
        if ret_exp.is_nil:
            did_infer_result = true
            ret_exp = local.reify(body_typ)
        else:
            let ret_typ = local.eval(ret_exp)
            if not ctx.is_subtype(body_typ, ret_typ):
                raise error(body, "Function body type {body_typ}, doesn't match expected return type {ret_typ}. {term(ret_exp, body).src}".fmt)
    elif ret_exp.is_nil:
        raise ctx.error("You have to provide a function result type or function body, so the result type can be inferred. {ctx.src}".fmt)

    let fun_typ = FunTyp(
        params: param_list,
        result: ret_exp,
        is_macro: is_macro,
    )

    #for k, v in ctx.env.vars.pairs:
    #    echo "capture {k} = {v}".fmt
    #    local.env.vars[k] = v

    (typ: fun_typ, ctx: local)

proc desugar_lambda_type_params(ctx: Ctx, exp: Exp): Exp =
    var params: seq[Exp]
    if not exp.has_prefix("(_)"):
        return term(term(term(), exp, term()))
    let total = exp[1]
    for outer in total.exprs:
        for inner in outer.exprs:
            var inner_typ: Exp = term()
            var inner_params: seq[Exp]
            for param in inner.exprs.reverse_iter:
                var (name, typ, val) = (term(), term(), term())
                var param = param
                if param.kind == expAtom:
                    name = param
                    typ = inner_typ
                else:
                    if param.has_prefix("="):
                        val = param[2]
                        param = param[1]
                    if param.kind == expAtom:
                        name = param
                    elif param.has_prefix(":"):
                        name = param[1]
                        typ = param[2]
                        inner_typ = typ
                    else:
                        assert inner.exprs.len == 1
                        name = atom("_")
                        typ = param
                inner_params.add(term(name, typ, val))
            params &= inner_params.reversed
    term(params)

proc expand_lambda*(ctx: Ctx, lhs, rhs: Exp): Exp =
    # `=>` : (lhs rhs: Quoted(Expr)) -> Eval(Expr)
    #let (lhs, rhs) = (args[0].exp, args[1].exp)
    if lhs.has_prefix("(_)"):
        let par = desugar_lambda_type_params(ctx, lhs)
        term(atom("lambda"), par, term(), rhs)
    elif lhs.has_prefix("->"):
        let par = desugar_lambda_type_params(ctx, lhs[1])
        let ret = lhs[2]
        term(atom("lambda"), par, ret, rhs)
    else:
        raise ctx.error(exp=lhs, msg="Bad lambda term ({lhs.str} => {rhs.str}). {lhs.src}".fmt)

proc apply_lambda(ctx: Ctx, fun: Fun, exp: Exp): Val =
    let norm = ctx.match_apply_args(exp)
    var args = new_seq[Val](norm.len - 1)
    var neu = false
    let local = fun.ctx ?? ctx.extend()
    for i, (par, arg) in zip(fun.typ.unsafe_get.params, norm.tail):
        let (val, typ) = (local.eval(arg), local.eval(par.typ))
        local.env.define(par.name, val, typ, arg=true)
        args[i] = val
        if val.kind == NeuVal: neu = true

    #if fun.body.is_left:
    #    echo "--------------"
    #    echo "CALL " & exp.str
    #    local.print_env(only_args=false)
    #    echo "--------------\n"

    if neu and ctx.eval_mode == EvalMode.Norm:
        return Neu(term(norm.head & ctx.norm_all(norm.tail)))

    match fun.body:
        Left(body): 
            eval(local, body)
        Right(body): 
            body(local, args)

proc eval_apply(ctx: Ctx, exp: Exp): Val =
    var head = ctx.eval(exp[0])
    case head.kind
    of FunVal:
        ctx.apply_lambda(head.fun, exp)
    of NeuVal:
        Neu(term(head.exp & ctx.norm_all(exp.tail)))
    of RecTypeVal:
        raise ctx.error(exp=exp, msg="Record constructors not implemented. {exp.src}".fmt)
    else:
        raise ctx.error(exp=exp, msg="Can't evaluate, because {head.noun} {head.bold} of type {ctx.dynamic_type(head).bold} is not callable. {exp[0].src}".fmt)

proc expand_apply(ctx: Ctx, lhs, rhs: Exp): Exp =
    # `()` : (func: Expr, args: [[[Expr]]]) -> Eval(Expr)
    var call = @[lhs]
    let total = rhs
    assert total.len <= 1
    for outer in total.exprs:
        for inner in outer.exprs:
            for exp in inner.exprs:
                call &= exp
    term(call)

#
# Records
#

proc expand_record(ctx: Ctx, exp: Exp): Exp =
    # (e1, e2, .., en)
    var fields: seq[Exp]
    for group in exp.exprs:
        if group.len != 1:
            raise ctx.error(exp=exp, msg="Tuple elements must be spearated by a comma {group.src}".fmt)

        let arg = group[0]
        if not arg.has_prefix("="):
            raise ctx.error(exp=arg, msg="Missing label for record field {arg.src}".fmt)

        assert arg.len == 3
        var name, typ, val: Exp
        if arg[1].has_prefix(":"):
            let name_typ = arg[1]
            assert name_typ.len == 3
            name = name_typ[1]
            typ = name_typ[2]
            val = arg[2]
        else:
            name = arg[1]
            val = arg[2]
            typ = term()
        
        if name.kind != expAtom:
            raise ctx.error(exp=name, msg="Field name must be an atom, but got term {name}. {name.src}".fmt)

        fields.add(term(name, typ, val))
    return term(atom("record"), term(fields))

proc eval_record_type(ctx: Ctx, arg: Exp): RecTyp =
    var slots: seq[RecSlot]
    var extensible = false
    var extension: Opt[Exp]
    let local = ctx.extend()
    for group in arg.exprs:
        # FIXME: correct ordering inside param list
        if not group.is_term: continue
        for list in group.exprs: 
            var list_type = None(Exp)
            for x in list.exprs.reverse_iter:
                var slot_name: string
                var slot_default = None(Exp)
                var slot_typ: Exp
                var name_typ = x
                case x.kind
                of expAtom:
                    if x.value == "...":
                        extensible = true
                        continue
                    slot_name = x.value
                    match list_type:
                        Some(list_type): slot_typ = list_type
                        None: assert false
                of expTerm:
                    if x[0].is_token(".."):
                        assert x.len == 2
                        extension = Some(x[1])
                        continue
                    if x[0].is_token("="):
                        name_typ = x[1]
                        slot_default = Some(x[2])
                    if not name_typ[0].is_token(":"):
                        raise local.error(exp=x, msg="Expected a pair `name : type`, but got {name_typ.str}. {name_typ.src}".fmt)
                    if name_typ[1].kind != expAtom:
                        raise local.error(exp=x, msg="Field name must be an atom, but got {name_typ[1].str}. {name_typ[1].src}".fmt)
                    slot_name = name_typ[1].value
                    let slot_typ_val = local.eval(name_typ[2])
                    slot_typ = local.reify(slot_typ_val)
                    list_type = Some(slot_typ)
                    local.env.assume(slot_name, slot_typ_val)

                slots.add(RecSlot(name: slot_name, typ: slot_typ, default: slot_default))

    return MakeRecTyp(slots, extensible, extension)

proc eval_record(ctx: Ctx, arg: Exp): Rec =
    var fields: seq[RecField]
    let local = ctx.extend()
    for exp in arg.exprs:
        let (name_exp, typ_exp, val_exp) = (exp[0], exp[1], exp[2])
        let name = name_exp.value
        let val = ctx.eval(val_exp)
        var typ = ctx.infer_type(val_exp)
        if not typ_exp.is_nil:
            let exp_typ = ctx.eval(typ_exp)
            if not ctx.is_subtype(typ, exp_typ):
                raise ctx.error(exp=exp, msg="Expected value of {exp_typ}, but found {val} of {typ}. {exp.src}".fmt)
            typ = exp_typ
        local.env.define(name, val, typ, Some(exp))
        fields.add(RecField(name: name, val: val, typ: typ))
    return MakeRec(fields)

proc record_infer(ctx: Ctx, arg: Exp): RecTyp =
    var slots: seq[RecSlot]
    let local = ctx.extend()
    for exp in arg.exprs:
        let (name_exp, typ_exp, val_exp) = (exp[0], exp[1], exp[2])
        let name = name_exp.value
        let typ_val = if not typ_exp.is_nil:
            local.eval(typ_exp)
        else:
            local.infer_type(val_exp)
        local.env.assume(name, typ_val)
        slots.add(RecSlot(name: name, typ: local.reify(typ_val), value: Some(val_exp)))
    return MakeRecTyp(slots)

#
# Syntax sugar
#

proc expand_group(ctx: Ctx, exprs: Exp): Exp =
    # `(_)` : (args: [[[Expr]]]) -> Eval(Expr)

    # Anatomy of a group:
    # (a b, d e; f g, h i)
    #  _ _  _ _  _ _  _ _ exprs       (level 0)
    #  ---  ---  ---  --- inner group (level 1)
    #  --------  -------- outer group (level 2)
    #  ------------------ total group (level 3)

    if exprs.len == 0:
        # ()
        return term(atom("record"), term())
    if exprs.len > 1:
        # (e1; e2; ...; en)
        return term(atom("block") & exprs.exprs)

    let lists = exprs[0].exprs
    if lists.len == 1 and lists[0].len == 1:
        # (e)
        # FIXME: detect single element tuple with a trailing comma (e,)
        let inner = lists[0][0]
        let is_tuple = inner.is_term(3) and inner[0].is_token("=")
        if not is_tuple:
            return inner

    return expand_record(ctx, exprs[0])

proc expand_define(ctx: Ctx, lhs, rhs: Exp): Exp =
    if lhs.is_term:
        if lhs.has_prefix("->"):
            # short function definition with return type
            let name = lhs[1][1]
            let params = term(atom("(_)"), lhs[1][2])
            let res_typ = lhs[2]
            let fun_typ = term(atom("->"), params, res_typ)
            let fun = term(atom("=>"), fun_typ, rhs)
            return term(atom("define"), name, fun)
        if lhs.has_prefix("()"):
            # short function definition or pattern matching
            let name = lhs[1]
            let params = term(atom("(_)"), lhs[2])
            let fun = term(atom("=>"), params, rhs)
            return term(atom("define"), name, fun)
    return term(atom("define"), lhs, rhs)

proc expand_compare(ctx: Ctx, args: seq[Exp]): Exp =
    # TODO: handle more cases
    let exp = term(args)
    if args.len != 3: raise ctx.error("Only two-argument comparisons are supported right now. {ctx.src}".fmt)
    term(args[1], args[0], args[2])

#
# Base functionality
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

proc eval_name(ctx: Ctx, exp: Exp): Val =
    let name = exp.value
    let vari = ctx.env.lookup(name).or_else:
        raise ctx.error("Variable {name.bold} is not defined or assumed. {exp.src}".fmt)
    if vari.val.is_none and ctx.eval_mode == EvalMode.Unwrap:
        raise ctx.error("Can't unwrap because {name.bold} is not defined. {exp.src}".fmt)
    if vari.opaque and ctx.eval_mode != EvalMode.Unwrap:
        return Neu(exp)
    vari.val ?? Neu(exp)

proc eval_define(ctx: Ctx, lhs, rhs: Exp, only_assume = false): Val =
    var (lhs, rhs) = (lhs, rhs)
    var lhs_typ = None(Val)
    var opaque = false
    if lhs.has_prefix(":"):
        lhs_typ = Some(ctx.eval(lhs[2]))
        lhs = lhs[1]
    if lhs.has_prefix("opaque"):
        opaque = true
        lhs = lhs[1]
    if lhs.kind != expAtom:
        raise error(lhs, "Expected an Atom on the left side of definition, but found Term {lhs}. {lhs.src}".fmt)
    let name = lhs.value
    if name in ctx.env.vars and ctx.env.vars[name].val.is_some:
        let vari = ctx.env.vars[name]
        let site = vari.site.map(x => "\n\nIt was already defined here: {x.src(hi=false)}".fmt) ?? ""
        raise error(lhs, "Cannot define `{name}`. {lhs.src} {site}".fmt)
    var rhs_typ = ctx.infer_type(rhs)
    lhs_typ.if_some(lhs_typ):
        if not ctx.is_subtype(rhs_typ, lhs_typ):
            raise ctx.error(exp=rhs, msg="Can't coerce {rhs} of type {rhs_typ.bold} to type {lhs_typ.bold}. {rhs.src}".fmt)
    let typ = lhs_typ ?? rhs_typ
    let site = term(lhs, rhs)
    if only_assume:
        ctx.env.assume(name, typ, site=Some(site))
    var rhs_val = ctx.eval(rhs)
    if rhs_val.kind == FunVal:
        rhs_val.fun.name = name
    #echo "define {name} = {rhs_val}".fmt
    ctx.env.define(name, rhs_val, typ, site=Some(site), opaque=opaque)
    return unit

proc eval_assume(ctx: Ctx, lhs, rhs: Exp): Val =
    var names: seq[string]
    if lhs.kind == expAtom:
        names.add(lhs.value)
    elif lhs.has_prefix(","):
        for arg in lhs.tail:
            if arg.kind != expAtom:
                raise error(arg, fmt"The left side of assumption must be a list of names. {arg.src}")
            names.add(arg.value)
    else:
        raise error(lhs, fmt"The left side of assumption must be a name or a list of names. {lhs.src}")

    for name in names:
        let local = ctx.env.find(name)
        let exp = term(lhs, rhs)
        if local != nil:
            if local.vars[name].site.is_none:
                local.vars[name].site = Some(exp)

            match local.vars[name].val:
                None:
                    if ctx.env == local:
                        raise error(exp, "Already assumed {name} in this scope. {exp.src}".fmt)
                Some(val):
                    if val.kind == FunVal and val.fun.builtin:
                        let builtin = val.fun.builtin
                        let typ_val = ctx.eval(rhs)
                        if typ_val.kind != FunTypeVal:
                            raise ctx.error(exp=rhs, msg="The type of builtin function {val.fun.name.bold} must be a function type, but got {typ_val.noun} {typ_val.bold}. {rhs.src}".fmt)
                        let typ = typ_val.fun_typ
                        local.vars[name].typ = Some(Val(kind: FunTypeVal, fun_typ: typ))
                        local.vars[name].val = Some(Box(Fun(
                            name: val.fun.name,
                            body: val.fun.body,
                            typ: Some(typ),
                            ctx: None(Ctx),
                            builtin: true,
                        )))

        else:
            let typ = ctx.eval(rhs)
            ctx.env.assume(name, typ, site=Some(exp))

    return unit

proc v_cast(ctx: Ctx, lhs: Exp, dst_typ: Val): Val =
    var src_typ = ctx.infer_type(lhs)
    let dst_typ = if dst_typ.kind == NeuVal: ctx.unwrap(dst_typ.exp) else: dst_typ
    # check if can cast to subtype
    if not ctx.is_subtype(src_typ, dst_typ):
        raise error(lhs, "You can't cast {lhs.bold} of {src_typ.bold} to type {dst_typ.bold}.\n\n".fmt &
        "Can't upcast, because type {src_typ.bold} is not a subtype of {dst_typ.bold}.\n\n".fmt &
        "Can't downcast, because there is no evidence, that {lhs.bold} was upcast from type {dst_typ.bold}. {lhs.src}".fmt)
    return ctx.eval(lhs)

proc eval_union*(ctx: Ctx, args: seq[Val]): Val =
    let args = args[0].values
    if args.len == 0: return UnionType()
    if args.len == 1: return args[0]
    return norm_union(args)

proc eval_inter*(ctx: Ctx, args: seq[Val]): Val =
    let args = args[0].values 
    if args.len == 0: return InterType()
    if args.len == 1: return args[0]
    return norm_inter(args)

proc eval_match(ctx: Ctx, lhs_exp: Exp, rhs_val: Val): bool =
    if lhs_exp.is_token("_"): return true
    let lhs_val = ctx.eval(lhs_exp)
    return lhs_val == rhs_val

proc infer_case(ctx: Ctx, switch_exp: Exp, cases: seq[Exp]): Val =
    #let branches = exp.exprs[2 .. ^1]
    var types: seq[Val]
    for x in cases:
        let (pattern, body) = (x[0], x[1])
        types.add(ctx.infer_type(body))
    eval_union(ctx, @[MakeListLit(types)])

proc eval_case(ctx: Ctx, switch_exp: Exp, cases: seq[Exp]): Val =
    let switch = ctx.eval(switch_exp)
    let typ = ctx.infer_type(switch_exp)
    if switch.kind == NeuVal:
        raise ctx.error("Can't match on an unevaluated value {switch_exp.bold}. {switch_exp.src}".fmt)
    for branch in cases:
        let local = ctx.extend()
        if local.eval_match(branch[0], switch):
            return local.eval(branch[1])
    raise ctx.error("Not all cases covered for {switch.noun} {switch.bold} of type {typ.bold}. {switch_exp.src}".fmt)

#
# Assert & Tests
#

proc eval_test(ctx: Ctx, name: string, test: Exp) =
    try:
        let local = ctx.extend()
        discard local.eval(test)
        stdout.write "test " & name & " \e[32mPASSED\e[0m\n".fmt
    except VitaminError:
        stdout.write "test " & name & " \e[31mFAILED\e[0m\n".fmt
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error, prefix="ASSERTION FAILED")

proc eval_xtest(ctx: Ctx, name: string, body_exp: Exp) =
    echo "test {name} \e[33mSKIPPED\e[0m".fmt

proc eval_assert(ctx: Ctx, exp: Exp) =
    var cond = ctx.expand(exp)
    var negate = false
    if cond.has_prefix("compare"):
        cond = expand_compare(ctx, cond.tail)
    if cond.has_prefix("not"):
        cond = ctx.expand(cond[1])
        negate = true
    let neg = if negate: "not " else: ""
    let neg_neg = if negate: "" else: "not "
    if cond.has_prefix("==") or cond.has_prefix("!="):
        let op = cond[0].value
        let (lhs, rhs) = (cond[1], cond[2])
        #echo "{ctx.expand(lhs).str_ugly} ?= {ctx.expand(rhs).str_ugly}".fmt
        let actual_typ = ctx.infer_type(lhs)
        let expected_typ = ctx.infer_type(rhs)
        if not ctx.is_subtype(actual_typ, expected_typ):
            raise error(exp, "can't compare {lhs.str} of type {actual_typ.str} ".fmt &
                "with {rhs.str} of type {expected_typ.str}. {exp.src}".fmt)
        let (actual, expected) = (ctx.eval(lhs), ctx.eval(rhs))
        case op
        of "==":
            if not equal(actual, expected):
                raise error(exp, "Expected {lhs.bold}\nto equal {rhs.bold}".fmt &
                    "\n     but {actual.bold} != {expected.bold} {exp.src}".fmt)
        of "!=":
            if equal(actual, expected):
                raise error(exp, "Expected {lhs.bold}\nto not equal {rhs.bold}".fmt &
                    "\n         but {actual.bold} == {expected.bold} {exp.src}".fmt)
    elif cond.has_prefix("is-subtype"):
        let (lhs, rhs) = (cond[1], cond[2])
        let lhs_val = ctx.eval(lhs)
        let rhs_val = ctx.eval(rhs)
        if not ctx.is_subtype(lhs_val, rhs_val) xor negate:
            raise error(exp, "Expected {lhs_val.bold} to {neg}be a subtype of {rhs_val.bold}. {exp.src}".fmt)
    elif cond.has_prefix("error"):
        var cond = cond[1]
        var res = None(Val)
        try:
            res = Some(ctx.eval(cond))
        except VitaminError:
            discard

        match res:
            None:
                discard
            Some(val):
                raise error(cond, "Expected expression {cond.bold} to raise a compile-time error,\n".fmt &
                    "but it successfuly evaluated to {val.bold} of type {ctx.dynamic_type(val).bold}. {cond.src}".fmt)
    else:
        raise error(exp, "assert doesn't support expressions like {cond.bold} {exp.src}".fmt)

#
# Quasiquotation
#

proc unquote(ctx: Ctx, x: Exp): Exp =
    let res = ctx.eval(x[1])
    if res.kind != ExpVal:
        raise error(x, fmt"You can only unquote expressions, but you tried to unquote a value {res.str} of type {ctx.dynamic_type(res)}. {x.src}")
    res.exp

proc unquote_splice(ctx: Ctx, x: Exp): seq[Exp] =
    let res = ctx.eval(x[1])
    if res.kind != ExpVal:
        raise error(x, fmt"You can only splice terms, but you tried to splice a value of type {ctx.dynamic_type(res)}. {x.src}")
    let exp = res.exp
    if exp.kind != expTerm:
        raise error(x, fmt"You can only splice terms, but you tried to splice an atom `{exp.value}`. {x.src}")
    exp.exprs

proc quasiquote(ctx: Ctx, x: Exp): Exp =
    if x.kind == expAtom: return x
    if x.has_prefix("$"):
        return unquote(ctx, x)
    var exprs: seq[Exp]
    for sub in x.exprs:
        if sub.has_prefix("$$"):
            exprs &= unquote_splice(ctx, sub)
        else:
            exprs.add(quasiquote(ctx, sub))
    term(exprs)

#
# Interpreter 
#

proc dynamic_level(ctx: Ctx, val: RecTyp): int =
    result = 0
    for slot in val.slots:
        result = max(result, ctx.infer_level(slot.typ))

proc dynamic_level(ctx: Ctx, val: FunTyp): int =
    result = 0
    let local = ctx.extend()
    for par in val.params:
        local.env.assume(par.name, local.eval(par.typ))
        result = max(result, local.infer_level(par.typ))
    result = max(result, local.infer_level(val.result))

proc dynamic_level*(ctx: Ctx, val: Val): int =
    case val.kind
    of TypeVal:
        val.level + 1
    of NeuVal:
        ctx.dynamic_level(ctx.infer_type(val.exp))
    of UnionTypeVal, InterTypeVal:
        max_or(val.values.map_it(ctx.dynamic_level(it)), default=0)
    of RecTypeVal:
        ctx.dynamic_level(val.rec_typ)
    of FunTypeVal:
        ctx.dynamic_level(val.fun_typ)
    else:
        raise error("`level-of` expected an argument of Type, but got {val.str}.".fmt)

proc reify_fun_params*(params: seq[FunParam]): Exp =
    var exps: seq[Exp]
    for par in params:
        let default = par.default ?? term()
        exps.add(term(atom(par.name), par.typ, default))
    term(exps)

proc dynamic_type*(ctx: Ctx, val: Val): Val =
    case val.kind
    of TypeVal, RecTypeVal, FunTypeVal, UnionTypeVal, InterTypeVal:
        Universe(ctx.dynamic_level(val))
    of RecVal:
        var slots: seq[RecSlot]
        for field in val.rec.fields:
            slots.add(RecSlot(name: field.name, typ: ctx.reify(field.typ)))
        Box(MakeRecTyp(slots))
    of FunVal:
        Val(kind: FunTypeVal, fun_typ: get_typ(ctx, val.fun))
    of I8:  ctx.eval("I8".atom)
    of U8:  ctx.eval("U8".atom)
    of I64: ctx.eval("I64".atom)
    of U64: ctx.eval("U64".atom)
    of MemVal:  ctx.eval("Size".atom)
    of NumLit:  ctx.eval("Num-Literal".atom)
    of StrLit:  ctx.eval("Str-Literal".atom)
    of ListLit: ctx.eval("List-Literal".atom)
    of ExpVal:
        case val.exp.kind
        of expAtom: ctx.eval("Atom".atom)
        of expTerm: ctx.eval("Term".atom)
    of NeuVal:
        ctx.infer_type(val.exp)

proc infer_apply*(ctx: Ctx, exp: Exp): Val =
    let head_exp = exp[0]
    let head_typ = ctx.infer_type(head_exp)
    #ctx.push_call(exp, infer=true)
    #defer: ctx.pop_call()
    case head_typ.kind
    of FunTypeVal:
        let args = ctx.match_apply_args(exp).tail
        let typ = head_typ.fun_typ

        # TODO: skip defining parameters if not a dependent type
        let local = ctx.extend()
        for (par, arg) in zip(typ.params, args):
            let arg_val = local.eval(arg)
            let par_typ = local.eval(par.typ)
            local.env.define(par.name, arg_val, par_typ)

        let res_typ = local.eval(typ.result)
        return res_typ

    of TypeVal:
        let head = ctx.eval(head_exp)
        case head.kind
        of RecTypeVal:
            return head
        else:
            raise ctx.error(exp=exp, msg="Can't use function call syntax to construct a value of type {head}. {ctx.src}".fmt)
    else:
        raise ctx.error(exp=exp, msg="Can't infer type of expression, because {head_exp.bold} of {head_typ.noun} {head_typ.bold} is not callable. {exp.src}".fmt)

proc infer_block*(ctx: Ctx, exp: Exp): Val =
    result = unit_type
    for stat in exp.tail:
        result = ctx.infer_type(stat)

proc match_apply_args(ctx: Ctx, exp: Exp): Exp =
    let (head, tail) = (exp[0], exp.tail)

    let head_typ = ctx.infer_type(head)
    if head_typ.kind != FunTypeVal:
        return exp

    let UNSET = 0
    let DEFAULT = 1
    let DONE = 2
    let typ = head_typ.fun_typ
    let par_count = typ.params.len
    var par_name = typ.params.map_it(it.name)
    var arg_norm = new_seq[Exp](par_count)
    var par_done = new_seq[int](par_count)
    var arg_done = new_seq[bool](tail.len)
    var variadic_par = -1
    var variadic_arg : seq[Exp]

    for i, par in typ.params:
        if par.variadic:
            variadic_par = i
            par_done[i] = DEFAULT
        par.default.if_some(arg_default):
            arg_norm[i] = arg_default
            par_done[i] = DEFAULT

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
            arg_norm[i] = term(atom("$quote"), arg_norm[i])

    if variadic_par != -1 and typ.params[variadic_par].quoted:
        variadic_arg = variadic_arg.map_it(term(atom("$quote"), it))

    let local = ctx.extend()
    for i, (arg, par) in zip(arg_norm, typ.params):
        if par.variadic:
            let par = typ.params[variadic_par]
            let par_typ = local.eval(par.typ)
            for arg in variadic_arg:
                let arg_typ = local.infer_type(arg)
                if not local.is_subtype(arg_typ, par_typ):
                    raise local.error(exp=arg, msg="Value for variadic parameter {par.name.bold} must be of type {par_typ.bold}, but got {arg.bold} of type {arg_typ.bold}. {exp.src}".fmt)
            arg_norm[i] = term(atom("$list") & variadic_arg)
        else:
            let arg_typ = local.infer_type(arg)
            let par_typ = local.eval(par.typ)
            if not local.is_subtype(arg_typ, par_typ):
                raise local.error(exp=arg, msg="Value for parameter {par.name.bold} must be of type {par_typ.bold}, but got {arg.bold} of type {arg_typ.bold}. {exp.src}".fmt)
            let arg_val = local.eval(arg)
            local.env.define(par.name, arg_val, par_typ)

    term(head & arg_norm)

proc is_macro_expr*(ctx: Ctx, exp: Exp): bool =
    if exp.len >= 1 and exp.head.is_atom:
        let typ = ctx.env.lookup_type(exp.head.value).or_else: return false
        if typ.kind == FunTypeVal:
            return typ.fun_typ.is_macro
    return false

#
# Core functions
#

proc unwrap*(ctx: Ctx, exp: Exp): Val =
    let new_ctx = ctx.extend(new_env=false, eval_mode=EvalMode.Unwrap)
    new_ctx.eval(exp)

proc norm*(ctx: Ctx, exp: Exp): Exp =
    let new_ctx = ctx.extend(new_env=false, eval_mode=EvalMode.Norm)
    new_ctx.reify(new_ctx.eval(exp))

proc reify*(ctx: Ctx, val: Val): Exp =
    case val.kind
    of TypeVal:
        atom("Type")
    of ExpVal:
        term(atom("$quote"), val.exp)
    of NumLit:
        atom(val.str, tag=aNum)
    of StrLit:
        atom("\"" & val.str.escape & "\"", tag=aStr)
    of NeuVal:
        return val.exp
    of UnionTypeVal, InterTypeVal:
        let op = case val.kind
        of UnionTypeVal: "Union"
        of InterTypeVal: "Inter"
        else: raise
        term(atom(op) & val.values.map_it(ctx.reify(it)))
    of FunTypeVal:
        # TODO: handle pragmas
        let ret_exp = val.fun_typ.result
        let par_exp = reify_fun_params(val.fun_typ.params)
        term(atom("Lambda"), par_exp, ret_exp)
    of FunVal:
        if val.fun.name != "": return atom(val.fun.name)
        let typ = val.fun.typ.or_else:
            raise ctx.error("Can't reify lambda without a type. {ctx.src}")
        if val.fun.body.is_right:
            raise ctx.error("Can't reify unnamed builtin lambda. {ctx.src")
        var body = val.fun.body.unsafe_left
        let ret_exp = typ.result
        let par_exp = reify_fun_params(typ.params)
        term(atom("lambda"), par_exp, ret_exp, body)
    of RecTypeVal:
        term(atom("Record"))
    of RecVal:
        term(atom("record"))
    else:
        raise ctx.error("Can't reify {val.noun} {val.bold}. {ctx.src}".fmt)

proc expand*(ctx: Ctx, exp: Exp): Exp =
    result = exp
    while ctx.is_macro_expr(result):
        var val = ctx.eval_apply(result)
        if val.kind != ExpVal:
            raise error(exp, "Expected macro {result} to return a value of type Expr, but got {val} of {ctx.dynamic_type(val)}. {exp.src}".fmt)
        result = val.exp

proc infer_level(ctx: Ctx, exp: Exp): int =
    ctx.dynamic_level(ctx.infer_type(exp))

proc infer_type*(ctx: Ctx, exp: Exp): Val =
    let exp = ctx.expand(exp)
    case exp.kind:
    of expAtom:
        case exp.tag:
        of aSym:
            let typ = ctx.env.lookup_type(exp.value).or_else:
                raise ctx.error("Type of {exp.bold} is unknown. {exp.src}".fmt)
            return typ
        of aNum:
            return ctx.eval("Num-Literal".atom)
        of aStr:
            return ctx.eval("Str-Literal".atom)
        else:
            discard
    of expTerm:
        if exp.len == 0:
            return unit
        if exp[0].kind == expAtom:
            case exp[0].value:
            of "$quote":
                return ctx.eval("Expr".atom)
            of "$list":
                return ctx.eval("List-Literal".atom)
            of "unwrap":
                return ctx.infer_type(exp[1])
            of "define":
                return ctx.eval("Unit".atom)
            of "case":
                return ctx.infer_case(exp[1], exp.exprs[2 .. ^1])
            of "as":
                return ctx.eval(exp[2])
            of "block":
                return ctx.infer_block(exp)
        return ctx.infer_apply(exp)
    raise ctx.error(trace=true, msg="infer-type not implemented for expression {exp}. {exp.src}".fmt)

proc eval*(ctx: Ctx, exp: Exp): Val =
    let exp = ctx.expand(exp)
    case exp.kind
    of expAtom:
        case exp.tag
        of aSym, aLit: return eval_name(ctx, exp)
        of aNum: return Val(kind: NumLit, lit: exp.value)
        of aStr: return Val(kind: StrLit, lit: exp.value.basic_str)
        else: raise ctx.error(exp=exp, msg="I don't know how to evaluate term {exp.str}. {exp.src}".fmt)
    of expTerm:
        if exp.len == 0:
            raise ctx.error(trace=true, msg="Can't evaluate empty term. {exp.src}".fmt)
        if exp[0].is_atom:
            case exp[0].value
            of "$list":
                return Val(kind: ListLit, values: ctx.eval_all(exp.tail))
            of "$quote":
                return if exp.len == 1: Box(term()) else: Box(exp[1])
            of "case":
                return ctx.eval_case(exp[1], exp.exprs[2 .. ^1])
            of "unwrap":
                return ctx.unwrap(exp[1])
            of "define":
                return ctx.eval_define(exp[1], exp[2])
            of ":":
                return ctx.eval_assume(exp[1], exp[2])
            of "as":
                return ctx.v_cast(exp[1], ctx.eval(exp[2]))
            of "block":
                var res = unit
                for stat in exp.tail:
                    res = eval(ctx, stat)
                return res
        return ctx.eval_apply(exp)
    raise ctx.error(exp=exp, msg="I don't know how to evaluate term {exp.str}. {exp.src}".fmt)

#
# Global context definitions
#

proc def_builtin_fun(ctx: Ctx, name: string, fun: BuiltinFunProc, typ: FunTyp) =
    let val = Box(Fun(name: name, body: Right[Exp, BuiltinFunProc](fun), typ: Some(typ), builtin: true))
    ctx.env.define name, val, ctx.dynamic_type(val)

proc set_builtin_fun(ctx: Ctx, name: string, fun: BuiltinFunProc) =
    let val = Box(Fun(name: name, body: Right[Exp, BuiltinFunProc](fun), builtin: true))
    ctx.env.vars[name] = Var(val: Some(val), typ: None(Val))

template set_builtin_fun_inline(gctx: Ctx, name: string, stat: untyped): untyped =
    gctx.set_builtin_fun name, (proc (ctx {.inject.}: Ctx, args {.inject.}: seq[Val]): Val = stat)

template def_builtin_fun_inline(gctx: Ctx, name: string, typ: FunTyp, stat: untyped): untyped =
    gctx.def_builtin_fun name, (proc (ctx {.inject.}: Ctx, args {.inject.}: seq[Val]): Val = stat), typ

var root_ctx* = Ctx(env: Env(parent: nil))

root_ctx.env.define "Type", type0, type1

root_ctx.env.assume "Atom", type0

root_ctx.env.assume "Term", type0

root_ctx.env.assume "Expr", type0

root_ctx.set_builtin_fun "Union", eval_union

root_ctx.set_builtin_fun "Inter", eval_inter

root_ctx.def_builtin_fun_inline "=", FunTyp(
    params: @[
        FunParam(name: "pattern", typ: atom("Expr"), quoted: true),
        FunParam(name: "expr", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
):
    Box(expand_define(ctx, args[0].exp, args[1].exp))

root_ctx.def_builtin_fun_inline "@", FunTyp(
    params: @[
        FunParam(name: "head", typ: atom("Expr"), quoted: true),
        FunParam(name: "args", typ: atom("Expr"), quoted: true),
        FunParam(name: "last", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
):
    Box(term(args[0].exp & args[1].exp.exprs & args[2].exp))

root_ctx.def_builtin_fun_inline "(_)", FunTyp(
    params: @[
        FunParam(name: "group", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
):
    Box(expand_group(ctx, args[0].exp))

root_ctx.def_builtin_fun_inline "()", FunTyp(
    params: @[
        FunParam(name: "func", typ: atom("Expr"), quoted: true),
        FunParam(name: "args", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
):
    Box(expand_apply(ctx, args[0].exp, args[1].exp))

root_ctx.def_builtin_fun_inline "=>", FunTyp(
    params: @[
        FunParam(name: "head", typ: atom("Expr"), quoted: true),
        FunParam(name: "body", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
):
    Box(expand_lambda(ctx, args[0].exp, args[1].exp))

root_ctx.def_builtin_fun_inline "->", FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr"), quoted: true),
        FunParam(name: "result", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
):
    let (par_exp, ret_exp) = (args[0].exp, args[1].exp)
    let par = desugar_lambda_type_params(ctx, par_exp)
    Box(term(atom("Lambda"), par, ret_exp))

root_ctx.def_builtin_fun_inline "lambda-infer", FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr")),
        FunParam(name: "result", typ: atom("Expr")),
        FunParam(name: "body", typ: atom("Expr")),
    ],
    result: atom("Type"),
):
    let (par, ret, body) = (args[0].exp.exprs, args[1].exp, args[2].exp)
    let (typ, _) = make_lambda_type(ctx, par, ret, body)
    Box(typ)

root_ctx.def_builtin_fun_inline "lambda", FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr"), quoted: true),
        FunParam(name: "result", typ: atom("Expr"), quoted: true),
        FunParam(name: "body", typ: atom("Expr"), quoted: true),
    ],
    result: term(atom("lambda-infer"), atom("params"), atom("result"), atom("body")),
):
    let (par, ret, body) = (args[0].exp.exprs, args[1].exp, args[2].exp)
    let (typ, closure) = make_lambda_type(ctx, par, ret, body)
    Box(MakeFun(typ=typ, body=body, ctx=closure))

root_ctx.def_builtin_fun_inline "Lambda", FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr"), quoted: true),
        FunParam(name: "result", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Type"),
):
    let (par, ret, body) = (args[0].exp.exprs, args[1].exp, term())
    let (typ, _) = make_lambda_type(ctx, par, ret, body)
    Box(typ)

root_ctx.def_builtin_fun_inline "quote", FunTyp(
    params: @[
        FunParam(name: "expr", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
):
    Box(quasiquote(ctx, args[0].exp))


root_ctx.set_builtin_fun_inline "print":
    stdout.write args[0].values.join(args[1].str) & args[2].str
    return unit

root_ctx.set_builtin_fun_inline "record":
    Box(eval_record(ctx, args[0].exp))

root_ctx.set_builtin_fun_inline "record-infer":
    Box(record_infer(ctx, args[0].exp))

root_ctx.set_builtin_fun_inline "Record":
    if args[0].values.len == 0: return unit_type
    Box(eval_record_type(ctx, args[0].values[0].exp))

root_ctx.set_builtin_fun_inline "type-of":
    ctx.infer_type(args[0].exp)

root_ctx.set_builtin_fun_inline "level-of":
    Val(kind: U64, u64: uint64(ctx.infer_level(args[0].exp)))

# non-essential definitions:

root_ctx.set_builtin_fun_inline "assert":
    eval_assert(ctx, args[0].exp)
    unit

root_ctx.set_builtin_fun_inline "test":
    eval_test(ctx, args[0].lit, args[1].exp)
    unit

root_ctx.set_builtin_fun_inline "xtest":
    eval_xtest(ctx, args[0].lit, args[1].exp)
    unit

root_ctx.set_builtin_fun_inline "==":
    if eval_equals(ctx, args[0].exp, args[1].exp):
        return ctx.eval(atom("true"))
    else:
        return ctx.eval(atom("false"))

root_ctx.set_builtin_fun_inline "gensym":
    Box(atom(gensym(prefix="__")))

root_ctx.set_builtin_fun_inline "compare": 
    ctx.eval(expand_compare(ctx, args.map_it(it.exp)))
    
root_ctx.set_builtin_fun_inline "eval":
    ctx.eval(args[0].exp)

root_ctx.set_builtin_fun_inline "num-i8":
    let num = parse_int(args[0].lit)
    if not (-128 <= num and num <= 127):
        raise ctx.error("Number literal {args[0]} does not fit in the range of type I8. {ctx.src}".fmt)
    Val(kind: I8, i8: int8(num))

root_ctx.set_builtin_fun_inline "num-u8":
    let num = parse_int(args[0].lit)
    if not (0 <= num and num <= 255):
        raise ctx.error("Number literal {args[0]} does not fit in the range of type U8. {ctx.src}".fmt)
    Val(kind: U8, u8: uint8(num))

root_ctx.set_builtin_fun_inline "num-i64":
    try:
        Val(kind: I64, i64: int64(parse_int(args[0].lit)))
    except ValueError:
        raise ctx.error("Number literal {args[0]} does not fit in the range of type I64. {ctx.src}".fmt)

root_ctx.set_builtin_fun_inline "num-u64":
    try:
        let num = parse_uint(args[0].lit)
        Val(kind: U64, u64: uint64(num))
    except ValueError:
        raise ctx.error("Number literal {args[0]} does not fit in the range of type U64. {ctx.src}".fmt)

root_ctx.set_builtin_fun_inline "inv":
    var lit = args[0].lit
    if lit[0] == '-': lit = lit[1 .. ^1] else: lit = "-" & lit
    Val(kind: NumLit, lit: lit)