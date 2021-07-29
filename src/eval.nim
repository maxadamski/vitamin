import options, tables, sequtils, strformat, strutils, algorithm
import common/[exp, error, utils, types]
import patty
import sugar

# TODO: Allow access to the expression stack in macros

{.warning[ProveInit]: off.}

#
# Boilerplate forward declarations :/
#

proc eval*(ctx: Ctx, exp: Exp, unwrap = false): Val
proc dynamic_type*(ctx: Ctx, val: Val): Val
proc dynamic_level*(ctx: Ctx, val: Val): int
proc infer_type*(ctx: Ctx, exp: Exp): Val
proc infer_level*(ctx: Ctx, exp: Exp): int
proc reify*(ctx: Ctx, val: Val): Exp
proc norm*(ctx: Ctx, exp: Exp): Exp
proc expand*(ctx: Ctx, exp: Exp): Exp
proc is_subtype*(ctx: Ctx, x, y: Val): bool
func `==`*(x, y: Val): bool
func equal*(x, y: Val): bool = x == y

#
# Glooobals
#

var global_fun_id: uint32 = 1000
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

#
# Context
#

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
    let val = variable.val.or_else:
        return None[VarDefined]()
    Some(VarDefined(val: val, typ: typ, site: variable.site))

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

func `==`(x, y: Neu): bool =
    if x.args.len != y.args.len or x.head != y.head:
        return false
    for (u, v) in zip(x.args, y.args):
        if u != v:
            return false
    true

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
        if a.name != b.name or a.typ != b.typ: return false
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

func `==`*(x, y: Val): bool =
    if x.kind != y.kind: return false
    case x.kind
    of TypeVal: x.level == y.level
    of UnionTypeVal, InterTypeVal: sets_equal(x.values, y.values)
    of UniqueVal: x == y
    of HoldVal: x.name == y.name
    of NeuVal: x.neu == y.neu
    of FunTypeVal: x.fun_typ == y.fun_typ
    of FunVal: x.fun == y.fun
    of RecVal: x.rec == y.rec
    of RecTypeVal: x.rec_typ == y.rec_typ
    of NumVal, StrVal: x.lit == y.lit
    of ExpVal: x.exp == y.exp
    of I8: x.i8 == y.i8
    of U8: x.u8 == y.u8
    of I64: x.i64 == y.i64
    of U64: x.u64 == y.u64
    else:
        raise error(term(), "Equality for {x.noun} {x} and {y.noun} {y} not implemented".fmt)

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
    var typ: Val
    var quoted = false
    var variadic = false
    var lazy = false
    var did_infer_typ = false
    var searched = false

    if not typ_exp.is_nil:
        var typ_exp = norm(ctx, typ_exp)
        while typ_exp.has_prefix_any(["Quoted", "Varargs", "Lazy"]):
            case typ_exp[0].value
            of "Quoted":
                typ_exp = typ_exp[1]
                quoted = true
            of "Varargs":
                typ_exp = typ_exp[1]
                variadic = true
            of "Lazy":
                typ_exp = typ_exp[1]
                lazy = true
        typ = ctx.eval(typ_exp)

    if val_exp.is_token("_"):
        searched = true
    elif not val_exp.is_nil:
        val = Some(val_exp)
        var val_typ = ctx.infer_type(val_exp)
        if typ_exp.is_nil:
            did_infer_typ = true
            typ = val_typ
        else:
            if not ctx.is_subtype(val_typ, typ):
                raise ctx.error(exp=param, msg="Value of {val_typ} can't be used as a default value for parameter of {typ}. {param.src}".fmt)

    elif typ_exp.is_nil:
        raise ctx.error(exp=param, msg="You have to provide a type or default value for function parameters. {param.src}".fmt)

    ctx.env.assume(name.value, typ)

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
    let local = ctx.extend()

    # TODO: ensure that params form a DAG, and add params in topological order
    # assume all params in the environment
    var param_list: seq[FunParam]
    for param in params:
        param_list.add(make_lambda_param(local, param))

    var ret_exp = ret
    var is_macro = false
    var is_pure = false # TODO: infer this
    var is_total = false # TODO: infer this
    var did_infer_result = false

    if not ret_exp.is_nil:
        ret_exp = local.expand(ret_exp)
        if ret_exp.has_prefix("Expand"):
            ret_exp = ret_exp[1]
            is_macro = true
        ret_exp = local.norm(ret_exp)

    if not body.is_nil:
        let body_typ = local.infer_type(body)
        if ret_exp.is_nil:
            did_infer_result = true
            ret_exp = local.reify(body_typ)
        else:
            let ret_typ = eval(local, ret_exp)
            if not ctx.is_subtype(body_typ, ret_typ):
                raise error(body, "Function body type {body_typ}, doesn't match expected return type {ret_typ}. {term(ret_exp, body).src}".fmt)
    elif ret_exp.is_nil:
        raise ctx.error("You have to provide a function result type or function body, so the result type can be inferred. {ctx.src}".fmt)

    let fun_typ = FunTyp(
        params: param_list,
        result: ret_exp,
        is_macro: is_macro,
        is_pure: is_pure,
        is_total: is_total,
    )

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

proc apply_lambda(ctx: Ctx, fun: Fun, exp: Exp, expand = true): Val =
    let typ = fun.typ.or_else:
        raise ctx.error(exp=exp, msg="Function type must be specified before invocation. {exp.src}".fmt)
    let args = exp.tail
    if args.len != typ.params.len:
        raise ctx.error(exp=exp, msg="Attempting to pass {args.len} arguments to an {typ.params.len} argument function. {exp.src}".fmt)

    #let local = fun.ctx ?? ctx.extend()
    let local = ctx.extend()
    var bindings: seq[Val]
    var hold = false
    for (par, arg_exp) in zip(typ.params, args):
        let arg_val = if par.quoted: Box(arg_exp) else: local.eval(arg_exp)
        let par_typ = local.eval(par.typ)
        if arg_val.kind == HoldVal:
            local.env.assume(par.name, par_typ)
            bindings.add(arg_val)
            hold = true
            continue
        if par.quoted:
            if par.typ == atom("Atom") and arg_exp.kind != expAtom:
                raise local.error(exp=arg_exp, msg="Expected an Atom but got a Term. {arg_exp.src}".fmt)
            if par.typ == atom("Term") and arg_exp.kind != expTerm:
                raise local.error(exp=arg_exp, msg="Expected a Term but got an Atom. {arg_exp.src}".fmt)
        else:
            let arg_typ = local.infer_type(arg_exp)
            if not ctx.is_subtype(arg_typ, par_typ):
                let arg_typ_typ = ctx.dynamic_type(arg_typ)
                let rule =  type_rule("{arg_exp} : {par_typ}".fmt, "{arg_exp} : {arg_typ}".fmt, "{par.name} : {par_typ}".fmt, "{arg_typ} : {arg_typ_typ}".fmt)
                raise local.error(exp=arg_exp, msg="Argument {arg_val} of {arg_typ.noun} {arg_typ} does not match type {par_typ} of parameter `{par.name}`. {arg_exp.src}\n\n".fmt &
                                                   "In the following function definition:\n\n>> {fun.name} : {Box(typ)}\n\nGoal not satisfied:\n\n{rule}".fmt)
        local.env.define(par.name, arg_val, par_typ)
        bindings.add(arg_val)

    if hold:
        return Box(Neu(head: Box(fun), args: bindings))

    match fun.body:
        Left(body):
            result = local.eval(body)
        Right(builtin):
            result = builtin(ctx, bindings)

    if typ.is_macro and expand:
        if result.kind != ExpVal:
            let res_typ = ctx.dynamic_type(result)
            raise error(exp, "Expected macro to return a value of type Expr, but got {res_typ}. {exp.src}".fmt)
        result = ctx.eval(result.exp)

proc eval_apply(ctx: Ctx, exp: Exp): Val =
    let exp = ctx.expand(exp)
    let head_exp = ctx.expand(exp[0])
    let head = ctx.eval(head_exp)
    case head.kind
    of FunVal:
        apply_lambda(ctx, head.fun, exp)
    of HoldVal, NeuVal, UniqueVal:
        # can't evaluate, so normalize arguments and return the term
        Box(Neu(head: head, args: exp.tail.map_it(ctx.eval(it))))
    of RecTypeVal:
        raise ctx.error(exp=exp, msg="[eval_apply] Record constructors not implemented. {exp.src}".fmt)
    else:
        let head_typ = ctx.dynamic_type(head)
        raise ctx.error(exp=exp, msg="Can't evaluate, because {head.noun} {head.bold} of type {head_typ.bold} is not callable.\n\nexpanded from {head_exp.bold}. {head_exp.src}".fmt)

func expand_apply(ctx: Ctx, lhs, rhs: Exp): Exp =
    # `()` : (func: Expr, args: [[[Expr]]]) -> Eval(Expr)
    var call = @[lhs]
    let total = rhs
    assert total.len <= 1
    for outer in total.exprs:
        for inner in outer.exprs:
            for exp in inner.exprs:
                call &= exp
    return term(call)

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
        return append(atom("block"), exprs.exprs)

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
            let fun = append(atom("=>"), fun_typ, rhs)
            return append(atom("define"), name, fun)
        if lhs.has_prefix("()"):
            # short function definition or pattern matching
            let name = lhs[1]
            let params = term(atom("(_)"), lhs[2])
            let fun = append(atom("=>"), params, rhs)
            return append(atom("define"), name, fun)
    return append(atom("define"), lhs, rhs)

proc expand_compare(ctx: Ctx, args: seq[Exp]): Exp =
    # TODO: handle more cases
    let exp = term(args)
    if args.len != 3: raise ctx.error("Only two-argument comparisons are supported right now. {ctx.src}".fmt)
    term(args[1], args[0], args[2])

#
# Base functionality
#

proc eval_name*(ctx: Ctx, exp: Exp, unwrap = false): Val =
    let name = exp.value
    let res = ctx.env.get(name).or_else:
        raise ctx.error("Variable {name.bold} is not defined or assumed. {exp.src}".fmt)
    let val = res.val.or_else:
        Hold(name)
    if val.kind == UniqueVal and not unwrap:
        return Hold(name)
    return val

proc eval_equals(ctx: Ctx, lhs, rhs: Exp): bool =
    let lhs_typ = ctx.infer_type(lhs)
    let rhs_typ = ctx.infer_type(rhs)
    let lhs_val = ctx.eval(lhs)
    let rhs_val = ctx.eval(rhs)
    if lhs_typ != rhs_typ:
        let exp = term(lhs, rhs)
        raise error(exp, "Can't compare arguments of different types {lhs_val} of {lhs_typ} and {rhs_val} of {rhs_typ}. {exp.src}".fmt)
    lhs_val == rhs_val

proc eval_define(ctx: Ctx, args: seq[Val]): Val =
    var (lhs, rhs) = (args[0].exp, args[1].exp)
    var lhs_typ = None(Val)
    if lhs.is_term and lhs.has_prefix(":"):
        lhs_typ = Some(ctx.eval(lhs[2]))
        lhs = lhs[1]
    if lhs.kind != expAtom:
        raise error(lhs, "Expected an Atom on the left side of definition, but found Term {lhs}. {lhs.src}".fmt)
    let name = lhs.value
    if name in ctx.env.vars and ctx.env.vars[name].val.is_some:
        let variable = ctx.env.vars[name]
        let site = variable.site.map(x => "\n\nIt was already defined here: {x.src(hi=false)}".fmt) ?? ""
        raise error(lhs, "Cannot define `{name}`. {lhs.src} {site}".fmt)
    var rhs_typ = ctx.infer_type(rhs)
    lhs_typ.if_some(lhs_typ):
        if not ctx.is_subtype(rhs_typ, lhs_typ):
            raise ctx.error(exp=rhs, msg="Can't coerce {rhs} of type {rhs_typ.bold} to type {lhs_typ.bold}. {rhs.src}".fmt)

    let typ = lhs_typ ?? rhs_typ
    var rhs_val = ctx.eval(rhs)
    if rhs_val.kind == FunVal:
        rhs_val.fun.name = name
    let site = term(lhs, rhs)
    ctx.env.define(name, rhs_val, typ, site)
    return Hold(name)

proc eval_assume(ctx: Ctx, args: seq[Val]): Val =
    let (lhs, rhs) = (args[0].exp, args[1].exp)
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
                            raise ctx.error(exp=rhs, msg="The type of builtin {val.fun.name} function must be a function type, but got {typ_val}. {rhs.src}".fmt)
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
            ctx.env.assume(name, typ, exp)
    return unit

proc v_cast(ctx: Ctx, val: Val, dst_typ: Val, exp: Exp = term()): Val =
    var src_typ = ctx.dynamic_type(val)
    let dst_typ = if dst_typ.kind == UniqueVal: dst_typ.inner else: dst_typ
    # check if can cast to subtype
    if ctx.is_subtype(src_typ, dst_typ):
        let res = val.deep_copy
        res.typ = Some(dst_typ)
        return res
    else:
        write_stack_trace()
        raise error(exp, "You can't cast {val.bold} of {src_typ.bold} to type {dst_typ.bold}.\n\n".fmt &
        "Can't upcast, because type {src_typ.bold} is not a subtype of {dst_typ.bold}.\n\n".fmt &
        "Can't downcast, because there is no evidence, that {val.bold} was upcast from type {dst_typ.bold}. {exp.src}".fmt)

proc eval_union*(ctx: Ctx, args: seq[Val]): Val =
    if args.len == 0: return UnionType()
    if args.len == 1: return args[0]
    return norm_union(args[0], args[1])

proc eval_inter*(ctx: Ctx, args: seq[Val]): Val =
    if args.len == 0: return InterType()
    if args.len == 1: return args[0]
    return norm_inter(args[0], args[1])

proc v_unwrap(ctx: Ctx, val: Val): Val =
    var val = val
    if val.kind == HoldVal:
        val = eval_name(ctx, atom(val.name), unwrap=true)
    if val.kind == NeuVal:
        let head = ctx.v_unwrap(val.neu.head)
        return ctx.eval(append(ctx.reify(head), val.neu.args.map_it(ctx.reify(it))))
    if val.kind != UniqueVal:
        raise ctx.error("Can't unwrap, because expression does not evaluate to a unique value. {ctx.src}".fmt)
    return val.inner

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
    eval_union(ctx, types)

proc eval_case(ctx: Ctx, switch_exp: Exp, cases: seq[Exp]): Val =
    let switch = ctx.eval(switch_exp)
    let typ = ctx.infer_type(switch_exp)
    for branch in cases:
        let local = ctx.extend()
        if local.eval_match(branch[0], switch):
            return local.eval(branch[1])
    raise ctx.error("Not all cases covered for {switch.noun} {switch.bold} of type {typ.bold}. {switch_exp.src}".fmt)

#
# Assert & Tests
#

proc eval_test(ctx: Ctx, name_exp, test: Exp) =
    if name_exp.kind != expAtom or name_exp.tag != aStr:
        raise error(name_exp, "Test description must be a string literal. {name_exp.src}")
    let name = name_exp.value
    stdout.write "test " & name & " "
    stdout.flush_file
    try:
        let local = ctx.extend()
        discard local.eval(test)
        stdout.write "\e[32mPASSED\e[0m\n".fmt
    except VitaminError:
        stdout.write "\e[31mFAILED\e[0m\n".fmt
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error, prefix="ASSERTION FAILED")

proc eval_xtest(ctx: Ctx, name_exp, body_exp: Exp) =
    if name_exp.kind != expAtom or name_exp.tag != aStr:
        raise error(name_exp, "Test description must be a string literal. {name_exp.src}")
    let name = name_exp.value
    echo "test {name} \e[33mSKIPPED\e[0m".fmt

proc eval_assert(ctx: Ctx, arg: Exp) =
    let exp = ctx.expand(arg)
    var cond = exp
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
        let actual_typ = ctx.infer_type(lhs)
        let expected_typ = ctx.infer_type(rhs)
        let (actual, expected) = (ctx.eval(lhs), ctx.eval(rhs))
        if actual.typ.is_some and not equal(actual_typ, expected_typ):
            raise error(exp, "can't compare {lhs.str} of type {actual_typ.str}".fmt &
                "with {rhs.str} of type {expected_typ.str}. {exp.src}".fmt)
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
                let typ = ctx.dynamic_type(val)
                raise error(cond, "Expected expression {cond.bold} to raise a compile-time error,\n".fmt &
                    "but it successfuly evaluated to {val.bold} of type {typ.bold}. {cond.src}".fmt)
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
    of HoldVal:
        ctx.dynamic_level(ctx.dynamic_type(val))
    of UnionTypeVal, InterTypeVal:
        max_or(val.values.map_it(ctx.dynamic_level(it)), default=0)
    of RecTypeVal:
        ctx.dynamic_level(val.rec_typ)
    of FunTypeVal:
        ctx.dynamic_level(val.fun_typ)
    else:
        raise error("`level-of` expected an argument of Type, but got {val.str}.".fmt)

proc infer_level(ctx: Ctx, exp: Exp): int =
    ctx.dynamic_level(ctx.infer_type(exp))

proc norm*(ctx: Ctx, exp: Exp): Exp =
    ctx.reify(ctx.eval(exp))

proc expand*(ctx: Ctx, exp: Exp): Exp =
    ctx.push_call(exp)
    defer: ctx.pop_call()

    if exp.len >= 1:
        if exp[0].kind == expAtom and ctx.env.get(exp[0].value).is_none:
            return exp
        let callee = ctx.eval(exp[0])
        case callee.kind
        of FunVal:
            let fun = callee.fun
            let typ = get_typ(ctx, fun)
            if typ.is_macro:
                let res = apply_lambda(ctx, fun, exp, expand=false)
                assert res.kind in {ExpVal, NeuVal}
                return expand(ctx, res.exp)
        else:
            discard
    exp

proc reify*(ctx: Ctx, val: Val): Exp =
    case val.kind
    of TypeVal:
        atom("Type")
    of ExpVal:
        val.exp
    of NumVal:
        atom(val.str, tag=aNum)
    of StrVal:
        atom(val.str, tag=aStr)
    of HoldVal:
        atom(val.name)
    of NeuVal:
        var exps = @[ctx.reify(val.neu.head)]
        for arg in val.neu.args:
            exps.add(ctx.reify(arg))
        term(exps)
    of UnionTypeVal, InterTypeVal:
        let op = case val.kind
        of UnionTypeVal: "Union"
        of InterTypeVal: "Inter"
        else: raise
        append(atom(op), val.values.map_it(reify(ctx, it)))
    of FunTypeVal:
        # TODO: handle pragmas
        var par_exp: seq[Exp]
        for par in val.fun_typ.params:
            let default = par.default ?? term()
            par_exp.add(term(atom(par.name), par.typ, default))
        let ret_exp = val.fun_typ.result
        term(atom("Lambda"), term(par_exp), ret_exp)
    of FunVal:
        assert val.fun.name != ""
        atom(val.fun.name)
    of RecTypeVal:
        term(atom("Record"))
    of RecVal:
        term(atom("record"))
    else:
        raise ctx.error("Can't reify {val.noun} {val.bold}. {ctx.src}".fmt)

proc dynamic_type*(ctx: Ctx, val: Val): Val =
    val.typ.if_some(typ):
        return typ

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
    of I8: Hold("I8")
    of U8: Hold("U8")
    of I64: Hold("I64")
    of U64: Hold("U64")
    of MemVal: Hold("Size")
    of NumVal: Hold("Num-Literal")
    of StrVal: Hold("Str-Literal")
    of ExpVal:
        case val.exp.kind
        of expAtom: Hold("Atom")
        of expTerm: Hold("Term")
    of UniqueVal:
        ctx.dynamic_type(val.inner)
    of NeuVal:
        let (head, args) = (val.neu.head, val.neu.args)
        let head_typ = ctx.dynamic_type(head)
        assert head_typ.kind == FunTypeVal
        let fun_typ = head_typ.fun_typ
        assert fun_typ.params.len == args.len
        let local = ctx.extend()
        for (arg_val, par) in zip(args, fun_typ.params):
            let par_typ = local.eval(par.typ)
            local.env.define(par.name, arg_val, par_typ)
        local.eval(fun_typ.result)
    of HoldVal:
        let variable = ctx.env.get_assumed(val.name).or_else:
            raise ctx.error("{val.name.bold} is not assumed. This shouldn't happen!".fmt)
        variable.typ

proc infer_type*(ctx: Ctx, exp: Exp): Val =
    let exp = ctx.expand(exp)
    ctx.push_call(exp, infer=true)
    defer: ctx.pop_call()
    case exp.kind:
    of expAtom:
        case exp.tag:
        of aSym, aLit:
            let name = exp.value
            let variable = ctx.env.get_assumed(name).or_else:
                raise ctx.error("Type of {name.bold} is unknown. {ctx.src}".fmt)
            return variable.typ
        else:
            # FIXME: do not use dynamic type
            return ctx.dynamic_type(ctx.eval(exp))
    of expTerm:
        if exp.len == 0:
            return unit
        if exp.len >= 1 and exp[0].kind == expAtom:
            case exp[0].value:
            of "unique":
                return ctx.infer_type(exp[1])
            of "unwrap":
                return ctx.dynamic_type(ctx.eval(exp))
            of "define":
                if exp[1].kind != expAtom:
                    raise ctx.error(exp=exp[1], msg="Expected an Atom on the left side of definition, but found Term {exp[1]}. {exp[1].src}".fmt)
                let name = exp[1].value
                var typ = ctx.infer_type(exp[2])
                ctx.env.assume(name, typ, exp)
                return typ
            of "block":
                var typ = unit_type
                for stat in exp.tail:
                    typ = ctx.infer_type(stat)
                return typ
            of "case":
                return ctx.infer_case(exp[1], exp.exprs[2 .. ^1])
            of "Union", "Inter":
                return type0
            of ":", "print":
                return unit_type
            else:
                discard
        if exp.len >= 1:
            let head_exp = ctx.expand(exp[0])
            let head_typ = ctx.infer_type(head_exp)
            ctx.push_call(exp, infer=true)
            defer: ctx.pop_call()
            case head_typ.kind
            of FunTypeVal:
                let fun_typ = head_typ.fun_typ
                let local = ctx.extend()
                # TODO: skip defining parameters if not a dependent type
                for (par, arg) in zip(fun_typ.params, exp.tail):
                    let arg_val = if par.quoted: Box(arg) else: local.eval(arg)
                    let par_typ = local.eval(par.typ)
                    local.env.define(par.name, arg_val, par_typ)
                let res_typ = local.eval(fun_typ.result)
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
    raise ctx.error(trace=true, msg="infer-type not implemented for expression {exp}. {exp.src}".fmt)

proc eval*(ctx: Ctx, exp: Exp, unwrap = false): Val =
    let exp = ctx.expand(exp)
    ctx.push_call(exp)
    defer: ctx.pop_call()
    case exp.kind
    of expAtom:
        case exp.tag
        of aSym, aLit: return eval_name(ctx, exp)
        of aNum: return Val(kind: NumVal, lit: exp.value)
        of aStr: return Val(kind: StrVal, lit: exp.value)
        else: raise ctx.error(exp=exp, msg="I don't know how to evaluate term {exp.str}. {exp.src}".fmt)
    of expTerm:
        if exp.len == 0:
            raise ctx.error(trace=true, msg="Can't evaluate empty term. {exp.src}".fmt)
        if exp.len >= 1 and exp[0].kind == expAtom:
            case exp[0].value
            of "block":
                var res = unit
                for stat in exp.tail:
                    res = eval(ctx, stat)
                return res
            of "print":
                echo exp.tail.map_it(eval(ctx, it)).join(" ")
                return unit
            of "case":
                return ctx.eval_case(exp[1], exp.exprs[2 .. ^1])
            of "unique": return Unique(ctx.eval(exp[1]))
            of "unwrap": return ctx.v_unwrap(ctx.eval(exp[1]))
            of ":": return eval_assume(ctx, exp.tail.map_it(Box(it)))
            of "define": return eval_define(ctx, exp.tail.map_it(Box(it)))
            of "Union": return eval_union(ctx, exp.tail.map_it(eval(ctx, it)))
            of "Inter": return eval_inter(ctx, exp.tail.map_it(eval(ctx, it)))
        if exp.len >= 1:
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
    gctx.set_builtin_fun name, proc (ctx {.inject.}: Ctx, args {.inject.}: seq[Val]): Val = stat

template def_builtin_fun_inline(gctx: Ctx, name: string, typ: FunTyp, stat: untyped): untyped =
    gctx.def_builtin_fun name, (proc (ctx {.inject.}: Ctx, args {.inject.}: seq[Val]): Val = stat), typ

var root_ctx* = Ctx(env: Env(parent: nil))

root_ctx.env.define "Type", type0, type1
root_ctx.env.assume "Atom", type0
root_ctx.env.assume "Term", type0
root_ctx.env.define "Expr", root_ctx.eval(term(atom("Union"), atom("Atom"), atom("Term"))), type0

root_ctx.def_builtin_fun_inline "=", FunTyp(
    params: @[
        FunParam(name: "pattern", typ: atom("Expr"), quoted: true),
        FunParam(name: "expr", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
):
    Box(expand_define(ctx, args[0].exp, args[1].exp))

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
    if not args[0].exp.is_term:
        raise ctx.error(trace=true, msg="First argument of `Lambda` - {args[0]} is not of type `Term`".fmt)
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
    let (typ, ctx) = make_lambda_type(ctx, par, ret, body)
    Box(MakeFun(typ=typ, body=body, ctx=ctx))

root_ctx.def_builtin_fun_inline "Lambda", FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr"), quoted: true),
        FunParam(name: "result", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Type"),
):
    if not args[0].exp.is_term:
        raise ctx.error(trace=true, msg="First argument of `Lambda` - {args[0]} is not of type `Term`".fmt)
    let (par, ret, body) = (args[0].exp.exprs, args[1].exp, term())
    let (typ, _) = make_lambda_type(ctx, par, ret, body)
    Box(typ)

root_ctx.set_builtin_fun_inline "record":
    Box(eval_record(ctx, args[0].exp))

root_ctx.set_builtin_fun_inline "record-infer":
    Box(record_infer(ctx, args[0].exp))

root_ctx.set_builtin_fun_inline "Record":
    if args.len == 0: return unit_type
    Box(eval_record_type(ctx, args[0].exp))

root_ctx.set_builtin_fun_inline "type-of":
    ctx.infer_type(args[0].exp)

root_ctx.set_builtin_fun_inline "level-of":
    Val(kind: U64, u64: uint64(ctx.infer_level(args[0].exp)))

# non-essential definitions:

root_ctx.set_builtin_fun_inline "assert":
    eval_assert(ctx, args[0].exp)
    unit

root_ctx.set_builtin_fun_inline "test":
    eval_test(ctx, args[0].exp, args[1].exp)
    unit

root_ctx.set_builtin_fun_inline "xtest":
    eval_xtest(ctx, args[0].exp, args[1].exp)
    unit

root_ctx.set_builtin_fun_inline "==":
    if eval_equals(ctx, args[0].exp, args[1].exp):
        return ctx.eval(atom("true"))
    else:
        return ctx.eval(atom("false"))

root_ctx.set_builtin_fun_inline "gensym":
    Box(atom(gensym(prefix="__")))

root_ctx.set_builtin_fun_inline "quote":
    Box(quasiquote(ctx, args[0].exp))

root_ctx.set_builtin_fun_inline "compare": 
    ctx.eval(expand_compare(ctx, args.map_it(it.exp)))

root_ctx.set_builtin_fun_inline "as":
    let (lhs, rhs) = (args[0].exp, args[1])
    v_cast(ctx, ctx.eval(lhs), rhs, exp=term(lhs))
    
root_ctx.set_builtin_fun_inline "eval":
    ctx.eval(args[0].exp)

root_ctx.set_builtin_fun_inline "i8":
    let num = parse_int(args[0].lit)
    if not (-128 <= num and num <= 127):
        raise ctx.error("Number literal {args[0]} does not fit in the range of type I8. {ctx.src}".fmt)
    Val(kind: I8, i8: int8(num))

root_ctx.set_builtin_fun_inline "u8":
    let num = parse_int(args[0].lit)
    if not (0 <= num and num <= 255):
        raise ctx.error("Number literal {args[0]} does not fit in the range of type U8. {ctx.src}".fmt)
    Val(kind: U8, u8: uint8(num))

root_ctx.set_builtin_fun_inline "i64":
    try:
        Val(kind: I64, i64: int64(parse_int(args[0].lit)))
    except ValueError:
        raise ctx.error("Number literal {args[0]} does not fit in the range of type I64. {ctx.src}".fmt)

root_ctx.set_builtin_fun_inline "u64":
    try:
        let num = parse_uint(args[0].lit)
        Val(kind: U64, u64: uint64(num))
    except ValueError:
        raise ctx.error("Number literal {args[0]} does not fit in the range of type U64. {ctx.src}".fmt)

root_ctx.set_builtin_fun_inline "inv":
    var lit = args[0].lit
    if lit[0] == '-': lit = lit[1 .. ^1] else: lit = "-" & lit
    Val(kind: NumVal, lit: lit)