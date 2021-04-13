import types, error, syntax_rule, exp_stream
import sets, tables, options, strformat

const debug_parser = 0

type
    SyntaxGroup* = ref object
        name: string
        stronger_than*: seq[SyntaxGroup]
    
    Parselet* = object
        group*: string
        function*: string
        rule*: SyntaxRule

    Parser* = ref object
        parent*: Parser
        tighter_than*: Table[string, HashSet[string]]
        infix_rules*: Table[string, Parselet]
        prefix_rules*: Table[string, Parselet]

    ParseError* = ref object
        parent*: ParseError
        rule*: SyntaxRule
        partial*: Option[Exp]
        reason*: string

func parse_error(x: ParseError): Result[ParseError, Option[Exp]] =
    error[ParseError, Option[Exp]](x)

func parse_error(rule: SyntaxRule, partial: Option[Exp] = none(Exp), parent: ParseError = nil, reason: string = ""): auto =
    parse_error(ParseError(rule: rule, partial: partial, parent: parent, reason: reason))

func parse_error(rule: SyntaxRule, partial: Exp, parent: ParseError = nil, reason: string = ""): auto =
    parse_error(rule, some(partial), parent, reason)

func parse_ok(x: Option[Exp] = none(Exp)): auto =
    ok[ParseError, Option[Exp]](x)

func parse_ok(x: Exp): auto =
    ok[ParseError, Option[Exp]](some(x))

proc raise_parse_error(error: ParseError, token: Option[Exp]) =
    var text = ""
    var trace = error
    var node = error.partial.get
    while trace != nil:
        text &= "while parsing " & $trace.rule
        if trace.partial.is_some:
            text &= "\n  found: " & $trace.partial.get
            node = concat(node, trace.partial.get)
        if trace.reason != "":
            text &= "\n  error: " & $trace.reason
        trace = trace.parent
        if trace != nil:
            text &= "\n"
    let rule = error.rule
    let found = if token.is_some: ", but found `{token.get.str}`".fmt else: ""
    let source = node.in_source
    let source_text = if source == "": "" else: "\n\n" & source
    raise verror(1006, node, "Parser rule {rule.str} failed.{source_text}\n\nExpected one of the following tokens: {rule.follow}{found}\n\nParse trace:\n\n{text}".fmt)

proc parse_expr(p: var Parser, tokens: var ExpStream, until: HashSet[string] = init_hash_set[string](), rule: Option[SyntaxRule] = none(SyntaxRule)): Result[ParseError, Option[Exp]]

proc parse_rule(p: var Parser, tokens: var ExpStream, rule: SyntaxRule, follow: HashSet[string]): Result[ParseError, Option[Exp]] =
    when debug_parser > 0: echo fmt"parse_rule: try rule {rule} (head: `{tokens.peek_opt}`, follow: {follow})"
    case rule.kind:
    of NilRule:
        parse_ok()

    of ExpRule:
        parse_expr(p, tokens, follow + rule.follow, some(rule))

    of TokRule:
        if rule.value == "":
            if tokens.eos:
                return parse_error(rule, term(), reason="expected any token, but got EOS")
            return parse_ok(tokens.next(ind=rule.raw))

        if not tokens.expect(rule.value, raw=rule.raw):
            return parse_error(rule, tokens.peek_opt(ind=true), reason="no or non matching atom")
        let tok = tokens.next(ind=rule.raw)
        if rule.save:
            parse_ok(tok)
        else:
            parse_ok()

    of AltRule:
        var last_trace: ParseError = nil
        for subrule in rule.rules:
            tokens.checkpoint()
            let expr = parse_rule(p, tokens, subrule, follow + rule.follow)
            if expr.is_ok:
                when debug_parser > 1: echo $expr & " <- " & rule.str
                return expr
            last_trace = expr.get_error
            when debug_parser > 0: echo fmt"parse_rule: backtrack token stream to {tokens.index} (head: {tokens.peek_opt})"
            tokens.backtrack()
        parse_error(rule, parent=last_trace, reason="no term matched from alternatives")

    of SeqRule:
        var exprs: seq[Exp]
        let subrules = rule.rules
        for subrule in subrules:
            let res = parse_rule(p, tokens, subrule, follow + rule.follow)
            if res.is_error:
                when debug_parser > 0: echo fmt"parse error: broken seq"
                return parse_error(rule, term(exprs), res.get_error, reason="incomplete term sequence")
            let expr = res.get
            when debug_parser > 1: echo $expr & " <- in seq " & subrule.str & " -- " & $subrule.slots & " splice: " & $subrule.should_splice
            if expr.is_some:
                if subrule.should_splice and expr.get.is_term:
                    exprs &= expr.get.exprs
                else:
                    exprs.add(expr.get)
        when debug_parser > 1: echo $exprs & " <- in seq " & rule.str & " -- " & $rule.slots & " splice: " & $rule.should_splice
        if rule.slots == 0:
            parse_ok()
        elif rule.slots == 1 and exprs.len == 1:
            parse_ok(exprs[0])
        else:
            parse_ok(term(exprs))

    of RepRule:
        let subrule = rule.rule
        let follow = follow + rule.follow - rule.first
        var exprs: seq[Exp]
        while not tokens.eos and not tokens.expect_in(follow):
            let res = parse_rule(p, tokens, subrule, follow)
            if res.is_error:
                when debug_parser > 0:
                    echo fmt"parse_rule: break repeat rule"
                break
            let expr = res.get
            when debug_parser > 1:
                echo $expr & " <- in rep " & subrule.str & " -- " & $subrule.slots & " splice: " & $subrule.should_splice
            if expr.is_some:
                if subrule.should_splice and expr.get.is_term:
                    exprs &= expr.get.exprs
                else:
                    exprs.add(expr.get)
        when debug_parser > 1:
            echo fmt"parse_rule: finished repeat rule {rule} (slots: {rule.slots}, splice: {rule.should_splice}, exprs: {exprs})"
        if rule.slots == 0:
            parse_ok()
        else:
            parse_ok(term(exprs))

proc parse_expr(p: var Parser, tokens: var ExpStream, until = init_hash_set[string](), rule = none(SyntaxRule)): Result[ParseError, Option[Exp]] =
    if tokens.expect_in(until):
        return parse_ok()
    var expr_opt = tokens.peek_opt
    if expr_opt.is_none:
        let rule2 = if rule.is_some: rule.get else: exp_rule("Any")
        return parse_error(rule2, term(), nil, reason="end of stream while parsing expression")
    var expr = expr_opt.get

    # if a rule cannot occur here, treat the token as a literal
    if p.prefix_rules.has_key(expr.value) and not expr.is_literal:
        let subrule = p.prefix_rules[expr.value]
        if rule.is_some and subrule.group != "Any" and rule.get.group != some("Any"):
            let (group, assoc) = (rule.get.group.get, rule.get.relation)
            if subrule.group == group:
                if assoc == StrongerThan:
                    return parse_error(rule.get, expr, nil, reason=fmt"{group} is non-associative")
            elif p.tighter_than[subrule.group].contains(group):
                discard
            elif p.tighter_than[group].contains(subrule.group):
                discard
            else:
                return parse_error(rule.get, expr, nil, reason=fmt"{group} is not related to {subrule.group}")

        when debug_parser > 0: echo fmt"parse_expr: found prefix operator `{expr}`, trying rule {subrule.rule}"
        let res = parse_rule(p, tokens, subrule.rule, until + subrule.rule.follow)
        let head = atom(subrule.function)
        if res.is_error: 
            raise_parse_error( parse_error(subrule.rule, head, res.get_error).get_error, tokens.peek_opt )
        let right = res.get
        if right.is_some():
            if subrule.rule.should_splice:
                expr = concat(head, right.get)
            else:
                expr = term(head, right.get)
    else:
        when debug_parser > 0: echo fmt"parse_expr: shift literal `{expr}`"
        expr = tokens.next_opt.get

    while not tokens.eos:
        let token_opt = tokens.peek_opt
        if token_opt.is_none: break
        let token = token_opt.get
        # TODO: how to generalize this condition?
        if tokens.expect("$CNT") or tokens.expect(";"):
            break
        if tokens.expect_in(until):
            break
        if not p.infix_rules.has_key(token.value) or token.is_literal:
            when debug_parser > 0: echo fmt"parse_expr: found literal {token} in infix position (break)"
            break
        # if rule cannot occur here: break 
        let subrule = p.infix_rules[token.value]
        if rule.is_some and subrule.group != "Any" and rule.get.group != some("Any"):
            let (group, assoc) = (rule.get.group.get, rule.get.relation)
            if subrule.group == group:
                if assoc == StrongerThan:
                    when debug_parser > 0: echo fmt"parse_expr: infix break ({group} is non-associative)"
                    break
            elif p.tighter_than[subrule.group].contains(group):
                discard
            elif p.tighter_than[group].contains(subrule.group):
                when debug_parser > 0: echo fmt"parse_expr: infix break ({group} is tighter than {subrule.group})"
                break
            else:
                return parse_error(rule.get, expr, nil, reason=fmt"{group} is not related to {subrule.group}")

        when debug_parser > 0: echo fmt"parse_expr: valid infix operator `{token.value}`, trying rule {subrule.rule}"
        let res = parse_rule(p, tokens, subrule.rule, until + subrule.rule.follow)
        let head = atom(subrule.function)
        let left = expr
        expr = term(head, left)
        if res.is_error: 
            raise_parse_error( parse_error(subrule.rule, expr, res.get_error).get_error, tokens.peek_opt )
        let right = res.get
        if right.is_some:
            if subrule.rule.should_splice:
                expr = concat(expr, right.get)
            else:
                expr = append(expr, right.get)

    when debug_parser > 0: echo fmt"parse_expr: return expr {expr}" 

    return parse_ok(expr)

iterator parse*(p: var Parser, tokens: seq[Exp]): Exp {.inline.} =
    var stream = mkstream(tokens)
    while stream.peek_opt.is_some:
        if stream.expect("$CNT", raw=true) or stream.expect(";", raw=true):
            discard stream.next(ind=true)
            continue
        let res = parse_expr(p, stream)
        if res.is_error and not stream.eos:
            raise_parse_error( res.get_error, stream.peek_opt )
        elif res.get.is_some:
            let expr = res.get.get
            when debug_parser > 0: echo expr.str
            yield expr

func operator_graph*(self: Parser): string =
    result = "digraph {\n"
    for x, ys in self.tighter_than:
        for y in ys:
            result &= "\"{x}\" -> \"{y}\"\n".fmt
    result &= "}"