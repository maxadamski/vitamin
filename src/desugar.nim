# This file contains functions equivalent to vitamin functions
# for which all parameters are of type Expr and the result is also Expr.
# Keeping these functions in eval.nim introduced too much clutter.
# These functions should only perform context-free Exprs transformations.

# TODO: serious error handling

import sequtils
import common/[exp, utils]


func desugar*(exp: Exp): Exp


func desugar_define*(exp: Exp): Exp =
    let (lhs, rhs) = (exp[1], exp[2])

    if lhs.is_term:
        if lhs.has_prefix("->"):
            # short function definition with return type
            let name = lhs[1][1]
            let params = term(atom("(_)"), lhs[1][2])
            let res_typ = lhs[2]
            let fun_typ = term(atom("->"), params, res_typ)
            let fun = term(atom("=>"), fun_typ, rhs)
            return term(atom("$define"), name, fun.desugar)

        if lhs.has_prefix("()"):
            # short function definition or pattern matching
            let name = lhs[1]
            let params = term(atom("(_)"), lhs[2])
            let fun = term(atom("=>"), params, rhs)
            return term(atom("$define"), name, fun.desugar)

    term(atom("$define"), lhs.desugar, rhs.desugar)


func desugar_assume*(exp: Exp): Exp =
    let (lhs, rhs) = (exp[1], exp[2].desugar)

    if lhs.has_prefix(","):
        var parts: seq[Exp]
        for name in lhs.tail:
            if not name.is_atom: assert false
            parts &= term("$assume".atom, name, rhs)
        return term("$block".atom & parts)

    if not lhs.is_atom: assert false
    term("$assume".atom, lhs, rhs)


func desugar_record_type*(exp: Exp): Exp =
    let exp = exp[2]
    var fields : seq[Exp]

    for group in exp.exprs:
        for list in group.exprs:
            var list_typ : Exp
            var list_idx = 0
            var list_res = new_seq[Exp](list.exprs.len)
            for sub in list.exprs.reverse_iter:
                var sub = sub
                var typ, val: Exp
                var name = sub

                if sub.is_atom:
                    typ = list_typ

                else:
                    if sub.has_prefix("="):
                        name = sub[1]
                        val = sub[2]
                        sub = name

                    if sub.has_prefix(":"):
                        name = sub[1]
                        typ = sub[2]
                        sub = name

                if not name.is_atom: assert false
                typ = typ.desugar
                val = val.desugar

                if list_idx == 0:
                    list_typ = typ

                var parts = @["$field".atom, name]
                if not typ.is_nil: parts &= term(":".atom, typ)
                if not val.is_nil: parts &= term("=".atom, val)
                list_idx += 1
                list_res[^list_idx] = term(parts)

            fields &= list_res

    term("$Record".atom & fields)


func desugar_record*(exp: Exp): Exp =
    # (e1, e2, .., en)

    var fields : seq[Exp]

    for group in exp.exprs:
        #if group.len != 1: raise ctx.error(exp=exp, msg="Tuple elements must be spearated by a comma {group.src}".fmt)

        var arg = group[0]
        #if not arg.has_prefix("="): raise ctx.error(exp=arg, msg="Missing label for record field {arg.src}".fmt)

        var name, typ : Exp
        var val = arg

        if arg.has_prefix("="):
            name = arg[1]
            val = arg[2]
            arg = name

        if arg.has_prefix(":"):
            name = arg[1]
            typ = arg[2]
            val = term("as".atom, val, typ)

        if not name.is_nil and not name.is_atom: assert false

        fields &= term("$arg".atom, name, val.desugar)

    term("$record".atom & fields)


func desugar_group*(exp: Exp): Exp =
    # (a b, d e; f g, h i; j k, l m)
    #  ________  ________  ________  exp[1].exprs
    #  ___  ___  ___  ___  ___  ___  exp[1].exprs.exprs
    #  _ _  _ _  _ _  _ _  _ _  _ _  exp[1].exprs.exprs.exprs

    let exp = exp[1]

    # Anatomy of a group:

    if exp.len == 0:
        # ()
        return term(atom("$record"))
    if exp.len > 1:
        # (e1; e2; ...; en)
        return term(atom("$block") & exp.exprs).desugar

    let lists = exp[0].exprs
    if lists.len == 1 and lists[0].len == 1:
        # (e)
        # FIXME: detect single element tuple with a trailing comma (e,)
        let inner = lists[0][0]
        let is_tuple = inner.is_term(3) and inner[0].is_token("=")
        if not is_tuple:
            return inner.desugar

    return desugar_record(exp[0])


func desugar_apply*(exp: Exp): Exp =
    let (lhs, rhs) = (exp[1], exp[2])
    if lhs.is_atom("Record"): return desugar_record_type(exp)
    var call = @[lhs.desugar]
    let total = rhs
    assert total.len <= 1
    for outer in total.exprs:
        for inner in outer.exprs:
            for exp in inner.exprs:
                call &= exp.desugar
    term(call)


func desugar_lambda_params(exp: Exp): seq[Exp] =
    let total = exp[1]
    for outer_idx, outer in total.exprs:
        let force_keyword = outer_idx == 1
        for inner in outer.exprs:
            var inner_typ: Exp = term()
            var inner_params: seq[Exp]
            for param in inner.exprs.reverse_iter:
                var (name, typ, val) = (term(), term(), term())
                var autoquote = false
                var variadic = false
                var vararg_typ = term()
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

                if typ.is_nil and val.is_nil:
                    typ = atom("_")
                if not name.is_atom:
                    assert false #ctx.error(exp=name, msg="Lambda parameter name must be an Atom, but got Term {name}. {name.src}".fmt)
                typ = desugar(typ)
                val = desugar(val)
                var vararg_container = "Arguments".atom
                while typ.has_prefix_any(["quoted", "variadic"]):
                    case typ.head.value:
                    of "quoted":
                        autoquote = true
                        typ = typ[1]
                    of "variadic":
                        variadic = true
                        if typ.len == 3:
                            vararg_container = typ[1]
                            typ = typ[2]
                        elif typ.len == 2:
                            typ = typ[1]
                        else:
                            assert false

                if variadic:
                    vararg_typ = typ
                    typ = term(vararg_container, typ)

                var parts = @["$param".atom, name]
                if not typ.is_nil: parts &= term(":".atom, typ)
                if not val.is_nil: parts &= term("=".atom, val)
                if variadic: parts &= term("$variadic".atom, vararg_typ)
                if autoquote: parts &= "$quoted".atom
                if force_keyword: parts &= "$keyword".atom

                inner_params.add(term(parts))
            result &= inner_params.reversed


func desugar_lambda_type*(exp: Exp): Exp =
    # <pi-params> -> e
    # <pi-params> -> expand(e)

    var (lhs, rhs) = (exp[1], desugar(exp[2]))
    var parts = @["$Lambda".atom]
    var autoexpand = false

    if lhs.has_prefix("(_)"):
        parts &= desugar_lambda_params(lhs)
    else:
        parts &= term("$param".atom, "_".atom, term(":".atom, lhs))

    if rhs.has_prefix("expand"):
        autoexpand = true
        rhs = rhs[1]

    parts &= term("$result".atom, rhs)

    # TODO: parse effects

    if autoexpand:
        parts &= "$expand".atom

    term(parts)


func desugar_lambda*(exp: Exp): Exp =
    # x => e
    # <pi-params> => e
    # _ -> _ => e

    let (lhs, rhs) = (exp[1], exp[2])
    var parts = @["$lambda".atom]

    if lhs.has_prefix("(_)"):
        parts &= desugar_lambda_params(lhs)

    elif lhs.has_prefix("->"):
        parts &= desugar_lambda_type(lhs).tail

    else:
        assert false

    parts &= term("$body".atom, rhs.desugar)

    term(parts)


func desugar_compare*(exp: Exp): Exp =
    if exp.len > 4: assert false
    term(exp[2].desugar, exp[1].desugar, exp[3].desugar)


func desugar*(exp: Exp): Exp =
    if exp.len < 1 or exp.head.is_term: return exp
    let arg = exp.tail
    case exp.head.value:
    of "compare": desugar_compare(exp)
    of "Record": desugar_record_type(exp)
    of ":": desugar_assume(exp)
    of "=": desugar_define(exp)
    of "(_)": desugar_group(exp)
    of "()": desugar_apply(exp)
    of "=>": desugar_lambda(exp)
    of "->": desugar_lambda_type(exp)
    of "@": term(arg[0].desugar & arg[1].exprs.map(desugar) & arg[2].desugar)
    else: term(exp.exprs.map(desugar))
