import types, error
import sets, tables, options, sequtils, strutils, strformat

type
    SyntaxRuleKind* = enum
        SeqRule, AltRule, RepeatRule, ExprRule, AtomRule, BlockRule

    SyntaxGroupRelation* = enum
        StrongerThan, StrongerEqual

    SyntaxGroup* = ref object
        name: string
        stronger_than*: seq[SyntaxGroup]

    SyntaxRule* = ref object
        case kind*: SyntaxRuleKind
        of SeqRule, AltRule:
            rules*: seq[SyntaxRule]
        of RepeatRule:
            rule*: SyntaxRule
            sep*: string
            min*, max*: int
            trailing*: bool
        of ExprRule:
            group*: Option[string]
            relation*: SyntaxGroupRelation
        of AtomRule:
            value*: string
            tag*: Option[AtomTag]
        of BlockRule:
            indented*: bool
    
    Parselet* = object
        name*, group*: string
        splat*: bool
        rule*: bool

    Parser* = ref object
        parent*: Parser
        tighter_than*: Table[string, HashSet[string]]
        infix_rules*: Table[string, tuple[group, name: string, splat: bool, rule: SyntaxRule]]
        prefix_rules*: Table[string, tuple[group, name: string, splat: bool, rule: SyntaxRule]]

    ParseError* = ref object
        parent*: ParseError
        rule*: SyntaxRule
        partial*: Option[Exp]
        reason*: string

proc `$`(self: SyntaxRule): string
proc parse_until_maybe(p: var Parser, tokens: var ExpStream, until: HashSet[string] = init_hash_set[string](), rule: Option[SyntaxRule] = none(SyntaxRule)): Result[ParseError, Option[Exp]]
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

func follow_tokens(self: SyntaxRule): HashSet[string] =
    case self.kind:
    of AltRule:
        for subrule in self.rules:
            result = result + subrule.follow_tokens
    of SeqRule:
        for subrule in self.rules:
            case subrule.kind
            of RepeatRule:
                result = result + subrule.follow_tokens
                if subrule.min > 0:
                    break
            of AtomRule:
                result.incl(subrule.value)
                # TODO: should this break be here?
                #break
            else:
                continue
    of RepeatRule:
        result = self.rule.follow_tokens
    else:
        discard
    return result

func get_or(x: Option[Exp], default: Exp = term()): Exp =
    if x.is_some: x.get else: default

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
    let follow = rule.follow_tokens
    let found = if token.is_some: ", but found `{token.get}`".fmt else: ""
    let source = node.in_source
    let source_text = if source == "<not found>": "" else: "\n\n" & source
    raise verror(1006, node, "Parser rule {rule} failed.{source_text}\n\nExpected one of the following tokens: {follow}{found}\n\nParse trace:\n\n{text}".fmt)

func seq_rule(rules: varargs[SyntaxRule]): SyntaxRule = SyntaxRule(kind: SeqRule, rules: @rules)
func alt_rule(rules: varargs[SyntaxRule]): SyntaxRule = SyntaxRule(kind: AltRule, rules: @rules)
func loop_rule(min, max: int, rule: SyntaxRule): SyntaxRule = SyntaxRule(kind: RepeatRule, rule: rule, min: min, max: max, sep: "")
func list0_rule(sep: string, rule: SyntaxRule): SyntaxRule = SyntaxRule(kind: RepeatRule, rule: rule, min: 0, max: -1, sep: sep, trailing: true)
func some_rule(rule: SyntaxRule): SyntaxRule = loop_rule(min=0, max= -1, rule=rule)
func opt_rule(rule: SyntaxRule): SyntaxRule = loop_rule(min=0, max=1, rule=rule)
func opt_rule_seq(rules: varargs[SyntaxRule]): SyntaxRule = opt_rule(seq_rule(rules))
func expr_rule(group: Option[string], relation = StrongerEqual): SyntaxRule = SyntaxRule(kind: ExprRule, group: group, relation: relation)
func expr_rule(group: string, relation = StrongerEqual): SyntaxRule = expr_rule(some(group), relation)
func atom_rule(value: string, tag = none(AtomTag)): SyntaxRule = SyntaxRule(kind: AtomRule, value: value, tag: tag)
func opt_atom(value: string): SyntaxRule = opt_rule(atom_rule(value))
proc block_rule(indented = true): SyntaxRule = SyntaxRule(kind: BlockRule, indented: indented)
proc bexpr_rule(group: string, relation = StrongerEqual): SyntaxRule = alt_rule(block_rule(), expr_rule(group, relation))
func is_list_rule(x: SyntaxRule, sep: string): bool = x.kind == RepeatRule and x.min in {0, 1} and x.max == -1 and x.sep == sep
proc is_block_rule(x: SyntaxRule): bool = x.kind == BlockRule
proc is_bexpr_rule(x: SyntaxRule): bool = x.kind == AltRule and x.rules[0].is_block_rule and x.rules[1].kind == ExprRule

proc to_string(self: SyntaxRule): string =
    case self.kind:
    of BlockRule:
        "Block"
    of SeqRule:
        "(" & self.rules.map(to_string).join(" ") & ")"
    of AltRule:
        "(" & self.rules.map(to_string).join(" / ") & ")"
    of AtomRule:
        "'" & self.value & "'"
    of ExprRule:
        if self.group.is_none:
            "Expr"
        else:
            let rel = if self.relation == StrongerEqual: "<=" else: "<"
            "Expr" & rel & $self.group.get
    of RepeatRule:
        if self.min == 0 and self.max == -1:
            if self.sep != "":
                "({self.rule} '{self.sep}')**".fmt
            else:
                "{self.rule}*".fmt
        elif self.min == 1 and self.max == -1:
            if self.sep != "":
                "({self.rule} '{self.sep}')++".fmt
            else:
                "{self.rule}+".fmt
        elif self.min == 0 and self.max == 1:
            "{self.rule}?".fmt
        else:
            "(loop min={self.min} max={self.max} sep=`{self.sep}` {self.rule})".fmt

proc `$`(self: SyntaxRule): string =
    let res = to_string(self)
    if res.starts_with("(") and res.ends_with(")"):
        return res[1 ..< ^1]
    return res

proc to_expr_flatten(exprs: seq[Exp]): Exp =
    if exprs.len == 1:
        return exprs[0]
    else:
        return term(exprs)

proc parse_rule_maybe(p: var Parser, tokens: var ExpStream, rule: SyntaxRule, until_token: HashSet[string]): Result[ParseError, Option[Exp]] =
    case rule.kind:
    of ExprRule:
        parse_until_maybe(p, tokens, until_token + rule.follow_tokens, some(rule))

    of AtomRule:
        if tokens.eat_atom(rule.value).is_none:
            return parse_error(rule, tokens.peek_opt(ind=true), reason="no or non matching atom")
        parse_ok()

    of AltRule:
        var last_trace: ParseError = nil
        for subrule in rule.rules:
            let expr = parse_rule_maybe(p, tokens, subrule, until_token + rule.follow_tokens)
            if expr.is_ok: return expr
            last_trace = expr.get_error
        parse_error(rule, parent=last_trace, reason="no term matched from alternatives")

    of SeqRule:
        var exprs: seq[Exp]
        let subrules = rule.rules
        for subrule in subrules:
            let res = parse_rule_maybe(p, tokens, subrule, until_token + rule.follow_tokens)
            if res.is_error:
                #echo fmt"parse error: broken seq"
                return parse_error(rule, term(exprs), res.get_error, reason="incomplete term sequence")
            let expr = res.get
            if expr.is_some: exprs.add(expr.get)
        parse_ok(to_expr_flatten(exprs))

    of BlockRule:
        var exprs: seq[Exp]
        var until = until_token
        until.incl("$DED")
        if rule.indented:
            if tokens.eat_atom("$IND").is_none:
                return parse_error(rule, term(), nil,
                    reason="expected $IND token before block")
        while not tokens.eos:
            if rule.indented and tokens.expect_raw("$DED"):
                discard tokens.next(ind=true)
                break
            if tokens.expect_raw("$CNT") or tokens.expect_raw(";"):
                discard tokens.next(ind=true)
                continue
            let res = parse_until_maybe(p, tokens, until)
            if res.is_error:
                return parse_error(rule, term(exprs), res.get_error,
                    reason="error occured while parsing statement in the block")
            elif res.get.is_some:
                let expr = res.get.get
                exprs.add(expr)
        
        parse_ok(term(exprs))

    of RepeatRule:
        let subrule = rule.rule
        let has_sep = rule.sep != ""
        var count = 0
        var exprs: seq[Exp]
        var until = until_token + rule.follow_tokens
        if has_sep:
            until.incl(rule.sep)
        while not tokens.eos and (rule.max == -1 or count < rule.max):
            if has_sep:
                if count == 0:
                    if tokens.expect(rule.sep):
                        return parse_error(rule, term(exprs), nil,
                            reason=fmt"expected {subrule} but found separator `{rule.sep}`")
                elif tokens.eat_atom(rule.sep).is_none:
                    break
            let res = parse_rule_maybe(p, tokens, subrule, until)
            if res.is_error:
                if has_sep and not rule.trailing:
                    return parse_error(rule, term(exprs), res.get_error,
                        reason=fmt"expected another {subrule} after `{rule.sep}`")
                break
            if count > rule.max and rule.max != -1:
                return parse_error(rule, term(exprs), res.get_error,
                    reason=fmt"expected at most {rule.max} {subrule} expressions, but got {count}")
            let expr = res.get
            if expr.is_some:
                exprs.add(expr.get)
            count += 1
        if count < rule.min:
            return parse_error(rule, term(exprs), nil,
                reason=fmt"expected at least {rule.min} {subrule} expressions, but got {count}")
        if rule.min == 0 and rule.max == 1:
            if exprs.len == 1:
                return parse_ok(exprs[0])
            elif subrule.kind == AtomRule:
                return parse_ok()
            else:
                return parse_ok(term())
        parse_ok(term(exprs))

proc parse_rule_prefix(p: var Parser, tokens: var ExpStream, until: HashSet[string], name: string, rule: SyntaxRule,  splat: bool,op: Exp): Exp =
    let right_rule = if rule.kind == SeqRule:  seq_rule(rule.rules[1 .. ^1]) else: rule
    let right_res = parse_rule_maybe(p, tokens, right_rule, until + right_rule.follow_tokens)
    if right_res.is_error: 
        raise_parse_error( parse_error(rule, atom(name), right_res.get_error).get_error, tokens.peek_opt )
    let right = right_res.get.get_or()
    let expr = atom(name)
    if splat: 
        concat(expr, right)
    else:
        term(expr, right)

proc parse_rule_infix(p: var Parser, tokens: var ExpStream, until: HashSet[string], name: string, rule: SyntaxRule, splat: bool, left: Exp, op: Exp): Exp =
    let right_rule = if rule.kind == SeqRule: seq_rule(rule.rules[2 .. ^1]) else: rule
    let right_res = parse_rule_maybe(p, tokens, right_rule, until + right_rule.follow_tokens)
    if right_res.is_error: 
        raise_parse_error( parse_error(rule, term(atom(name), left), right_res.get_error).get_error, tokens.peek_opt )
    let right = right_res.get.get_or()
    let expr = term(atom(name), left)
    if splat:
        concat(expr, right)
    else:
        append(expr, right)

proc parse_until_maybe(p: var Parser, tokens: var ExpStream, until = init_hash_set[string](), rule = none(SyntaxRule)): Result[ParseError, Option[Exp]] =
    if tokens.expect_in(until):
        return parse_ok()
    var expr_opt = tokens.next_opt
    if expr_opt.is_none:
        let rule2 = if rule.is_some: rule.get else: expr_rule("Any")
        return parse_error(rule2, term(), nil, reason="end of stream while parsing expression")
    var expr = expr_opt.get
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

        expr = parse_rule_prefix(p, tokens, until, subrule.name, subrule.rule, subrule.splat, expr)

    while not tokens.eos:
        let token_opt = tokens.peek_opt
        if token_opt.is_none: break
        let token = token_opt.get
        if tokens.expect("$CNT") or tokens.expect(";"):
            break
        if tokens.expect_in(until):
            break
        if not p.infix_rules.has_key(token.value) or token.is_literal:
            break
        # if rule cannot occur here: break 
        let subrule = p.infix_rules[token.value]
        if rule.is_some and subrule.group != "Any" and rule.get.group != some("Any"):
            let (group, assoc) = (rule.get.group.get, rule.get.relation)
            if subrule.group == group:
                if assoc == StrongerThan:
                    #echo fmt"infix break ({group} is non-associative)"
                    break
            elif p.tighter_than[subrule.group].contains(group):
                discard
            elif p.tighter_than[group].contains(subrule.group):
                #echo fmt"infix break ({group} is tighter than {subrule.group})"
                break
            else:
                return parse_error(rule.get, expr, nil, reason=fmt"{group} is not related to {subrule.group}")
        expr = parse_rule_infix(p, tokens, until, subrule.name, subrule.rule, subrule.splat, expr, tokens.next)
    return parse_ok(expr)

iterator parse*(p: var Parser, tokens: seq[Exp]): Exp {.inline.} =
    var stream = mkstream(tokens)
    while stream.peek_opt.is_some:
        if stream.expect("$CNT", ind=true) or stream.expect(";", ind=true):
            discard stream.next(ind=true)
            continue
        let res = parse_until_maybe(p, stream)
        if res.is_error and not stream.eos:
            raise_parse_error( res.get_error, stream.peek_opt )
        elif res.get.is_some:
            let expr = res.get.get
            echo expr
            yield expr

proc add_groups(parser: var Parser, groups: string) =
    for name in groups.split(' '):
        parser.tighter_than[name] = HashSet[string]()

proc add_order(parser: var Parser, order: string) =
    let groups = order.split(" > ")
    for i, group in groups:
        for looser in groups[i+1..<groups.len]:
            for tight in group.split(' '):
                for loose in looser.split(' '):
                    parser.tighter_than[tight].incl(loose)
                    #parser.tighter_than[loose].incl(tight)

proc add_infix(parser: var Parser, group, fun, tok: string, splat = false, left_assoc = StrongerThan, right_assoc = StrongerThan) =
    parser.infix_rules[tok] = (group, fun, splat, seq_rule( expr_rule(group, left_assoc), atom_rule(tok), expr_rule(group, right_assoc) ))

proc add_prefix(parser: var Parser, group, fun, tok: string, assoc = StrongerThan, splat = false) =
    parser.prefix_rules[tok] = (group, fun, splat, seq_rule( atom_rule(tok), expr_rule(group, assoc) ))

proc add_infix_left(parser: var Parser, group, fun, tok: string, splat = false) =
    parser.add_infix(group, fun, tok, splat, StrongerThan, StrongerThan)

proc add_infix_right(parser: var Parser, group, fun, tok: string, splat = false) =
    parser.add_infix(group, fun, tok, splat, StrongerThan, StrongerEqual)

var global_parser* = Parser()

global_parser.add_groups("Indented-Block Round-Parentheses Function-Call Exponentiation Exponentiation-Base Exponentiation-Power Multiplication Addition Negation")
global_parser.add_groups("Opaque Macro Command Use Member Logical-Not Logical-And Logical-Or Logical-Xor Equality Ordering Function Definition Assignment Typing")
global_parser.add_groups("If-Expr Case-Expr While-Expr For-Expr")

global_parser.add_order("Function-Call > Round-Parentheses > Exponentiation-Base > Negation > Exponentiation-Power > Exponentiation > Multiplication > Addition > Assignment Definition")
global_parser.add_order("Function-Call > Round-Parentheses > Logical-Not > Equality Ordering > Logical-And Logical-Or Logical-Xor > If-Expr > Function > Assignment Definition")
global_parser.add_order("Typing > Definition")
global_parser.add_order("Logical-And > Logical-Or")
global_parser.add_order("Definition Round-Parentheses Function-Call > Use")
global_parser.add_order("Function-Call Round-Parentheses Equality Ordering Logical-And Logical-Or Logical-Not > Command")
global_parser.add_order("Member > Function-Call Assignment Use")
global_parser.add_order("Macro Opaque > Round-Parentheses Definition Function")
global_parser.add_order("Function > Macro Opaque")
global_parser.add_order("If-Expr > Use")

global_parser.add_infix_left("Member", "member", ".")
global_parser.add_infix_left("Definition", "let", "=")
global_parser.add_infix_right("Assignment", "assign", ":=")
global_parser.add_infix_left("Typing", "type", ":")
global_parser.add_infix_left("Addition", "add", "+")
global_parser.add_infix_left("Addition", "sub", "-")
global_parser.add_infix_left("Multiplication", "mul", "*")
global_parser.add_infix_left("Multiplication", "div", "/")
global_parser.add_infix("Equality", "equal", "==")
global_parser.add_infix("Equality", "not-equal", "!=")
global_parser.add_infix("Ordering", "less-than", "<")
global_parser.add_infix("Ordering", "greather-than", ">")
global_parser.add_infix("Ordering", "less-than-or-equal", "<=")
global_parser.add_infix("Ordering", "greather-than-or-equal", ">=")
global_parser.add_prefix("Negation", "negation", "-")
global_parser.add_prefix("Use", "use", "use")
global_parser.add_prefix("Use", "use-macro", "use-macro")
global_parser.add_prefix("Use", "use-syntax", "use-syntax")
global_parser.add_prefix("Opaque", "opaque", "opaque")
global_parser.add_prefix("Macro", "macro", "macro")
global_parser.add_prefix("Command", "assert", "assert")
global_parser.add_prefix("Logical-Not", "not", "not")
global_parser.add_infix_left("Logical-And", "and", "and")
global_parser.add_infix_left("Logical-Or", "or", "or")
global_parser.add_infix_left("Logical-Xor", "xor", "xor")
global_parser.infix_rules["^"] = ("Exponentiation-Base", "pow", false, seq_rule( expr_rule("Exponentiation-Base"), atom_rule("^"), bexpr_rule("Exponentiation") ))
global_parser.prefix_rules["("] = ("Round-Parentheses", "group", true, seq_rule( atom_rule("("), list0_rule(",", expr_rule("Any")), atom_rule(")") ))
global_parser.infix_rules["("] = ("Function-Call", "call", true, seq_rule( expr_rule("Function-Call"), atom_rule("("), list0_rule(",", expr_rule("Any")), atom_rule(")") ))
global_parser.infix_rules["=>"] = ("Function", "fun", false, seq_rule( expr_rule("Function"), atom_rule("=>"), bexpr_rule("Function") ))
global_parser.prefix_rules["while"] = ("While-Expr", "while-expr", true, seq_rule( atom_rule("while"), expr_rule("While-Expr"), opt_atom("do"), bexpr_rule("While-Expr") ))
global_parser.prefix_rules["for"] = ("For-Expr", "for-expr", true, seq_rule(atom_rule("for"), expr_rule("For-Expr"), atom_rule("in"), expr_rule("For-Expr"), opt_atom("do"), bexpr_rule("For-Loop") ))
global_parser.prefix_rules["if"] = ("If-Expr", "if-expr", true, seq_rule(
    atom_rule("if"), expr_rule("If-Expr"), opt_atom("do"), bexpr_rule("If-Expr"),
    some_rule(seq_rule( atom_rule("elif"), expr_rule("If-Expr"), opt_atom("do"), bexpr_rule("If-Expr") )),
    opt_rule(seq_rule( atom_rule("else"), bexpr_rule("If-Expr") )),
))
global_parser.prefix_rules["case"] = ("Case-Expr", "case-expr", true, seq_rule(
    atom_rule("case"), opt_rule(expr_rule("Case-Expr")),
    some_rule(seq_rule( atom_rule("of"), expr_rule("Case-Expr"), opt_atom("do"), bexpr_rule("Case-Expr") )),
))
