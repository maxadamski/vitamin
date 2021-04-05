import types, error
import sets, tables, options, sequtils, strutils, strformat

func v_num(num: int): Val = Val(kind: NumVal, num: num)
func v_hold(name: string): Val = Val(kind: HoldVal, name: name)
func v_universe(level: int): Val = Val(kind: TypeVal, level: 0)
func v_union_type(types: varargs[Val]): Val = Val(kind: UnionTypeVal, types: @types)
func v_inter_type(types: varargs[Val]): Val = Val(kind: InterTypeVal, types: @types)
func v_record(fields: varargs[RecField]): Val = Val(kind: RecVal, fields: @fields)
func v_record_type(slots: varargs[RecSlot]): Val = Val(kind: RecTypeVal, slots: @slots)

func lambda_type(params: varargs[FunParam], ret: Exp): FunTyp = FunTyp(params: @params, ret_typ: ret)
func v_lambda(typ: FunTyp, body: Exp, env: Env): Val = Val(kind: FunVal, fun: Fun(typ: typ, body: body, env: env))
func v_lambda_type(typ: FunTyp): Val = Val(kind: FunTypeVal, fun_typ: typ)
func v_lambda_type(params: varargs[FunParam], ret: Exp): Val = v_lambda_type(lambda_type(params, ret))

let type0* = v_universe(1)
let type1* = v_universe(2)
let unit* = v_record()
let v_true = v_num(1)
let v_false = v_num(0)
proc v_bool(x: bool): Val = (if x: v_true else: v_false)
let unit_type* = v_record_type()
let exp_type* = Val(kind: ExpTypeVal)

proc expand_lambda_params(exp: Exp): seq[FunParam] =
    var params: seq[FunParam]
    if exp[0].is_token("group"):
        for x in exp.exprs[1 .. ^1]:
            var param = FunParam()
            var name_type = x
            if x[0].is_token("="):
                name_type = x[1]
                param.default = some(x[2])
            param.name = x[1].value
            param.typ = x[2]
            params.add(param)

proc expand_lambda_type(exp: Exp): FunTyp =
    let params = expand_lambda_params(exp[1])
    let ret_type = exp[2]
    lambda_type(params, ret_type)

proc src(exp: Exp): string =
    let source = exp.in_source
    if source == "<not found>": "" else: "\n\n" & source

proc get_opt*(env: Env, name: string): Option[Var] =
    if name in env.vars:
        some(env.vars[name])
    elif env.parent != nil:
        env.parent.get_opt(name)
    else:
        none(Var)

proc max_or(x: seq[int], default=0): int =
    if x.len == 0: default else: max(x)

proc v_equal(x, y: Val): Val =
    if x.kind != y.kind: return v_false
    let res = case x.kind
    of TypeVal: x.level == y.level
    of UniqueVal: x == y
    of HoldVal: x.name == y.name
    else: x == y
    v_bool(res)

proc v_not_equal(x, y: Val): Val =
    let res = v_equal(x, y)
    if res == v_true: v_false else: v_true

proc v_type*(env: Env, val: Val, as_type: Option[Val]): Val

proc v_type*(env: Env, val: Val, as_type: Val): Val =
    `v_type`(env, val, some(as_type))

proc v_type*(env: Env, val: Val): Val =
    `v_type`(env, val, none(Val))

proc universe*(env: Env, val: Val): int =
    case val.kind
    of TypeVal: val.level + 1
    of HoldVal: universe(env, v_type(env, val))
    of UnionTypeVal, InterTypeVal: max_or(val.types.map_it(universe(env, it)), default=1)
    of RecTypeVal: max_or(val.slots.map_it(universe(env, it.typ)), default=1)
    #of FunTypeVal: max(max_or(val.fun_typ.params.map_it(universe(env, it.typ)), default=0), universe(env, val.fun_typ.ret_typ))
    of ExpTypeVal: 0
    else: 0

proc v_type*(env: Env, val: Val, as_type: Option[Val]): Val =
    case val.kind
    of TypeVal, RecTypeVal, FunTypeVal, UnionTypeVal, InterTypeVal, ExpTypeVal:
        v_universe(universe(env, val))
    of RecVal:
        v_record_type(val.fields.map_it(RecSlot(name: it.name, typ: v_type(env, it.val))))
    of FunVal:
        v_lambda_type(val.fun.typ)
    #of FunVal:
    #    v_lambda_type()
    of NumVal:
        env.get_opt("I64").get.val
    of ExpVal:
        exp_type
    of UniqueVal:
        return v_type(env, val.inner_value)
    of HoldVal:
        let res = env.get_opt(val.name)
        if res.is_none:
            raise error("{val.name} is not declared.".fmt)
        res.get.typ
    else:
        raise error("`type-of` not implemented for argument {val}.".fmt)

proc eval*(env: Env, exp: Exp, as_type: Option[Val]): (Val, Val)

proc eval*(env: Env, exp: Exp, as_type: Val): (Val, Val) =
    eval(env, exp, some(as_type))

proc eval*(env: Env, exp: Exp): (Val, Val) =
    eval(env, exp, none(Val))

proc with_type*(env: Env, val: Val): (Val, Val) =
    (val, v_type(env, val))

proc eval*(env: Env, exp: Exp, as_type: Option[Val]): (Val, Val) =
    case exp.kind
    of expAtom:
        case exp.tag
        of aSym, aLit:
            let name = exp.value
            let res = env.get_opt(name)
            if res.is_none:
                raise error(exp, "{name} is not defined. {exp.src}".fmt)
            if not res.get.is_defined:
                raise error(exp, "{name} is declared, but not defined. {exp.src}".fmt)
            return (res.get.val, res.get.typ)

        of aNum:
            let val = Val(kind: NumVal, num: parse_int(exp.value))
            let typ = if as_type.is_none: v_type(env, val) else: as_type.get
            return (val, typ)
        
        else:
            raise error(exp, "I don't know how to evaluate term {exp}. {exp.src}".fmt)

    of expTerm:
        if exp.len >= 1 and exp[0].kind == expAtom:
            case exp[0].value
            of ":":
                assert exp.len == 3
                assert exp[1].kind == expAtom
                let name = exp[1].value
                let val = v_hold(name)
                let typ = eval(env, exp[2], as_type=type0)[0]
                env.vars[name] = Var(val: val, typ: typ, is_defined: true)
                return (unit, unit_type)
            
            of "=":
                assert exp.len == 3
                assert exp[1].kind == expAtom
                let name = exp[1].value
                let val = eval(env, exp[2], as_type=type0)[0]
                let typ = v_type(env, val)
                env.vars[name] = Var(val: val, typ: typ, is_defined: true)
                return (unit, unit_type)
            
            of "call":
                return eval(env, term(exp.exprs[1 .. ^1]), as_type)

            of "Union", "Inter":
                let args = exp.exprs[1 .. ^1].map_it(eval(env, it)[0])
                if exp[0].value == "Union":
                    return with_type(env, v_union_type(args))
                if exp[0].value == "Inter":
                    return with_type(env, v_inter_type(args))

            of "Record":
                # Record : (fields: [Expr]) -> Record-Universe(fields)
                var slots: seq[RecSlot]
                return with_type(env, v_record_type(slots))

            of "type-of":
                assert exp.len == 2
                let (val, typ) = eval(env, exp[1])
                return (typ, v_type(env, typ))

            of "assert":
                let res = eval(env, exp[1])[0]
                if res == v_false:
                    if exp[1][0].is_token("=="):
                        let actual = eval(env, exp[1][1])[0]
                        let expected = eval(env, exp[1][2])[0]
                        echo "fail: expected {exp[1][1]} to equal {exp[1][2]}, but {actual} != {expected}".fmt

                return (unit, unit_type)

            of "as":
                echo exp

            of "group":
                if exp.len == 1:
                    return (unit, unit_type)

                var fields: seq[RecField]
                for x in exp.exprs[1 .. ^1]:
                    if x[0].is_token("="):
                        let name = x[1].value
                        let (val, typ) = eval(env, x[2])
                        fields.add(RecField(name: name, val: val))

                let val = v_record(fields)
                return (val, v_type(env, val))

            of "==":
                let lhs = eval(env, exp[1])[0]
                let rhs = eval(env, exp[2])[0]
                return with_type(env, v_equal(lhs, rhs))

            of "!=":
                let lhs = eval(env, exp[1])[0]
                let rhs = eval(env, exp[2])[0]
                return with_type(env, v_not_equal(lhs, rhs))

            of "newtype":
                assert exp.len == 2
                let (val, typ) = eval(env, exp[1])
                if val.kind == FunTypeVal:
                    val.fun_typ.is_unique = true
                    return (val, typ)
                elif val.kind == FunVal:
                    val.fun.typ.is_unique = true
                    return (val, typ)
                else:
                    return with_type(env, Val(kind: UniqueVal, inner_value: val))

            of "macro":
                var (val, typ) = eval(env, exp[1])
                if val.kind == FunTypeVal:
                    val.fun_typ.is_macro = true
                if val.kind == FunVal:
                    val.fun.typ.is_macro = true
                return (val, typ)

            of "->":
                let res = v_lambda_type(expand_lambda_type(exp))
                return (res, v_type(env, res))

            of "=>":
                # `=>` : macro (params: [Expr], body: Exp) -> Fun-Type(params)
                let (head, body) = (exp[1], exp[2])
                let is_closure = false
                let local = if is_closure: env else: nil
                if head[0].is_token("group"):
                    let params = expand_lambda_params(head)
                    # TODO: infer ret
                    let ret = term()
                    let typ = lambda_type(params, ret)
                    return (v_lambda(typ, body, local), v_lambda_type(typ))

                elif head[0].is_token("->"):
                    let typ = expand_lambda_type(head)
                    return (v_lambda(typ, body, local), v_lambda_type(typ))

                else:
                    raise error(exp, "Bad lambda term {exp}. {exp.src}".fmt)

        if exp.len > 1:
            let callee = eval(env, exp[0])[0]
            let args = exp.exprs[1 .. ^1].map_it(eval(env, it)[0])
            case callee.kind
            of BuiltinFunVal:
                return with_type(env, callee.builtin_fun(args))
            of FunVal:
                raise error(exp, "Call not implemented. {exp.src}".fmt)
            else:
                raise error(exp, "{callee} is not callable. {exp.src}".fmt)
        
    raise error(exp, "I don't know how to evaluate term {exp}. {exp.src}".fmt)

var global_env* = Env(parent: nil)
global_env.vars["Type"] = Var(val: type0, typ: type1, is_defined: true)
#global_env.vars["Unit"] = Var(val: unit, typ: type0, is_defined: true)
