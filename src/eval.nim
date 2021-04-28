import options, tables, sequtils, strformat, strutils
import common/[vm, exp, error]
from common/utils import reverse_iter, max_or

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

let type0* = Universe(1)
let type1* = Universe(2)
let unit* = Record()

proc is_univ(val: Val): bool = val.kind == TypeVal

proc is_type(env: Env, val: Val): bool =
    v_typeof(env, val).is_univ 

proc infer_pure(env: Env, exp: Exp): bool =
    # TODO: implement me correctly!!!
    false

proc ensure_args_are_types(env: Env, args: seq[Exp]) =
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
        ret_exp = v_norm(env, ret_exp)
        if ret_exp.has_prefix("Eval"):
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
                result.add(term(name, typ, val))

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
    let src_typ = v_typeof(env, val)
    # check if can cast to subtype
    if is_subtype(src_typ, dst_typ):
        return Val(kind: CastVal, val: val, typ: dst_typ)

    # try to unwrap previous casts
    var dst_val = val
    while dst_val.kind == CastVal:
        if is_subtype(dst_val.typ, dst_typ):
            return dst_val
        dst_val = dst_val.val

    let src_typ2 = v_typeof(env, dst_val)
    # check if can cast to subtype
    if is_subtype(src_typ2, dst_typ):
        return dst_val

    raise error(exp, "You can't cast `{val.str}` of `{src_typ.str}` to type `{dst_typ.str}`.\n\nCan't downcast, because type `{src_typ.str}` is not a subtype of `{dst_typ.str}`.\n\nCan't upcast, because there is no evidence, that `{val.str}` was downcast from type `{dst_typ.str}`. {exp.src}".fmt)
    
proc eval_as(env: Env, exp: Exp): Val =
    ensure_arg_count(exp, 2)

    let dst_typ = eval(env, exp[2])
    if not is_type(env, dst_typ):
        raise error(exp[2], "Second argument of `as` must be of Type, but got value {dst_typ}. {exp[2].src}".fmt)
    # eval rhs and cast literal
    let val = eval(env, exp[1], as_type=dst_typ)
    return v_cast(env, val, dst_typ, exp=exp)

proc eval_assert(env: Env, exp: Exp): Val =
    ensure_arg_count(exp, 1)
    var cond = exp
    if exp[1].is_term and exp[1][0].is_token("compare"):
        cond = expand_compare(env, exp[1])

    if cond.len == 3 and cond[0].kind == expAtom:
        let op = cond[0].value
        let (lhs, rhs) = (cond[1], cond[2])
        let (actual, expected) = (eval(env, lhs), eval(env, rhs))
        case op
        of "==":
            if not equal(actual, expected):
                let header = exp.err_header("assert error")
                echo "{header}\nexpected `{lhs.str}`\nto equal `{rhs.str}`\n     but `{actual.str}` != `{expected.str}` {exp.src}\n".fmt
        of "!=":
            if equal(actual, expected):
                let header = exp.err_header("assert error")
                echo "{header}\n    expected `{lhs.str}`\nto not equal `{rhs.str}`\n         but `{actual.str}` == `{expected.str}` {exp.src}\n".fmt
        else:
            echo "error: assert doesn't support binary operator {op} {exp.src}".fmt
    else:
        echo "error: assert doesn't support expressions like {exp.str} {exp.src}".fmt

    return unit

#region [Purple] Quasiquotes

proc unquote(env: Env, x: Exp): Exp =
    let res = eval(env, x[1])
    if res.kind != ExpVal:
        raise error(x, fmt"You can only unquote expressions, but you tried to unquote a value of type {v_typeof(env, res)}. {x.src}")
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
    of UnionTypeVal, InterTypeVal: max_or(val.values.map_it(v_levelof(env, it)), default=1)
    of RecTypeVal: max_or(val.slots.map_it(v_levelof(env, it.typ)), default=1)
    of SetTypeVal: 1
    #of FunTypeVal: max(max_or(val.fun_typ.params.map_it(v_levelof(env, it.typ)), default=0), v_levelof(env, val.fun_typ.ret_typ))
    else: raise error("`level-of` expected an argument of Type, but got {v_typeof(env, val)}.")

proc v_typeof*(env: Env, val: Val, as_type: Option[Val]): Val =
    case val.kind
    of TypeVal, RecTypeVal, FunTypeVal, SetTypeVal, UnionTypeVal, InterTypeVal,
        SymbolTypeVal:
        Universe(v_levelof(env, val))
    of CastVal:
        val.typ
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

proc v_norm*(env: Env, exp: Exp): Exp =
    v_reify(env, eval(env, exp))

proc v_reify*(env: Env, val: Val): Exp =
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
    of RecTypeVal:
        term(atom("Record"))
    else:
        raise error("Can't reify value {val.str} of kind {val.kind}.".fmt)

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

proc v_union*(env: Env, args: seq[Val]): Val =
    var set = Val(kind: SetTypeVal)
    var types: seq[Val]
    for arg in args:
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

proc apply_builtin(env: Env, fun: Val, exp: Exp, eval_macro_res = true): Val =
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
    if typ.is_macro and eval_macro_res:
        assert res.kind == ExpVal
        return eval(env, res.exp)
    else:
        return res

proc v_expand*(env: Env, exp: Exp): Exp =
    if exp.len >= 1:
        if exp[0].kind == expAtom and env.get_opt(exp[0].value).is_none:
            return exp
        let fun = eval(env, exp[0])
        case fun.kind
        of BuiltinFunVal:
            if fun.builtin_typ.is_macro:
                let res = apply_builtin(env, fun, exp, eval_macro_res=false)
                assert res.kind == ExpVal
                return v_expand(env, res.exp)
        else:
            discard
    exp

proc v_infer*(env: Env, exp: Exp): Val =
    # TODO: implement me correctly!!!
    #echo "infer " & exp.str
    let exp = v_expand(env, exp)
    case exp.kind:
    of expAtom:
        return v_typeof(env, eval(env, exp))
    of expTerm:
        if exp.len >= 1 and exp[0].kind == expAtom:
            case exp[0].value:
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
                #if not exp[4].is_nil:
                #    types.add(v_infer(env, exp[4]))
                return v_union(env, types)
            of "for":
                return unit
            of "block":
                var typ = RecordType()
                for stat in exp.tail:
                    typ = v_infer(env, stat)
                return typ
            of "|", "&", "Set", "Record", "Lambda":
                return type0
            of "compare":
                return eval(env, atom("Bool"))
            of "list":
                return eval(env, atom("List"))
            of "Symbol":
                return Val(kind: SymbolTypeVal, name: exp[1].value)
            else:
                discard

        if exp.len >= 1:
            let fun = eval(env, exp[0])
            case fun.kind
            of BuiltinFunVal:
                let typ = fun.builtin_typ
                return eval(env, typ.result)
            of FunVal:
                let typ = fun.fun.typ
                return eval(env, typ.result)
            of HoldVal:
                let typ = v_typeof(env, fun)
                assert typ.kind == FunTypeVal
                return eval(env, typ.fun_typ.result)
            else:
                raise error(exp, "Can't call {fun}. {exp.src}".fmt)

    raise error(exp, "`infer` not implemented for expression {exp}. {exp.src}".fmt)

proc eval*(env: Env, exp: Exp, as_type: Option[Val], unwrap = false): Val =
    #echo "eval " & exp.str_ugly
    case exp.kind
    of expAtom:
        case exp.tag
        of aSym, aLit:
            let name = exp.value
            let res = env.get_opt(name)
            if res.is_none:
                #return Hold(name)
                raise error(exp, "{name} is not defined. {exp.src}".fmt)
            if not res.get.is_defined:
                #return Hold(name)
                raise error(exp, "{name} is declared, but not defined. {exp.src}".fmt)
            let val = res.get.val
            if not unwrap and val.kind == OpaqueVal:
                return Hold(name)
            return val

        of aNum:
            let val = Val(kind: NumVal, num: parse_int(exp.value))
            # TODO: check if can cast
            if as_type.is_some:
                return Val(kind: CastVal, val: val, typ: as_type.get)
            return val

        of aStr:
            let str = exp.value
            let len = str.len
            let p = alloc(len * sizeof(uint8))
            copy_mem(p, cast[pointer](str.cstring), len)
            let val = Val(kind: MemVal, memory: p, mutable: false)
            return Val(kind: CastVal, val: val, typ: Hold("Str"))
        
        else:
            raise error(exp, "I don't know how to evaluate term {exp.str}. {exp.src}".fmt)

    of expTerm:
        if exp.len == 0:
            return unit

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
                var val = eval(env, exp[2])
                var typ: Val
                if val.kind == CastVal:
                    typ = val.typ
                else:
                    typ = v_typeof(env, val)
                env.vars[name] = Var(val: val, typ: typ, is_defined: true, definition: some(exp))
                return unit
            of "Symbol":
                ensure_arg_count(exp, 1)
                if exp[1].kind != expAtom:
                    raise error(exp[1], "Symbol expected an Atom as it's sole argument, but was given Term {exp[1]}. {exp[1].src}".fmt)
                return Val(kind: SymbolVal, name: exp[1].value)
            of "Set":
                ensure_args_are_not_types(env, exp.tail)
                return Val(kind: SetTypeVal, values: exp.tail.map_it(eval(env, it)))
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
                return InterType(exp.tail.map_it(eval(env, it)))
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
            of "assert":
                return eval_assert(env, exp)
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
            of "unsafe-access":
                let adr = eval(env, exp[1])
                let idx = eval(env, exp[2])
                assert adr.kind == MemVal
                assert idx.kind == NumVal
                let p = cast[int](adr.memory) + idx.num
                let v = cast[int](cast[ptr uint8](p)[])
                return Val(kind: NumVal, num: v)
            of "as":
                return eval_as(env, exp)
            of "Record":
                return eval_record_type(env, exp)
            of "record":
                return eval_record(env, exp)
            of "compare":
                return VExp(expand_compare(env, exp))
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
                let fun_typ = fun.fun.typ
                var local = env.extend()
                let args = exp.tail
                var bindings: seq[(string, Val)]
                for i in 0..<fun_typ.params.len:
                    let par = fun_typ.params[i]
                    let arg = args[i]
                    let typ = eval(local, par.typ)
                    let val = eval(local, arg, as_type=typ)
                    local.vars[par.name] = Var(val: val, typ: typ, is_defined: true)
                    bindings.add((par.name, val))
                let ret_typ = eval(local, fun_typ.result)
                var res = eval(local, fun.fun.body, as_type=ret_typ)
                if fun_typ.is_opaque:
                    var name = ""
                    if exp[0].kind == expAtom:
                        name = exp[0].value
                    res = Val(kind: OpaqueFunVal, disp_name: name, result: res, bindings: bindings, opaque_fun: fun.fun)
                if fun_typ.is_macro:
                    assert res.kind == ExpVal
                    return eval(env, res.exp)
                return res
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