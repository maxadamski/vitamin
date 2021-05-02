import options, tables, sequtils, strformat, strutils, algorithm
import common/[vm, exp, error]
from common/utils import reverse_iter, max_or

const debug_interp = 0

var global_fun_id: uint32 = 1000

# boilerplate declarations
#proc norm*(env: Env, exp: Exp): Exp
proc eval*(env: Env, exp: Exp, as_type: Option[Val], unwrap = false): Val
proc eval*(env: Env, exp: Exp, as_type: Val, unwrap = false): Val = eval(env, exp, some(as_type), unwrap)
proc eval*(env: Env, exp: Exp, unwrap = false): Val = eval(env, exp, none(Val), unwrap)
proc v_typeof*(env: Env, val: Val, as_type: Option[Val]): Val
proc v_typeof*(env: Env, val: Val, as_type: Val): Val = v_typeof(env, val, some(as_type))
proc v_typeof*(env: Env, val: Val): Val = v_typeof(env, val, none(Val))
proc v_infer*(env: Env, exp: Exp): Val
proc v_reify*(env: Env, val: Val): Exp
proc v_norm*(env: Env, exp: Exp): Exp
proc v_expand*(env: Env, exp: Exp): Exp

let type0* = Universe(1)
let type1* = Universe(2)
let unit* = Record()

proc is_univ(val: Val): bool =
    val.kind == TypeVal

proc is_type(env: Env, val: Val): bool =
    v_typeof(env, val).is_univ

proc infer_pure(env: Env, exp: Exp): bool =
    # TODO: implement me correctly!!!
    false

proc ensure_args_are_types(env: Env, args: seq[Exp]) =
    return
    for arg in args:
        let typ = v_infer(env, arg)
        if not typ.is_univ:
            raise error(arg, "Expected argument to be a type, but got a value of {typ}. {arg.src}".fmt)

proc ensure_args_are_not_types(env: Env, args: seq[Exp]) =
    for arg in args:
        let typ = v_infer(env, arg)
        if typ.is_univ:
            raise error(arg, "Expected argument to be a value, but got a level {typ.level} type. {arg.src}".fmt)
    
proc ensure_arg_count(exp: Exp, count: int) =
    let actual_count = exp.tail.len
    let plural = if count == 1: "" else: "s"
    if count != actual_count:
        raise error(exp, "Function `{exp[0]}` expected {count} argument{plural} but was given {actual_count}. {exp.src}".fmt)

#region [Blue] Records / Tuples

proc expand_record(env: Env, exp: Exp): Exp =
    # (e1, e2, .., en)
    var fields: seq[Exp]
    for group in exp.exprs:
        if group.len != 1:
            raise error(exp, "Tuple elements must be spearated by a comma {group.src}".fmt)

        let arg = group[0]
        if not arg.has_prefix("="):
            raise error(arg, "Missing label for record field {arg.src}".fmt)

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
            raise error(name, "Field name must be an atom, but got term {name}. {name.src}".fmt)

        fields.add(term(name, typ, val))
    return append(atom("record"), fields)

proc eval_record_type(env: Env, exp: Exp): Val =
    var slots: seq[RecSlot]
    var extensible = false
    var extension: Option[Exp]
    if exp.len == 1:
        return RecordType()
    for group in exp[1].exprs:
        for list in group.exprs: 
            var list_type: Val
            var has_type = false
            for x in list.exprs.reverse_iter:
                var slot: RecSlot
                var name_typ = x
                case x.kind
                of expAtom:
                    if x.value == "...":
                        extensible = true
                        continue
                    slot.name = x.value
                    if has_type: slot.typ = list_type
                of expTerm:
                    if x[0].is_token(".."):
                        assert x.len == 2
                        extension = some(x[1])
                        continue
                    if x[0].is_token("="):
                        name_typ = x[1]
                        slot.default = some(x[2])
                    if not name_typ[0].is_token(":"):
                        raise error(exp, "Expected a pair `name : type`, but got {name_typ.str}. {name_typ.src}".fmt)
                    if name_typ[1].kind != expAtom:
                        raise error(exp, "Field name must be an atom, but got {name_typ[1].str}. {name_typ[1].src}".fmt)
                    slot.name = name_typ[1].value
                    slot.typ = eval(env, name_typ[2])
                    list_type = slot.typ
                    has_type = true
                slots.add(slot)
    return RecordType(slots, extensible, extension)

proc eval_record(env: Env, exp: Exp): Val =
    var fields: seq[RecField]
    for arg in exp.tail:
        let (name, typ_exp, val_exp) = (arg[0], arg[1], arg[2])
        let val = eval(env, val_exp)
        var typ = v_typeof(env, val)
        if not typ_exp.is_nil:
            let exp_typ = eval(env, typ_exp)
            if not is_subtype(typ, exp_typ):
                raise error(arg, "Expected value of {exp_typ}, but found {val} of {typ}. {arg.src}".fmt)
            typ = exp_typ
        fields.add(RecField(name: name.value, val: val, typ: typ))
    return Record(fields)

#endregion

#region [Green] Lambdas / Functions

proc make_lambda_param(env: Env, param: Exp): FunParam =
    var (name, typ_exp, val_exp) = (param[0], param[1], param[2])
    if not name.is_atom:
        raise error(name, "Lambda parameter name must be an Atom, but got Term {name}. {name.src}".fmt)

    var val = none(Exp)
    var typ: Val
    var quoted = false
    var variadic = false
    var lazy = false
    var did_infer_typ = false
    var searched = false

    if not typ_exp.is_nil:
        var typ_exp = v_norm(env, typ_exp)
        while typ_exp.has_prefix_any(["Quoted", "Args", "Lazy"]):
            case typ_exp[0].value
            of "Quoted":
                typ_exp = typ_exp[1]
                quoted = true
            of "Args":
                typ_exp = typ_exp[1]
                variadic = true
            of "Lazy":
                typ_exp = typ_exp[1]
                lazy = true
        typ = eval(env, typ_exp)

    if val_exp.is_token("_"):
        searched = true
    elif not val_exp.is_nil:
        val = some(val_exp)
        var val_typ = v_infer(env, val_exp)
        if typ_exp.is_nil:
            did_infer_typ = true
            typ = val_typ
        else:
            if not is_subtype(val_typ, typ):
                raise error(param, "Value of {val_typ} can't be used as a default value for parameter of {typ}. {param.src}".fmt)

    elif typ_exp.is_nil:
        raise error(param, "You have to provide a type or default value for function parameters. {param.src}".fmt)

    env.assume(name.value, typ)

    FunParam(
        name: name.value,
        typ: v_reify(env, typ),
        default: val,
        did_infer_typ: did_infer_typ,
        quoted: quoted,
        variadic: variadic,
        lazy: lazy,
        searched: searched,
    )

proc make_lambda_type(env: Env, params: seq[Exp], ret: Exp, body: Option[Exp]): tuple[typ: FunTyp, env: Env] =
    let local = env.extend()

    # TODO: ensure that params form a DAG, and add params in topological order
    # assume all params in the environment
    var param_list: seq[FunParam]
    for param in params:
        param_list.add(make_lambda_param(local, param))

    var ret_exp = ret
    var ret_typ: Val
    var is_macro = false
    var is_pure = false
    var did_infer_result = false

    if not ret_exp.is_nil:
        ret_exp = v_norm(local, ret_exp)
        if ret_exp.has_prefix("Expand"):
            ret_exp = ret_exp[1]
            is_macro = true
        ret_typ = eval(local, ret_exp)

    if body.is_some:
        let typ = v_infer(local, body.get)
        if ret_exp.is_nil:
            did_infer_result = true
            ret_typ = typ
        else:
            if not is_subtype(typ, ret_typ):
                raise error(body.get, "Function body type {typ}, doesn't match expected return type {ret_typ}. {term(ret_exp, body.get).src}".fmt)
        is_pure = infer_pure(local, body.get)

    elif ret_exp.is_nil:
        let exp = term(params)
        raise error(exp, "You have to provide a function result type or function body, so the result type can be inferred. {exp.src}".fmt)

    let fun_typ = FunTyp(
        params: param_list,
        result: v_reify(local, ret_typ),
        is_macro: is_macro,
        is_pure: is_pure,
    )

    (typ: fun_typ, env: local)

proc desugar_lambda_type_params(exp: Exp): seq[Exp] =
    if not exp.has_prefix("(_)"): assert false
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
                        assert false
                inner_params.add(term(name, typ, val))
            result &= inner_params.reversed

proc expand_lambda_type(env: Env, exp: seq[Val]): Val =
    # `->` : (lhs rhs: Quoted(Expr)) -> Eval(Expr)
    let (par_exp, ret_exp) = (exp[0].exp, exp[1].exp)
    let par = desugar_lambda_type_params(par_exp)
    VExp(term(atom("Lambda"), term(par), ret_exp))

proc expand_lambda(env: Env, args: seq[Val]): Val =
    # `=>` : (lhs rhs: Quoted(Expr)) -> Eval(Expr)
    let (lhs, rhs) = (args[0].exp, args[1].exp)
    if lhs.has_prefix("(_)"):
        let params = desugar_lambda_type_params(lhs)
        VExp(term(atom("lambda"), term(params), term(), rhs))
    elif lhs.has_prefix("->"):
        let par = desugar_lambda_type_params(lhs[1])
        let ret = lhs[2]
        VExp(term(atom("lambda"), term(par), ret, rhs))
    else:
        raise error(lhs, "Bad lambda term ({lhs.str} => {rhs.str}). {lhs.src}".fmt)

proc eval_lambda_type(env: Env, args: seq[Val]): Val =
    # Lambda : (params: [Expr], result: Expr) -> Type
    let (par, ret) = (args[0].exp.exprs, args[1].exp)
    let (typ, _) = make_lambda_type(env, par, ret, none(Exp))
    LambdaType(typ)

proc eval_lambda(env: Env, args: seq[Val]): Val =
    # lambda : (params: [Expr], result: Expr, body: Expr) -> type-of-lambda(params, result, body)
    let (par, ret, body) = (args[0].exp.exprs, args[1].exp, args[2].exp)
    let (typ, env) = make_lambda_type(env, par, ret, some(body))
    Lambda(typ=typ, body=body, env=env)

#endregion

proc expand_group(env: Env, args: seq[Val]): Val =
    # `(_)` : (args: [[[Expr]]]) -> Eval(Expr)

    # Anatomy of a group:
    # (a b, d e; f g, h i)
    #  _ _  _ _  _ _  _ _ exprs       (level 0)
    #  ---  ---  ---  --- inner group (level 1)
    #  --------  -------- outer group (level 2)
    #  ------------------ total group (level 3)

    let exprs = args[0].exp
    if exprs.len == 0:
        # ()
        return VExp(term())
    if exprs.len > 1:
        # (e1; e2; ...; en)
        return VExp(append(atom("block"), exprs.exprs))

    let lists = exprs[0].exprs
    if lists.len == 1 and lists[0].len == 1:
        # (e)
        # FIXME: detect single element tuple with a trailing comma (e,)
        let inner = lists[0][0]
        let is_tuple = inner.is_term(3) and inner[0].is_token("=")
        if not is_tuple:
            return VExp(inner)

    return VExp(expand_record(env, exprs[0]))

proc expand_square_group(env: Env, args: seq[Val]): Val =
    # `(_)` : (args: [[[Expr]]]) -> Eval(Expr)

    # Anatomy of a group:
    # [a b, d e; f g, h i]
    #  _ _  _ _  _ _  _ _ exprs       (level 0)
    #  ---  ---  ---  --- inner group (level 1)
    #  --------  -------- outer group (level 2)
    #  ------------------ total group (level 3)

    var total = args[0].exp
    var total_list: seq[Exp]
    for outer in total.exprs:
        var outer_list: seq[Exp]
        for inner in outer.exprs:
            var inner_list: seq[Exp]
            for expr in inner.exprs:
                inner_list.add(expr)
            if inner_list.len == 1:
                outer_list = inner_list
            else:
                outer_list.add(append(atom("list"), inner_list))
        if outer_list.len == 1:
            total_list = outer_list
        else:
            total_list.add(append(atom("list"), outer_list))

    return VExp(append(atom("list"), total_list))

proc expand_apply(env: Env, args: seq[Val]): Val =
    return VExp(concat(args[0].exp, args[1].exp))

proc expand_compare(env: Env, exp: Exp): Exp =
    # TODO: handle more cases
    let args = exp.tail
    if args.len != 3: raise error(exp, "Only two-argument comparisons are supported right now. {exp.src}".fmt)
    term(args[1], args[0], args[2])

proc v_cast(env: Env, val: Val, dst_typ: Val, exp: Exp = term()): Val =
    var val = val
    let src_typ = v_typeof(env, val)
    # check if can cast to subtype
    if is_subtype(src_typ, dst_typ):
        val.typ = some(dst_typ)
        return val

    raise error(exp, "You can't cast `{val.str}` of `{src_typ.str}` to type `{dst_typ.str}`.\n\nCan't downcast, because type `{src_typ.str}` is not a subtype of `{dst_typ.str}`.\n\nCan't upcast, because there is no evidence, that `{val.str}` was downcast from type `{dst_typ.str}`. {exp.src}".fmt)
    
proc eval_as(env: Env, exp: Exp): Val =
    ensure_arg_count(exp, 2)
    let dst_typ = eval(env, exp[2])
    if not is_type(env, dst_typ):
        raise error(exp[2], "Second argument of `as` must be of Type, but got value {dst_typ}. {exp[2].src}".fmt)
    # eval rhs and cast literal
    let val = eval(env, exp[1], as_type=dst_typ)
    return v_cast(env, val, dst_typ, exp=exp)

proc eval_assert(env: Env, args: seq[Val]): Val =
    let exp = v_expand(env, args[0].exp)
    var cond = exp
    #var expect_error = false
    if cond.has_prefix("compare"):
        cond = expand_compare(env, cond)
    if cond.has_prefix("==") or cond.has_prefix("!="):
        let op = cond[0].value
        let (lhs, rhs) = (cond[1], cond[2])
        let (actual, expected) = (eval(env, lhs), eval(env, rhs))
        let expected_typ = v_typeof(env, expected)
        if actual.typ.is_some and not equal(actual.typ.get, expected_typ):
            raise error(exp, "can't compare {lhs.str} of type {actual.typ.get.str}".fmt &
                "with {rhs.str} of type {expected_typ.str}. {exp.src}".fmt)
        case op
        of "==":
            if not equal(actual, expected):
                raise error(exp, "expected `{lhs.str}`\nto equal `{rhs.str}`".fmt &
                    "\n     but `{actual.str}` != `{expected.str}` {exp.src}".fmt)
        of "!=":
            if equal(actual, expected):
                raise error(exp, "expected `{lhs.str}`\nto not equal `{rhs.str}`".fmt &
                    "\n         but `{actual.str}` == `{expected.str}` {exp.src}".fmt)
    elif cond.has_prefix("error"):
        var error = false
        var res: Val
        var cond = cond[1]
        try:
            res = eval(env, cond)
        except VitaminError:
            error = true
        if not error:
            let typ = v_typeof(env, res)
            raise error(cond, "expected expression `{cond}` to raise a compile-time error,\n".fmt &
                "but it successfuly evaluated to `{res.str}` of type `{typ.str}`. {cond.src}".fmt)

    else:
        raise error(exp, "assert doesn't support expressions like {exp.str} {exp.src}".fmt)
    return unit

proc eval_test(env: Env, args: seq[Val]): Val =
    let (name_exp, test) = (args[0].exp, args[1].exp)
    if name_exp.kind != expAtom or name_exp.tag != aStr:
        raise error(name_exp, "Test description must be a string literal. {name_exp.src}")
    let name = name_exp.value
    var pass = false
    try:
        let local = env.extend()
        discard eval(local, test)
        echo "test {name} \e[32mPASSED\e[0m".fmt
        pass = true
    except VitaminError:
        echo "test {name} \e[31mFAILED\e[0m\n".fmt
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error, prefix="ASSERTION FAILED")
        pass = false
    return unit

#region [Purple] Quasiquotes

proc unquote(env: Env, x: Exp): Exp =
    let res = eval(env, x[1])
    if res.kind != ExpVal:
        raise error(x, fmt"You can only unquote expressions, but you tried to unquote a value {res.str} of type {v_typeof(env, res)}. {x.src}")
    res.exp

proc unquote_splice(env: Env, x: Exp): seq[Exp] =
    let res = eval(env, x[1])
    if res.kind != ExpVal:
        raise error(x, fmt"You can only splice terms, but you tried to splice a value of type {v_typeof(env, res)}. {x.src}")
    let exp = res.exp
    if exp.kind != expTerm:
        raise error(x, fmt"You can only splice terms, but you tried to splice an atom `{exp.value}`. {x.src}")
    exp.exprs

proc quasiquote(env: Env, x: Exp): Exp =
    if x.kind == expAtom: return x
    if x.has_prefix("$"):
        return unquote(env, x)
    var exprs: seq[Exp]
    for sub in x.exprs:
        if sub.has_prefix("$$"):
            exprs &= unquote_splice(env, sub)
        else:
            exprs.add(quasiquote(env, sub))
    term(exprs)

#endregion

proc v_levelof*(env: Env, val: Val): int =
    case val.kind
    of TypeVal: val.level + 1
    of HoldVal: v_levelof(env, v_typeof(env, val))
    of UnionTypeVal, InterTypeVal: max_or(val.values.map_it(v_levelof(env, it)), default=0)
    of RecTypeVal: max_or(val.slots.map_it(v_levelof(env, it.typ)), default=0)
    of SetTypeVal: 0
    #of FunTypeVal: max(max_or(val.fun_typ.params.map_it(v_levelof(env, it.typ)), default=0), v_levelof(env, val.fun_typ.ret_typ))
    else: raise error("`level-of` expected an argument of Type, but got {v_typeof(env, val)}.")

proc v_typeof*(env: Env, val: Val, as_type: Option[Val]): Val =
    if val.typ.is_some: return val.typ.get
    case val.kind
    of TypeVal, RecTypeVal, FunTypeVal, SetTypeVal, UnionTypeVal, InterTypeVal,
        SymbolTypeVal:
        Universe(v_levelof(env, val))
    of RecVal:
        RecordType(val.fields.map_it(RecSlot(name: it.name, typ: it.typ)))
    of FunVal:
        Val(kind: FunTypeVal, fun_typ: val.fun.typ)
    of BuiltinFunVal:
        Val(kind: FunTypeVal, fun_typ: val.builtin_typ)
    of SymbolVal:
        Val(kind: SetTypeVal, values: @[val])
    of MemVal:
        Hold("Size")
    of NumVal:
        Hold("I64")
    of ExpVal:
        case val.exp.kind
        of expAtom: Hold("Atom")
        of expTerm: Hold("Term")
    of OpaqueVal:
        v_typeof(env, val.inner)
    of OpaqueFunVal:
        v_typeof(env, val.result)
    of HoldVal:
        let res = env.get_opt(val.name)
        if res.is_none:
            raise error("`{val.name}` is not assumed. This shouldn't happen!".fmt)
        res.get.typ
    #else:
    #    raise error("`type-of` not implemented for term {val.str} of kind {val.kind}.".fmt)

proc v_type_macro*(env: Env, exp: Exp): Val =
    #if exp.kind == expAtom and exp.tag in {aSym, aLit}:
    #    let name = exp.value
    #    let res = env.get_opt(name)
    #    if res.is_none:
    #        raise error(exp, "I don't know the type of `{name}` since it isn't defined or assumed. {exp.src}".fmt)
    #    return res.get.typ
    let val = eval(env, exp)
    return v_typeof(env, val)

proc expand_type(env: Env, exp: Exp): Exp =
    exp

proc v_match*(env: Env, lhs, rhs: Exp): bool =
    if lhs.is_token("_"): return true
    let lhs = eval(env, lhs)
    let rhs = eval(env, rhs)
    #echo "match " & lhs.str & " " & rhs.str
    return equal(lhs, rhs)

proc v_value_set*(env: Env, args: seq[Val]): Val =
    var set: seq[Val]
    for arg in args:
        if set.any_it(equal(it, arg)):
            continue
        else:
            set.add(arg)
    return Val(kind: SetTypeVal, values: set)

proc v_union*(env: Env, args: seq[Val]): Val =
    var set = Val(kind: SetTypeVal)
    var types: seq[Val]
    for arg in args:
        if arg.kind == UnionTypeVal and arg.values.len == 0:
            # A | Any = Any
            return arg
        if arg.kind == InterTypeVal and arg.values.len == 0:
            # A | Never = A
            continue
        case arg.kind
        of SetTypeVal:
            for val in arg.values:
                if not set.values.any_it(equal(it, val)):
                    set.values.add(val)
        of UnionTypeVal:
            for val in arg.values:
                if not types.any_it(equal(it, val)):
                    types.add(val)
        else:
            if not types.any_it(equal(it, arg)):
                types.add(arg)
    if set.values.len > 0:
        types.add(set)
    return UnionType(types)

proc v_inter*(env: Env, args: seq[Val]): Val =
    var set = Val(kind: SetTypeVal)
    var types: seq[Val]
    for arg in args:
        if arg.kind == UnionTypeVal and arg.values.len == 0:
            # A & Any = A
            continue
        if arg.kind == InterTypeVal and arg.values.len == 0:
            # A & Never = Never
            return arg
        case arg.kind
        of SetTypeVal:
            if set.values.len == 0:
                set.values = arg.values
                continue
            var new_set: seq[Val]
            for val in arg.values:
                if set.values.any_it(equal(it, val)):
                    new_set.add(val)
            set.values = new_set
        of InterTypeVal:
            for val in arg.values:
                if not types.any_it(equal(it, val)):
                    types.add(val)
        else:
            if not types.any_it(equal(it, arg)):
                types.add(arg)
    if set.values.len > 0:
        types.add(set)
    return InterType(types)

proc apply_builtin(env: Env, fun: Val, exp: Exp, expand = true): Val =
    let typ = fun.builtin_typ
    ensure_arg_count(exp, typ.params.len)

    var local = env.extend()
    var args: seq[Val]
    for (param, arg) in zip(typ.params, exp.tail):
        let val = if param.quoted:
            VExp(arg)
        else:
            eval(env, arg)
        let arg_typ = v_typeof(local, val)
        let par_typ = eval(local, param.typ)
        if not is_subtype(arg_typ, par_typ):
            raise error(arg, "Argument {val} of {arg_typ} does not match type {par_typ} of parameter `{param.name}`. {arg.src}\n\nIn the following function definition:\n\n>> {LambdaType(typ)}".fmt)
        local.declare(param.name, val, par_typ)
        args.add(val)

    #let args = exp.tail.map_it(eval(env, it))
    let res = fun.builtin_fun(env, args)
    if typ.is_macro and expand:
        assert res.kind == ExpVal
        return eval(env, res.exp)
    else:
        return res

proc apply_lambda(env: Env, fun: Val, exp: Exp, expand = true): Val =
    let fun_typ = fun.fun.typ
    ensure_arg_count(exp, fun_typ.params.len)

    var local = env.extend()
    let args = exp.tail
    var bindings: seq[(string, Val)]
    for (par, arg) in zip(fun_typ.params, args):
        let typ = eval(local, par.typ)
        let val = if par.quoted: VExp(arg) else: eval(local, arg, as_type=typ)
        local.vars[par.name] = Var(val: val, typ: typ, is_defined: true)
        bindings.add((par.name, val))
    let ret_typ = eval(local, fun_typ.result)
    var res = eval(local, fun.fun.body, as_type=ret_typ)
    if fun_typ.is_opaque:
        var name = ""
        if exp[0].kind == expAtom:
            name = exp[0].value
        res = Val(kind: OpaqueFunVal, disp_name: name, result: res, bindings: bindings, opaque_fun: fun.fun)
    if fun_typ.is_macro and expand:
        assert res.kind == ExpVal
        return eval(env, res.exp)
    return res

proc v_expand*(env: Env, exp: Exp): Exp =
    if exp.len >= 1:
        if exp[0].kind == expAtom and env.get_opt(exp[0].value).is_none:
            return exp
        let fun = eval(env, exp[0])
        case fun.kind
        of BuiltinFunVal:
            if fun.builtin_typ.is_macro:
                let res = apply_builtin(env, fun, exp, expand=false)
                assert res.kind == ExpVal
                return v_expand(env, res.exp)
        of FunVal:
            if fun.fun.typ.is_macro:
                let res = apply_lambda(env, fun, exp, expand=false)
                assert res.kind == ExpVal
                return v_expand(env, res.exp)

        else:
            discard
    exp

proc v_reify*(env: Env, val: Val): Exp =
    when debug_interp > 0:
        echo "reify " & val.str
    case val.kind
    of TypeVal:
        atom("Type")
    of ExpVal:
        val.exp
    of NumVal:
        atom($val.num)
    of HoldVal:
        atom(val.name)
    of UnionTypeVal, InterTypeVal, SetTypeVal:
        let op = case val.kind
        of UnionTypeVal: "|"
        of InterTypeVal: "&"
        of SetTypeVal: "Set"
        else: raise
        append(atom(op), val.values.map_it(v_reify(env, it)))
    of SymbolVal:
        term(atom("Symbol"), atom(val.name))
    of OpaqueFunVal:
        var args: seq[Exp]
        var local = env.extend()
        for (name, arg) in val.bindings:
            args.add(term(atom("="), atom(name), v_reify(local, arg)))
            local.assume(name, arg)
        append(atom(val.disp_name), args)
    of RecTypeVal:
        term(atom("Record"))
    of RecVal:
        term(atom("record"))
    else:
        raise error("Can't reify value {val.str} of kind {val.kind}.".fmt)

proc v_norm*(env: Env, exp: Exp): Exp =
    v_reify(env, eval(env, exp))

proc v_infer*(env: Env, exp: Exp): Val =
    # TODO: implement me correctly!!!
    let exp = v_expand(env, exp)
    when debug_interp > 0:
        echo "infer " & exp.str
    case exp.kind:
    of expAtom:
        case exp.tag:
        of aSym, aLit:
            let name = exp.value
            let res = env.get_opt(name)
            if res.is_none:
                #return Hold(name)
                raise error(exp, "Type of {name} is unknown. {exp.src}".fmt)
            if res.get.is_placeholder:
                return Hold(name)
            if not res.get.is_defined:
                #return Hold(name)
                raise error(exp, "{name} is assumed, but not defined. {exp.src}".fmt)
            return res.get.typ
        else:
            return v_typeof(env, eval(env, exp))

    of expTerm:
        if exp.len == 0:
            return unit

        if exp.len >= 1 and exp[0].kind == expAtom:
            case exp[0].value:
            of "=":
                ensure_arg_count(exp, 2)
                if exp[1].kind != expAtom:
                    raise error(exp[1], "Expected an Atom on the left side of definition, but found Term {exp[1]}. {exp[1].src}".fmt)
                let name = exp[1].value
                if name in env.vars and env.vars[name].is_defined:
                    let v = env.vars[name]
                    let d = if v.definition.is_some: "\n\nIt was already defined here: {v.definition.get.src(hi=false)}".fmt else: ""
                    raise error(exp, "Cannot define `{name}`. {exp.src} {d}".fmt)
                env.vars[name] = Var(is_placeholder: true)
                var typ = v_infer(env, exp[2])
                #if val.kind == CastVal:
                #    typ = val.typ
                #else:
                #    typ = v_typeof(env, val)
                env.assume(name, typ)
                return RecordType()
            of ":":
                return RecordType()
            of ":=":
                return v_infer(env, exp[1])
            of "case":
                let branches = exp.exprs[2 .. ^1]
                var types: seq[Val]
                for branch in branches:
                    types.add(v_infer(env, branch[1]))
                return v_union(env, types)
            of "if":
                #echo exp
                var types: seq[Val]
                types.add(v_infer(env, exp[2]))
                if not exp[4].is_nil:
                    types.add(v_infer(env, exp[4]))
                return v_union(env, types)
            of "for":
                return RecordType()
            of "block":
                var typ = RecordType()
                for stat in exp.tail:
                    typ = v_infer(env, stat)
                return typ
            of "|", "&", "Union", "Inter", "Set", "Record", "Lambda":
                return type0
            of "compare":
                return eval(env, atom("Bool"))
            of "list":
                return eval(env, atom("List"))
            of "Symbol":
                return Val(kind: SymbolTypeVal, name: exp[1].value)
            of "quote":
                return eval(env, atom("Expr"))
            of "print":
                return RecordType()
            of "opaque":
                return v_typeof(env, eval(env, exp))
            of "record":
                return RecordType()
            of "as":
                return eval(env, exp[2])
            else:
                discard

        if exp.len >= 1:
            let fun_typ = v_infer(env, exp[0])
            case fun_typ.kind
            #of BuiltinFunVal:
            #    return eval(env, fun_typ.builtin_typ.result)
            of FunTypeVal:
                let typ = fun_typ.fun_typ
                let local = env.extend()
                for par in typ.params:
                    local.assume(par.name, eval(local, par.typ))
                return eval(local, typ.result)
            #of HoldVal:
            #    let typ = v_typeof(env, fun)
            #    assert typ.kind == FunTypeVal
            #    return eval(env, typ.fun_typ.result)
            else:
                return Val(kind: InterTypeVal)

                #raise error(exp, "{fun_typ} is not a function type. {exp.src}".fmt)

    raise error(exp, "`infer` not implemented for expression {exp}. {exp.src}".fmt)

proc eval*(env: Env, exp: Exp, as_type: Option[Val], unwrap = false): Val =
    when debug_interp > 0:
        echo "eval " & exp.str_ugly
    case exp.kind
    of expAtom:
        case exp.tag
        of aSym, aLit:
            let name = exp.value
            let res = env.get_opt(name)
            if res.is_none:
                #return Hold(name)
                raise error(exp, "{name} is not defined. {exp.src}".fmt)
            if res.get.is_placeholder:
                return Hold(name)
            if not res.get.is_defined:
                #return Hold(name)
                raise error(exp, "{name} is assumed, but not defined. {exp.src}".fmt)
            let val = res.get.val
            if not unwrap and val.kind == OpaqueVal:
                return Hold(name)
            return val

        of aNum:

            let num = parse_int(exp.value)
            # TODO: check if can cast
            if as_type.is_some:
                return Val(kind: NumVal, num: num, typ: some(as_type.get))
            else:
                return Val(kind: NumVal, num: num)

        #of aStr:
        #    let str = exp.value
        #    let len = str.len
        #    let p = alloc(len * sizeof(uint8))
        #    copy_mem(p, cast[pointer](str.cstring), len)
        #    let val = Val(kind: MemVal, memory: p)
        #    return Val(kind: CastVal, val: val, typ: Hold("Str"))
        
        else:
            raise error(exp, "I don't know how to evaluate term {exp.str}. {exp.src}".fmt)

    of expTerm:
        if exp.len == 0:
            return unit
            #raise error(exp, "Can't evaluate empty term. {exp.src}".fmt)

        if exp.len >= 1 and exp[0].kind == expAtom:
            case exp[0].value
            of ":":
                ensure_arg_count(exp, 2)
                let lhs = exp[1]

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
                    let typ = eval(env, exp[2], as_type=type0)
                    env.assume(name, typ)

                return unit
            
            of "=":
                ensure_arg_count(exp, 2)
                if exp[1].kind != expAtom:
                    raise error(exp[1], "Expected an Atom on the left side of definition, but found Term {exp[1]}. {exp[1].src}".fmt)
                let name = exp[1].value
                if name in env.vars and env.vars[name].is_defined:
                    let v = env.vars[name]
                    let d = if v.definition.is_some: "\n\nIt was already defined here: {v.definition.get.src(hi=false)}".fmt else: ""
                    raise error(exp, "Cannot define `{name}`. {exp.src} {d}".fmt)
                env.vars[name] = Var(is_placeholder: true)
                #var typ = v_infer(env, exp[2])
                var val = eval(env, exp[2])
                let typ = v_typeof(env, val)
                env.vars[name] = Var(val: val, typ: typ, is_defined: true, definition: some(exp))
                return unit

            of ":=":
                let lhs = eval(env, exp[1])
                assert lhs.kind == MemVal
                if not lhs.wr:
                    raise error(exp, "Can't write to non-writable pointer. {exp.src}".fmt)
                let rhs = eval(env, exp[2], as_type=lhs.mem_typ)
                assert is_subtype(v_typeof(env, rhs), lhs.mem_typ)
                lhs.mem_ptr = rhs
                return rhs

            of "*":
                if exp.len == 2:
                    let res = eval(env, exp[1])
                    assert res.kind == MemVal
                    if not res.rd:
                        raise error(exp, "Can't read from non-readable pointer. {exp.src}".fmt)
                    return res.mem_ptr

                if exp.len == 3:
                    let lhs = eval(env, exp[1])
                    let rhs = eval(env, exp[2])
                    if lhs.kind != NumVal:
                        raise error(exp[1], "Argument must be numeric. {exp[1].src}".fmt)
                    if rhs.kind != NumVal:
                        raise error(exp[2], "Argument must be numeric. {exp[2].src}".fmt)
                    return Val(kind: NumVal, num: lhs.num * rhs.num)

            of "+":
                let lhs = eval(env, exp[1])
                let rhs = eval(env, exp[2])
                if lhs.kind != NumVal:
                    raise error(exp[1], "Argument must be numeric, but got {lhs.kind}. {exp[1].src}".fmt)
                if rhs.kind != NumVal:
                    raise error(exp[2], "Argument must be numeric, but got {rhs.kind}. {exp[2].src}".fmt)
                return Val(kind: NumVal, num: lhs.num + rhs.num)

            of "<":
                let lhs = eval(env, exp[1])
                let rhs = eval(env, exp[2])
                if lhs.kind != NumVal:
                    raise error(exp[1], "Argument must be numeric, but got {lhs.kind}. {exp[1].src}".fmt)
                if rhs.kind != NumVal:
                    raise error(exp[2], "Argument must be numeric, but got {rhs.kind}. {exp[2].src}".fmt)
                if lhs.num < rhs.num:
                    return eval(env, atom("true"))
                else:
                    return eval(env, atom("false"))

            of "==":
                let lhs = eval(env, exp[1])
                let rhs = eval(env, exp[2])
                let lhs_typ = v_typeof(env, lhs)
                let rhs_typ = v_typeof(env, rhs)
                if not equal(lhs_typ, rhs_typ):
                    raise error(exp, "Can't compare arguments of different types {lhs} of {lhs_typ} and {rhs} of {rhs_typ}. {exp.src}".fmt)
                if equal(lhs, rhs):
                    return eval(env, atom("true"))
                else:
                    return eval(env, atom("false"))

            of "case":
                let switch = exp[1]
                let typ = v_infer(env, switch)
                let branches = exp.exprs[2 .. ^1]
                for branch in branches:
                    let local = env.extend()
                    if v_match(local, branch[0], switch):
                        return eval(local, branch[1])
                raise error(exp, "Not all cases covered for value {switch} of {typ}. {exp.src}".fmt)

            of "block":
                var res = unit
                for stat in exp.tail:
                    res = eval(env, stat)
                return res

            of "Symbol":
                ensure_arg_count(exp, 1)
                if exp[1].kind != expAtom:
                    raise error(exp[1], "Symbol expected an Atom as it's sole argument, but was given Term {exp[1]}. {exp[1].src}".fmt)
                return Val(kind: SymbolVal, name: exp[1].value)
            of "Set":
                ensure_args_are_not_types(env, exp.tail)
                return v_value_set(env, exp.tail.map_it(eval(env, it)))
            of "Union":
                ensure_args_are_types(env, exp.tail)
                return v_union(env, exp.tail.map_it(eval(env, it)))
            of "Inter":
                ensure_args_are_types(env, exp.tail)
                return InterType(exp.tail.map_it(eval(env, it)))
            of "|":
                ensure_args_are_types(env, exp.tail)
                return v_union(env, exp.tail.map_it(eval(env, it)))
            of "&":
                ensure_args_are_types(env, exp.tail)
                return v_inter(env, exp.tail.map_it(eval(env, it)))
            of "type-of":
                ensure_arg_count(exp, 1)
                return v_type_macro(env, exp[1])
            of "level-of":
                ensure_arg_count(exp, 1)
                let level = v_levelof(env, eval(env, exp[1]))
                return Val(kind: NumVal, num: level)
            of "print":
                echo exp.tail.map_it(eval(env, it)).join(" ")
                return unit
            of "quote":
                ensure_arg_count(exp, 1)
                return Val(kind: ExpVal, exp: quasiquote(env, exp[1]))
            of "opaque":
                ensure_arg_count(exp, 1)
                let val = eval(env, exp[1])
                if val.kind == FunTypeVal:
                    val.fun_typ.is_opaque = true
                    return val
                elif val.kind == FunVal:
                    val.fun.typ.is_opaque = true
                    return val
                else:
                    return Opaque(val)
            of "unwrap":
                ensure_arg_count(exp, 1)
                var val = eval(env, exp[1])
                if val.kind == HoldVal:
                    val = env.get_opt(val.name).get.val
                case val.kind:
                of OpaqueVal:
                    return val.inner
                of OpaqueFunVal:
                    return val.result
                else:
                    raise error(exp, "{val.str} is not an opaque value. {exp.src}".fmt)
            #of "unsafe-access":
            #    let adr = eval(env, exp[1])
            #    let idx = eval(env, exp[2])
            #    assert adr.kind == MemVal
            #    assert idx.kind == NumVal
            #    let p = cast[int](adr.memory) + idx.num
            #    let v = cast[int](cast[ptr uint8](p)[])
            #    return Val(kind: NumVal, num: v)
            of "as":
                return eval_as(env, exp)
            of "Record":
                return eval_record_type(env, exp)
            of "record":
                return eval_record(env, exp)
            of "compare":
                return eval(env, expand_compare(env, exp))

        if exp.len >= 1:
            let fun = eval(env, exp[0])

            case fun.kind
            of HoldVal:
                # can't evaluate, so normalize arguments and return the term
                let head = v_reify(env, fun)
                let args = exp.tail.map_it(v_norm(env, it))
                return VExp(append(head, args))

            of BuiltinFunVal:
                return apply_builtin(env, fun, exp)

            of FunVal:
                return apply_lambda(env, fun, exp)
            else:
                let fun_typ = v_typeof(env, fun)
                raise error(exp, "{fun} of {fun_typ} is not callable. {exp.src}".fmt)
        
    raise error(exp, "I don't know how to evaluate term {exp.str}. {exp.src}".fmt)

proc define(env: Env, name: string, val: Val) =
    env.vars[name] = Var(val: val, typ: v_typeof(env, val), is_defined: true)

var global_env* = Env(parent: nil)
global_env.define "Type", type0

global_env.define "(_)", Val(kind: BuiltinFunVal, builtin_fun: expand_group, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "group", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
))

global_env.define "[_]", Val(kind: BuiltinFunVal, builtin_fun: expand_square_group, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "group", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
))

global_env.define "()", Val(kind: BuiltinFunVal, builtin_fun: expand_apply, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "func", typ: atom("Expr"), quoted: true),
        FunParam(name: "args", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
))

global_env.define "=>", Val(kind: BuiltinFunVal, builtin_fun: expand_lambda, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "head", typ: atom("Expr"), quoted: true),
        FunParam(name: "body", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
))

global_env.define "->", Val(kind: BuiltinFunVal, builtin_fun: expand_lambda_type, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr"), quoted: true),
        FunParam(name: "result", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Expr"),
    is_macro: true,
))

global_env.define "lambda", Val(kind: BuiltinFunVal, builtin_fun: eval_lambda, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr"), quoted: true),
        FunParam(name: "result", typ: atom("Expr"), quoted: true),
        FunParam(name: "body", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Any"),
))

global_env.define "Lambda", Val(kind: BuiltinFunVal, builtin_fun: eval_lambda_type, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "params", typ: atom("Expr"), quoted: true),
        FunParam(name: "result", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Any"),
))

proc eval_ref(env: Env, args: seq[Val]): Val =
    # ref : (cap: Cap, type: Type, value: type) -> Ptr(cap, type)
    let (cap, typ, val_exp) = (args[0].name, args[1], args[2].exp)
    #echo "CALL ref {cap} {typ} {val}".fmt
    let rd = cap == "rdo" or cap == "imm" or cap == "mut"
    let wr = cap == "wro" or cap == "mut"
    let imm = cap == "imm"
    let mem = eval(env, val_exp)
    let mem_typ = v_typeof(env, mem)
    if not is_subtype(mem_typ, typ):
        raise error(val_exp, "Value {mem} of {mem_typ} is incompatible with type {typ}. {val_exp.src}".fmt)
    return Val(kind: MemVal, mem_ptr: mem, mem_typ: typ, wr: wr, rd: rd, imm: imm)


global_env.define "ref", Val(kind: BuiltinFunVal, builtin_fun: eval_ref, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "cap", typ: atom("Cap")),
        FunParam(name: "type", typ: atom("Type")),
        FunParam(name: "value", typ: atom("Expr"), quoted: true),
    ],
    result: term(atom("Ptr"), atom("cap"), atom("type")),
))

var next_sym = 0
proc eval_gensym(env: Env, args: seq[Val]): Val =
    # ref : (cap: Cap, type: Type, value: type) -> Ptr(cap, type)
    next_sym += 1
    return VExp(atom("__" & $next_sym))

global_env.define "gensym", Val(kind: BuiltinFunVal, builtin_fun: eval_gensym, builtin_typ: FunTyp(
    params: @[],
    result: atom("Atom"),
))

global_env.define "test", Val(kind: BuiltinFunVal, builtin_fun: eval_test, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "name", typ: atom("Atom"), quoted: true),
        FunParam(name: "body", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Atom"),
))

global_env.define "assert", Val(kind: BuiltinFunVal, builtin_fun: eval_assert, builtin_typ: FunTyp(
    params: @[
        FunParam(name: "assertion", typ: atom("Expr"), quoted: true),
    ],
    result: atom("Unit"),
))