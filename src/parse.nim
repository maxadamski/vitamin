import sets, tables, options, strformat
import common/[exp, error, syntaxrule, expstream, utils]

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
    err[ParseError, Option[Exp]](x)

func parse_error(rule: SyntaxRule, partial: Option[Exp] = none(Exp), parent: ParseError = nil, reason: string = ""): auto =
    parse_error(ParseError(rule: rule, partial: partial, parent: parent, reason: reason))

func parse_error(rule: SyntaxRule, partial: Exp, parent: ParseError = nil, reason: string = ""): auto =
    parse_error(rule, some(partial), parent, reason)

func parse_ok(x: Option[Exp] = none(Exp)): auto =
    ok[ParseError, Option[Exp]](x)

func parse_ok(x: Exp): auto =
    ok[ParseError, Option[Exp]](some(x))

func `$`(x: Option[Exp]): string =
    if x.is_some: $x.get else: "None"

proc raise_parse_error(error: ParseError, token: Option[Exp]) =
    var text = ""
    var trace = error
    var node = error.partial.get
    var follow: HashSet[string]
    while trace != nil:
        follow = trace.rule.follow
        text &= "while parsing " & trace.rule.str
        if trace.partial.is_some:
            text &= "\n  found: " & trace.partial.get.str_ugly
            node = concat(node, trace.partial.get)
        if trace.reason != "":
            text &= "\n  error: " & trace.reason
        trace = trace.parent
        if trace != nil:
            text &= "\n"
    let rule = error.rule
    let source = node.in_source
    let source_text = if source == "": "" else: "\n\n" & source
    raise error(node, "Parser rule {rule.str} failed.{source_text}\n\n{text}".fmt)

proc parse_expr(p: var Parser, tokens: var ExpStream, follow: HashSet[string] = init_hash_set[string](), rule: Option[SyntaxRule] = none(SyntaxRule)): Result[ParseError, Option[Exp]]

proc parse_rule(p: var Parser, tokens: var ExpStream, rule: SyntaxRule, follow: HashSet[string]): Result[ParseError, Option[Exp]] =
    when debug_parser > 0: echo fmt"parse_rule: try rule {rule.kind} {rule} (head: `{tokens.peek_opt}`, first: {rule.first}, follow: {rule.follow})"
    let follow = rule.follow + follow
    case rule.kind:
    of NilRule:
        parse_ok(term())

    of ExpRule:
        let res = parse_expr(p, tokens, follow, some(rule))
        when debug_parser > 0:
            if res.is_err: echo fmt"parse_rule: error {res.get_err.reason}"
        res

    of TokRule:
        if rule.value == "":
            if tokens.eos:
                return parse_error(rule, term(), reason="expected any token, but got EOS")
            return parse_ok(tokens.next(ind=rule.raw))

        if not tokens.expect(rule.value, raw=rule.raw):
            let tok = tokens.peek_opt(ind=true)
            return parse_error(rule, tok, reason=fmt"expected `{rule.value}`, but found `{tok}`")
        let tok = tokens.next_opt(ind=rule.raw)
        when debug_parser > 0: echo fmt"parse_rule: shift token `{tok}`"
        if rule.save:
            parse_ok(tok.get)
        else:
            parse_ok()

    of AltRule:
        var last_trace: ParseError = nil
        for subrule in rule.rules:
            tokens.checkpoint()
            let expr = parse_rule(p, tokens, subrule, follow)
            if expr.is_ok:
                if rule.slots == 0:
                    return parse_ok()
                else:
                    return expr
            last_trace = expr.get_err
            when debug_parser > 0: echo fmt"parse_rule: alternative did not match: backtrack token stream to {tokens.index} (head: {tokens.peek_opt})"
            tokens.backtrack()
        parse_error(rule, parent=last_trace, reason="could not match any rule from alternatives")

    of SeqRule:
        var exprs: seq[Exp]
        if rule.op != "":
            exprs.add(atom(rule.op))
        let subrules = rule.rules
        for subrule in subrules:
            let res = parse_rule(p, tokens, subrule, follow)
            if res.is_err:
                when debug_parser > 0: echo fmt"parse_rule: could not complete sequence; pop"
                return parse_error(rule, term(exprs), res.get_err, reason="could not complete sequence")
            let expr = res.get
            when debug_parser > 1: echo fmt"parse_rule: seq item {expr}"
            if expr.is_some:
                if subrule.should_splice and expr.get.is_term:
                    exprs &= expr.get.exprs
                else:
                    exprs.add(expr.get)

        when debug_parser > 1:
            echo fmt"parse_rule: finished seq rule {rule} (slots: {rule.slots}, splice: {rule.should_splice}, exprs: {exprs})"
        if rule.slots == 0 and exprs.len == 0:
            parse_ok()
        elif rule.slots == 1 and exprs.len == 1:
            parse_ok(exprs[0])
        else:
            parse_ok(term(exprs))

    of RepRule:
        let subrule = rule.rule
        var exprs: seq[Exp]
        while not tokens.eos and not tokens.expect_in(follow - rule.first):
            tokens.checkpoint()
            let res = parse_rule(p, tokens, subrule, follow + subrule.first)
            if res.is_err:
                when debug_parser > 0: echo fmt"parse_rule: did not match repeat rule: backtrack & pop"
                tokens.backtrack()
                break
            let expr = res.get
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

proc parse_expr(p: var Parser, tokens: var ExpStream, follow = init_hash_set[string](), rule = none(SyntaxRule)): Result[ParseError, Option[Exp]] =
    # TODO: refactor this monster of a function
    # TODO: make errors more descriptive
    let rule2 = if rule.is_some: rule.get else: exp_rule("Any")
    if tokens.expect_in(follow):
        return parse_error(rule2, term(), nil, reason=fmt"token `{tokens.peek_opt()}` in follow set {follow} while parsing expression, backtracking")
    var expr_opt = tokens.peek_opt
    if expr_opt.is_none:
        return parse_error(rule2, term(), nil, reason="end of stream while parsing expression")
    var expr = expr_opt.get


    # if a rule cannot occur here, treat the token as a literal
    if p.prefix_rules.has_key(expr.value) and not expr.is_literal:
        let parselet = p.prefix_rules[expr.value]
        let subrule = parselet.rule
        if rule.is_some and parselet.group != "Any" and rule.get.group != some("Any"):
            let (group, assoc) = (rule.get.group.get, rule.get.relation)
            if parselet.group == group:
                if assoc == StrongerThan:
                    return parse_error(rule.get, expr, nil, reason=fmt"{group} is non-associative")
            elif p.tighter_than[parselet.group].contains(group):
                discard
            elif p.tighter_than[group].contains(parselet.group):
                discard
            else:
                return parse_error(rule.get, expr, nil, reason=fmt"{group} is not related to {parselet.group}")

        when debug_parser > 0: echo fmt"parse_expr: found prefix operator `{expr}`, trying rule {subrule}"
        let res = parse_rule(p, tokens, subrule, follow)
        let head = atom(parselet.function)
        if res.is_err: 
            raise_parse_error( parse_error(subrule, head, res.get_err).get_err, tokens.peek_opt )
        let right = res.get
        if right.is_some:
            if subrule.should_splice:
                expr = concat(head, right.get)
            else:
                expr = term(head, right.get)

    elif p.infix_rules.has_key(expr.value) and not expr.is_literal:
        when debug_parser > 0: echo fmt"parse_expr: found infix operator `{expr}` in prefix position: backtracking"
        return parse_error(rule2, term(), nil, reason=fmt"found infix operator `{expr}` in prefix position: backtracking")

    else:
        when debug_parser > 0: echo fmt"parse_expr: shift literal `{expr}`"
        expr = tokens.next_opt.get

    while not tokens.eos:
        let token_opt = tokens.peek_opt
        if token_opt.is_none: break
        let token = token_opt.get
        if tokens.expect_in(follow):
            when debug_parser > 0: echo fmt"parse_expr: found terminal {token_opt} in infix position (break)"
            break
        if not p.infix_rules.has_key(token.value) or token.is_literal:
            when debug_parser > 0: echo fmt"parse_expr: found literal {token} in infix position (break)"
            break
        # TODO: make sure that if a rule cannot occur here: break 
        let parselet = p.infix_rules[token.value]
        let subrule = parselet.rule
        if rule.is_some and parselet.group != "Any" and rule.get.group != some("Any"):
            let (group, assoc) = (rule.get.group.get, rule.get.relation)
            if parselet.group == group:
                if assoc == StrongerThan:
                    when debug_parser > 0: echo fmt"parse_expr: infix break ({group} is non-associative)"
                    break
            elif p.tighter_than[parselet.group].contains(group):
                discard
            elif p.tighter_than[group].contains(parselet.group):
                when debug_parser > 0: echo fmt"parse_expr: infix break ({group} is tighter than {parselet.group})"
                break
            else:
                return parse_error(rule.get, expr, nil, reason=fmt"{group} is not related to {parselet.group}")

        when debug_parser > 0: echo fmt"parse_expr: valid infix operator `{token.value}`, trying rule {subrule}"
        let res = parse_rule(p, tokens, subrule, follow)
        let head = atom(parselet.function)
        let left = expr
        expr = term(head, left)
        if res.is_err: 
            raise_parse_error( parse_error(subrule, expr, res.get_err).get_err, tokens.peek_opt )
        let right = res.get
        if right.is_some:
            if subrule.should_splice:
                expr = concat(expr, right.get)
            else:
                expr = append(expr, right.get)

    when debug_parser > 0: echo fmt"parse_expr: return expr {expr}" 
    return parse_ok(expr)

iterator parse*(p: var Parser, tokens: seq[Exp]): Exp {.inline.} =
    # This function can be expressed as a SyntaxRule (($CNT | ';')+ Any ($EOS | ($CNT | ';')+)), but I wanted an iterator
    var stream = mkstream(tokens)
    var follow: HashSet[string]
    follow.incl("$CNT")
    follow.incl(";")
    while stream.peek_opt.is_some:
        if stream.expect("$CNT", raw=true) or stream.expect(";", raw=true):
            discard stream.next(ind=true)
            continue
        let res = parse_expr(p, stream, follow=follow)
        if res.is_err and not stream.eos:
            raise_parse_error( res.get_err, stream.peek_opt )
        elif res.get.is_some:
            let expr = res.get.get
            when debug_parser > 0: echo expr.str
            yield expr

            if stream.peek_opt.is_some:
                var found_sep = false
                while stream.expect("$CNT", raw=true) or stream.expect(";", raw=true):
                    found_sep = true
                    discard stream.next(ind=true)
                if not found_sep:
                    let head = stream.peek_opt.get
                    raise error(stream.peek_opt.get, "Expected a newline `$CNT` or semicolon `;` after expression, but found `{head}`.\n\n{head.in_source}".fmt)


func operator_graph*(self: Parser): string =
    result = "digraph {\n"
    for x, ys in self.tighter_than:
        for y in ys:
            result &= "\"{x}\" -> \"{y}\"\n".fmt
    result &= "}"
