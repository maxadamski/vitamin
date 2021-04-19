import types, error
import tables, options, sequtils, strutils, strformat, algorithm

var global_fun_id: uint32 = 1000

func v_num(num: int): Val = Val(kind: NumVal, num: num)
func v_hold(name: string): Val = Val(kind: HoldVal, name: name)
func v_opaque(inner: Val): Val = Val(kind: OpaqueVal, inner: inner)
func v_universe(level: int): Val = Val(kind: TypeVal, level: 0)
func v_union_type(types: varargs[Val]): Val = Val(kind: UnionTypeVal, types: @types)
func v_inter_type(types: varargs[Val]): Val = Val(kind: InterTypeVal, types: @types)
func v_record(fields: varargs[RecField]): Val = Val(kind: RecVal, fields: @fields)
func v_record_type(slots: varargs[RecSlot]): Val = Val(kind: RecTypeVal, slots: @slots)

func lambda_type(params: varargs[FunParam], ret: Exp): FunTyp = FunTyp(params: @params, ret_typ: ret)

func v_lambda_type(typ: FunTyp): Val = Val(kind: FunTypeVal, fun_typ: typ)

func v_lambda_type(params: varargs[FunParam], ret: Exp): Val = v_lambda_type(lambda_type(params, ret))

proc v_lambda(typ: FunTyp, body: Exp, env: Env): Val =
    global_fun_id += 1
    Val(kind: FunVal, fun: Fun(id: global_fun_id, typ: typ, body: body, env: env))

let type0* = v_universe(1)
let type1* = v_universe(2)
let unit* = v_record()
let v_true = v_num(1)
let v_false = v_num(0)
let v_any = v_union_type()
let v_never = v_inter_type()
proc v_bool(x: bool): Val = (if x: v_true else: v_false)
let unit_type* = v_record_type()
let exp_type* = Val(kind: ExpTypeVal)

proc expand_lambda_params(exp: Exp): seq[FunParam] =
    var params: seq[FunParam]
    if exp[0].is_token("()"):
        for x in exp.exprs[1 .. ^1]:
            var param = FunParam()
            var name_type = x
            if x[0].is_token("="):
                name_type = x[1]
                param.default = some(x[2])
            param.name = x[1].value
            param.typ = x[2]
            params.add(param)
    return params

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

proc equal(x, y: Val): bool =
    if x.kind != y.kind: return false
    case x.kind
    of TypeVal: x.level == y.level
    of OpaqueVal: x == y
    of FunVal: x.fun.id == y.fun.id
    of OpaqueFunVal: x.opaque_fun.id == y.opaque_fun.id and x.bindings == y.bindings
    of HoldVal: x.name == y.name
    of RecTypeVal:
        if x.slots.len != y.slots.len: return false
        let n = x.slots.len
        let sx = x.slots.sorted_by_it(it.name)
        let sy = y.slots.sorted_by_it(it.name)
        for i in 0..<n:
            if sx[i].name != sy[i].name or not equal(sx[i].typ, sy[i].typ): return false
        return true
    else: x == y

proc is_subtype(x, y: Val): bool =
    # is x a subtype of y
    if equal(x, y): return true
    if y.kind == UnionTypeVal and y.types.len == 0: return true
    if y.kind == InterTypeVal and y.types.len == 0: return false
    return false

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
    of CastVal:
        val.typ
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
    of OpaqueVal:
        return v_type(env, val.inner)
    of OpaqueFunVal:
        return v_type(env, val.result)
    of HoldVal:
        let res = env.get_opt(val.name)
        if res.is_none:
            raise error("`{val.name}` is not assumed. This shouldn't happen!".fmt)
        res.get.typ
    else:
        raise error("`type-of` not implemented for argument {val.str}.".fmt)

proc infer*(env: Env, exp: Exp): Val =
    unit

proc eval*(env: Env, exp: Exp, as_type: Option[Val], unwrap: bool = false): Val

proc eval*(env: Env, exp: Exp, as_type: Val, unwrap = false): Val =
    eval(env, exp, some(as_type), unwrap)

proc eval*(env: Env, exp: Exp, unwrap = false): Val =
    eval(env, exp, none(Val), unwrap)

proc eval*(env: Env, exp: Exp, as_type: Option[Val], unwrap: bool = false): Val =
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
            let val = res.get.val
            if not unwrap and val.kind == OpaqueVal:
                return v_hold(name)
            return val

        of aNum:
            let val = Val(kind: NumVal, num: parse_int(exp.value))
            # TODO: check if can cast
            if as_type.is_some:
                return Val(kind: CastVal, val: val, typ: as_type.get)
            return val
        
        else:
            raise error(exp, "I don't know how to evaluate term {exp.str}. {exp.src}".fmt)

    of expTerm:
        if exp.len >= 1 and exp[0].kind == expAtom:
            case exp[0].value
            of ":":
                assert exp.len == 3
                assert exp[1].kind == expAtom
                let name = exp[1].value
                let val = v_hold(name)
                let typ = eval(env, exp[2], as_type=type0)
                env.vars[name] = Var(val: val, typ: typ, is_defined: true)
                return unit
            
            of "=":
                assert exp.len == 3
                assert exp[1].kind == expAtom
                let name = exp[1].value
                var val = eval(env, exp[2])
                var typ: Val
                if val.kind == CastVal:
                    typ = val.typ
                else:
                    typ = v_type(env, val)
                env.vars[name] = Var(val: val, typ: typ, is_defined: true)
                return unit
            
            of "apply":
                return eval(env, term(exp.exprs[1 .. ^1]), as_type)

            of "Union", "Inter":
                let args = exp.exprs[1 .. ^1].map_it(eval(env, it))
                if exp[0].value == "Union":
                    return v_union_type(args)
                if exp[0].value == "Inter":
                    return v_inter_type(args)

            of "type-of":
                assert exp.len == 2
                if exp[1].kind == expAtom and exp[1].tag in {aSym, aLit}:
                    let name = exp[1].value
                    let res = env.get_opt(name)
                    if res.is_none:
                        raise error(exp, "I don't know the type of `{name}` since it isn't defined or assumed. {exp.src}".fmt)
                    return res.get.typ
                return v_type(env, eval(env, exp[1]))

            of "print":
                echo exp.exprs[1 .. ^1].map_it(eval(env, it)).join(" ")
                return unit

            of "assert":
                if exp[1].len == 3 and exp[1][0].kind == expAtom:
                    let op = exp[1][0].value
                    let (lhs, rhs) = (exp[1][1], exp[1][2])
                    let (actual, expected) = (eval(env, lhs), eval(env, rhs))
                    if op == "==":
                        if not equal(actual, expected):
                            let header = exp.err_header("assert error")
                            echo "{header}\nexpected `{lhs.str}`\nto equal `{rhs.str}`\n     but `{actual.str}` != `{expected.str}` {exp.src}\n".fmt
                    elif op == "!=":
                        if equal(actual, expected):
                            let header = exp.err_header("assert error")
                            echo "{header}\n    expected `{lhs.str}`\nto not equal `{rhs.str}`\n         but `{actual.str}` == `{expected.str}` {exp.src}\n".fmt
                    else:
                        echo "error: assert doesn't support binary operator {op} {exp.src}".fmt
                else:
                    echo "error: assert doesn't support expressions like {exp.str} {exp.src}".fmt

                return unit

            of "opaque":
                assert exp.len == 2
                let val = eval(env, exp[1])
                if val.kind == FunTypeVal:
                    val.fun_typ.is_opaque = true
                    return val
                elif val.kind == FunVal:
                    val.fun.typ.is_opaque = true
                    return val
                else:
                    return v_opaque(val)

            of "unwrap":
                assert exp.len == 2
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

            of "as":
                assert exp.len == 3
                let dst_typ = eval(env, exp[2])
                # eval rhs and cast literal
                let val = eval(env, exp[1], as_type=dst_typ)
                let src_typ = v_type(env, val)

                # try to unwrap previous casts
                var dst_val = val
                while dst_val.kind == CastVal:
                    if equal(dst_val.typ, dst_typ):
                        return dst_val
                    dst_val = dst_val.val

                # check if can cast to subtype
                if src_typ.is_subtype(dst_typ):
                    return Val(kind: CastVal, val: val, typ: dst_typ)

                raise error(exp, "You can't cast `{val.str}` of `{src_typ.str}` to type `{dst_typ.str}`.\n\nCan't downcast, because type `{src_typ.str}` is not a subtype of `{dst_typ.str}`.\n\nCan't upcast, because there is no evidence, that `{val.str}` was downcast from type `{dst_typ.str}`. {exp.src}".fmt)

            of "Record":
                # Record : (fields: [Expr]) -> Record-Universe(fields)
                var slots: seq[RecSlot]
                for x in exp.exprs[1 .. ^1]:
                    var slot: RecSlot
                    var name_typ = x
                    if x[0].is_token("="):
                        name_typ = x[1]
                        slot.default = some(x[2])
                    if not name_typ[0].is_token(":"):
                        raise error(exp, "Expected a pair `name : type`, but got {name_typ.str}. {name_typ.src}".fmt)
                    if name_typ[1].kind != expAtom:
                        raise error(exp, "Field name must be an atom, but got {name_typ[1].str}. {name_typ[1].src}".fmt)
                    slot.name = name_typ[1].value
                    slot.typ = eval(env, name_typ[2])
                    slots.add(slot)
                return v_record_type(slots)

            of "()":
                if exp.len == 1:
                    return unit
                if exp.len == 2 and not (exp[1].kind == expTerm and exp[1].len == 3 and exp[1][0].is_token("=")):
                    return eval(env, exp[1])

                var fields: seq[RecField]
                for x in exp.exprs[1 .. ^1]:
                    if x[0].is_token("="):
                        let name = x[1].value
                        let val = eval(env, x[2])
                        fields.add(RecField(name: name, val: val))

                return v_record(fields)

            of "macro":
                var val = eval(env, exp[1])
                if val.kind == FunTypeVal:
                    val.fun_typ.is_macro = true
                if val.kind == FunVal:
                    val.fun.typ.is_macro = true
                return val

            of "pure":
                var val = eval(env, exp[1])
                if val.kind == FunTypeVal:
                    val.fun_typ.is_pure = true
                if val.kind == FunVal:
                    val.fun.typ.is_pure = true
                return val

            of "->":
                return v_lambda_type(expand_lambda_type(exp))

            of "=>":
                # `=>` : macro (params: [Expr], body: Exp) -> Fun-Type(params)
                let (head, body) = (exp[1], exp[2])
                let is_closure = false
                let local = if is_closure: env else: nil
                if head[0].is_token("( _ )"):
                    let params = expand_lambda_params(head)
                    # TODO: assume parameters
                    # TODO: infer type of body
                    let ret = term()
                    let typ = lambda_type(params, ret)
                    return v_lambda(typ, body, local)

                elif head[0].is_token("->"):
                    let typ = expand_lambda_type(head)
                    return v_lambda(typ, body, local)

                else:
                    raise error(exp, "Bad lambda term {exp.str}. {exp.src}".fmt)

        if exp.len > 1:
            let callee = eval(env, exp[0])
            case callee.kind
            of BuiltinFunVal:
                let args = exp.exprs[1 .. ^1].map_it(eval(env, it))
                return callee.builtin_fun(args)
            of FunVal:
                let fun_typ = callee.fun.typ
                var local = env.extend()
                let args = exp.exprs[1 .. ^1]
                var bindings: seq[(string, Val)]
                for i in 0..<fun_typ.params.len:
                    let par = fun_typ.params[i]
                    let arg = args[i]
                    let typ = eval(local, par.typ)
                    let val = eval(local, arg, as_type=typ)
                    local.vars[par.name] = Var(val: val, typ: typ, is_defined: true)
                    bindings.add((par.name, val))
                let ret_typ = eval(local, fun_typ.ret_typ)
                var res = eval(local, callee.fun.body, as_type=ret_typ)
                if fun_typ.is_opaque:
                    var name = ""
                    if exp[0].kind == expAtom:
                        name = exp[0].value
                    res = Val(kind: OpaqueFunVal, disp_name: name, result: res, bindings: bindings, opaque_fun: callee.fun)
                return res
            else:
                raise error(exp, "{callee.str} is not callable. {exp.src}".fmt)
        
    raise error(exp, "I don't know how to evaluate term {exp.str}. {exp.src}".fmt)

var global_env* = Env(parent: nil)
global_env.vars["Type"] = Var(val: type0, typ: type1, is_defined: true)
