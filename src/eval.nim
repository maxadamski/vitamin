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
let never* = UnionType()
let unreachable* = Val(kind: NeverVal)
let unit* = Box(Rec())
let unit_type* = Box(RecTyp())

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
    x.values.len == y.values.len
    #[
    if x.values.len != y.values.len: return false
    for xf in x.values:
        var found = false
        for yf in y.values:
            if xf.name == yf.name:
                if xf.val == yf.val:
                    found = true 
                    break
                else:
                    return false
        if not found:
            return false 
    return true
    ]#

func `==`(x, y: RecTyp): bool =
    if x.fields.len != y.fields.len: return false
    let x_fields = x.fields.sorted_by_it(it.name)
    let y_fields = y.fields.sorted_by_it(it.name)
    for (a, b) in zip(x_fields, y_fields):
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
    of NeverVal: true
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
    #echo $x, " ?= ", $y
    if x.fields.len != y.fields.len: return false
    let n = x.fields.len
    # FIXME: sort topologically by dependency order
    let x_fields = x.fields
    let y_fields = y.fields
    let local = ctx.extend()
    for (a, b) in zip(x_fields, y_fields):
        if a.name != b.name: return false
        let a_typ = local.eval(a.typ)
        let b_typ = local.eval(b.typ)
        if not a.default.is_nil:
            let a_val = local.eval(a.default)
            let a_typ = local.eval(a.typ)
            local.env.define(a.name, a_val, a_typ)
        if a_typ != b_typ: return false
    return true

proc is_subtype*(ctx: Ctx, x, y: Val): bool =
    #echo fmt"{x} {x.kind} ?= {y} {y.kind}"
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
    return x == y

func reify_param(param: FunParam): Exp =
    result = term("$param".atom, param.name.atom)
    result.exprs &= term(":".atom, param.typ)
    if param.default.is_some: result.exprs &= term("=".atom, param.default.unsafe_get)
    if param.variadic: result.exprs &= term("$variadic".atom, param.variadic_typ)
    if param.keyword: result.exprs &= "$keyword".atom
    if param.quoted: result.exprs &= "$quoted".atom

func reify_lambda_type(fun_typ: FunTyp): Exp =
    result.exprs &= "$Lambda".atom
    for param in fun_typ.params: result.exprs &= reify_param(param)
    result.exprs &= term("$result".atom, fun_typ.result)
    if fun_typ.autoexpand: result.exprs &= "$expand".atom

func reify_lambda(fun: Fun): Exp =
    if fun.name.len > 0: return fun.name.atom
    result.exprs &= "$lambda".atom & reify_lambda_type(fun.typ.unsafe_get).tail
    result.exprs &= term("$body".atom, fun.body.unsafe_left)

proc eval_lambda_param(ctx: Ctx, exp: Exp): FunParam =
    result.name = exp[1].value
    for part in exp.exprs[2 .. ^1]:
        if part.has_prefix(":"):
            result.typ = ctx.norm(part[1])
        elif part.has_prefix("="):
            result.default = Some(ctx.norm(part[1]))
        elif part.has_prefix("$variadic"):
            result.variadic = true
            result.variadic_typ = ctx.norm(part[1])
        elif part == atom("$quoted"):
            result.quoted = true
        elif part == atom("$keyword"):
            result.keyword = true

    let typ = if result.typ.is_nil:
        ctx.infer_type(result.default.unsafe_get)
    else:
        ctx.eval(result.typ)

    ctx.env.assume(result.name, typ, arg=true)

proc eval_lambda_type(ctx: Ctx, exp: Exp): FunTyp =
    # TODO: ensure that params form a DAG, and add params in topological order
    let local = ctx.extend()
    for part in exp.tail:
        if part.has_prefix("$param"):
            result.params &= local.eval_lambda_param(part)
        elif part.has_prefix("$result"):
            result.result = local.norm(part[1])
        elif part.is_atom("$expand"):
            result.autoexpand = true
        else:
            raise ctx.error("Unexpected $Lambda form {part.str_ugly}. {exp.src}".fmt)

proc infer_lambda_type(ctx: Ctx, exp: Exp, extend=true): FunTyp =
    var declared_type = unreachable
    var inferred_type = unreachable
    let local = if extend: ctx.extend() else: ctx
    for part in exp.tail:
        if part.has_prefix("$param"):
            result.params &= local.eval_lambda_param(part)
        elif part.has_prefix("$body"):
            inferred_type = local.infer_type(part[1])
        elif part.has_prefix("$result"):
            declared_type = local.eval(part[1])
        elif part.is_atom("$expand"):
            result.autoexpand = true
        else:
            assert false
    if not declared_type.is_never and not local.is_subtype(inferred_type, declared_type):
        raise ctx.error("Inferred type of body {inferred_type.str} is not a subtype of {declared_type.str}. {exp.src}".fmt)
    let returns = if not declared_type.is_never: declared_type else: inferred_type
    result.result = ctx.reify(returns)

proc eval_lambda(ctx: Ctx, exp: Exp): Fun =
    let local = ctx.extend()
    result.typ = Some(local.infer_lambda_type(exp, extend=false))
    result.ctx = Some(ctx)
    for part in exp.tail:
        if part.has_prefix("$body"):
            let body = local.norm(part[1])
            result.body = Left[Exp, BuiltinFunProc](body)

proc infer_record_type(ctx: Ctx, exp: Exp): RecTyp =
    for part in exp.tail:
        if part.has_prefix("$arg"):
            result.fields &= RecField(name: part[1].value, typ: ctx.reify(ctx.infer_type(part[2])))
        else:
            assert false

proc eval_record_type(ctx: Ctx, exp: Exp): RecTyp =
    let local = ctx.extend()
    for part in exp.tail:
        if part.has_prefix("$field"):
            var field : RecField
            field.name = part[1].value
            for part in part[2 .. ^1]:
                if part.has_prefix(":"):
                    field.typ = local.norm(part[1])
                elif part.has_prefix("="):
                    field.default = part[1]
                else:
                    assert false
            result.fields &= field
        else:
            assert false

proc eval_record(ctx: Ctx, exp: Exp): Rec =
    for part in exp.tail:
        if part.has_prefix("$arg"):
            let (name, val) = (part[1], part[2])
            result.values[name.value] = ctx.eval(val)
        else:
            raise

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
    #echo "eval " & exp.str_ugly
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
    let name = lhs.value
    let local = ctx.env.find(name)
    let exp = term(lhs, rhs)
    if local != nil:
        if local.vars[name].site.is_none:
            local.vars[name].site = Some(lhs)

        match local.vars[name].val:
            None:
                discard
                #if ctx.env == local:
                #    raise error(exp, "Already assumed {lhs} in this scope. {lhs.src}".fmt)
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
        if ctx.eval_mode == EvalMode.Norm:
            return Neu(term(@["case".atom, switch_exp] & cases))
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
    except AssertionDefect:
        echo get_current_exception().getStackTrace()
        stdout.write "test " & name & " \e[31mFAILED\e[0m\n".fmt
    except VitaminError:
        stdout.write "test " & name & " \e[31mFAILED\e[0m\n".fmt
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error, prefix="ASSERTION FAILED")

proc eval_xtest(ctx: Ctx, name: string, body_exp: Exp) =
    echo "test {name} \e[33mSKIPPED\e[0m".fmt

proc eval_assert(ctx: Ctx, exp: Exp) =
    var cond = ctx.expand(exp)
    var negate = false
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
# Interpreter 
#

proc dynamic_level(ctx: Ctx, val: RecTyp): int =
    result = 0
    for slot in val.fields:
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
    of NeverVal:
        never
    of TypeVal, RecTypeVal, FunTypeVal, UnionTypeVal, InterTypeVal:
        Universe(ctx.dynamic_level(val))
    of RecVal:
        var fields: seq[RecField]
        for (name, val) in val.rec.values.pairs:
            fields &= RecField(name: name, typ: ctx.reify(ctx.infer_type(ctx.reify(val))))
        Val(kind: RecTypeVal, rec_typ: RecTyp(fields: fields))
    of FunVal:
        let typ = val.fun.typ.or_else:
            raise ctx.error("Type of lambda {val.fun.name.bold} must be assumed before usage! {ctx.src}".fmt)
        Val(kind: FunTypeVal, fun_typ: typ)
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
        if arg.has_prefix("$define"):
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
            let par_typ = local.eval(par.variadic_typ)
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
            return typ.fun_typ.autoexpand
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
    of U8:
        term("num-u8".atom, atom($val.u8, aNum))
    of I8:
        term("num-i8".atom, atom($val.i8, aNum))
    of U64:
        term("num-u64".atom, atom($val.u64, aNum))
    of I64:
        term("num-i64".atom, atom($val.i64, aNum))
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
    of UnionTypeVal:
        term(atom("Union") & val.values.map_it(ctx.reify(it)))
    of InterTypeVal:
        term(atom("Inter") & val.values.map_it(ctx.reify(it)))
    of FunTypeVal:
        reify_lambda_type(val.fun_typ)
    of FunVal:
        reify_lambda(val.fun)
    of RecTypeVal:
        term(atom("$Record"))
    of RecVal:
        term(atom("$record"))
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
    #echo "infer " & exp.str_ugly
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
            of "$define":
                return ctx.eval("Unit".atom)
            of "$assume":
                return ctx.eval("Unit".atom)
            of "$Lambda":
                return Universe(ctx.dynamic_level(ctx.eval(exp)))
            of "$lambda":
                return Box(ctx.infer_lambda_type(exp))
            of "$Record":
                return Universe(ctx.dynamic_level(ctx.eval(exp)))
            of "$record":
                return Box(ctx.infer_record_type(exp))
            of "$quote":
                return ctx.eval("Expr".atom)
            of "$list":
                return ctx.eval("List-Literal".atom)
            of "$block":
                var res = unit_type
                for stat in exp.tail:
                    res = ctx.infer_type(stat)
                return res
            of "unwrap":
                return ctx.infer_type(exp[1])
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
    #echo "eval " & exp.str_ugly
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
            of "$define":
                return ctx.eval_define(exp[1], exp[2])
            of "$assume":
                return ctx.eval_assume(exp[1], exp[2])
            of "$Lambda":
                return Val(kind: FunTypeVal, fun_typ: ctx.eval_lambda_type(exp))
            of "$lambda":
                return Val(kind: FunVal, fun: ctx.eval_lambda(exp))
            of "$Record":
                return Val(kind: RecTypeVal, rec_typ: ctx.eval_record_type(exp))
            of "$record":
                return Val(kind: RecVal, rec: ctx.eval_record(exp))
            of "$quote":
                return if exp.len == 1: Box(term()) else: Box(exp[1])
            of "$block":
                var res = unit
                for stat in exp.tail:
                    res = eval(ctx, stat)
                return res
            of "$list":
                return Val(kind: ListLit, values: ctx.eval_all(exp.tail))
            of "case":
                return ctx.eval_case(exp[1], exp.exprs[2 .. ^1])
            of "unwrap":
                return ctx.unwrap(exp[1])
            of "as":
                return ctx.v_cast(exp[1], ctx.eval(exp[2]))
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

var root_ctx* = Ctx(env: Env(parent: nil))

root_ctx.env.define "Type", type0, type1

root_ctx.env.assume "Atom", type0

root_ctx.env.assume "Term", type0

root_ctx.env.assume "Expr", type0

root_ctx.set_builtin_fun "Union", eval_union

root_ctx.set_builtin_fun "Inter", eval_inter

root_ctx.set_builtin_fun_inline "type-of":
    ctx.infer_type(args[0].exp)

root_ctx.set_builtin_fun_inline "level-of":
    Val(kind: U64, u64: uint64(ctx.infer_level(args[0].exp)))

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

root_ctx.set_builtin_fun_inline "print":
    stdout.write args[0].values.join(args[1].str) & args[2].str
    return unit

root_ctx.set_builtin_fun_inline "gensym":
    Box(atom(gensym(prefix="__")))
    
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
