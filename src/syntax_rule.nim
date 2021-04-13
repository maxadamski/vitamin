import types
import options, sets, sequtils, strutils

type
    SyntaxRuleKind* = enum
        NilRule = 0, TokRule, ExpRule, SeqRule, AltRule, RepRule

    SyntaxGroupRelation* = enum
        StrongerThan, StrongerEqual

    SyntaxRule* = ref object
        should_splice*: bool
        slots*: int
        name*: string
        follow*: HashSet[string]
        first*: HashSet[string]
        case kind*: SyntaxRuleKind
        of NilRule:
            discard
        of SeqRule, AltRule:
            rules*: seq[SyntaxRule]
            is_opt*, is_plus*, is_list*: bool
        of RepRule:
            rule*: SyntaxRule
        of ExpRule:
            group*: Option[string]
            relation*: SyntaxGroupRelation
        of TokRule:
            value*: string
            tag*: Option[AtomTag]
            raw*: bool
            save*: bool

func is_optional(self: SyntaxRule): bool =
    return self.kind == NilRule or self.kind == RepRule or (self.kind == AltRule and (self.is_opt or self.rules.any(is_optional)))


# -- Base constructors

func seq_rule*(rules: seq[SyntaxRule], splice = false, is_plus = false, is_list = false, name = "", follow = init_hash_set[string]()): SyntaxRule =
    let slots = rules.map_it(int(it.slots > 0)).foldl(a + b)
    var first, follow: HashSet[string]
    for i in 0 ..< rules.high:
        first = first + rules[i].first
        if not rules[i].is_optional:
            break

    for i in 0 ..< rules.high:
        for j in i + 1 .. rules.high:
            rules[i].follow = rules[i].follow + rules[j].first
            if not rules[j].is_optional:
                break

    SyntaxRule(kind: SeqRule, rules: @rules, should_splice: splice, slots: slots, first: first, follow: follow, 
                is_plus: is_plus, is_list: is_list, name: name)

func alt_rule*(rules: seq[SyntaxRule], splice = false, is_opt = false, name = ""): SyntaxRule =
    let slots = rules.map_it(it.slots).max
    let first = rules.map_it(it.first).foldl(a + b)
    SyntaxRule(kind: AltRule, rules: @rules, should_splice: splice, slots: slots, is_opt: is_opt, name: name, first: first)

func rep_rule*(rule: SyntaxRule, splice = false): SyntaxRule =
    SyntaxRule(kind: RepRule, rule: rule, should_splice: splice, slots: int(rule.slots > 0), first: rule.first)

func tok_rule*(value: string = "", tag = none(AtomTag), raw = false, save = false): SyntaxRule =
    var first: HashSet[string]
    first.incl(value)
    SyntaxRule(kind: TokRule, value: value, tag: tag, raw: raw, save: save, slots: int(save), first: first)

func exp_rule*(group: Option[string], relation = StrongerEqual): SyntaxRule =
    SyntaxRule(kind: ExpRule, group: group, relation: relation, slots: 1)

func exp_rule*(group: string, relation = StrongerEqual): SyntaxRule =
    exp_rule(some(group), relation)

# -- Utility functions

func splice*(x: SyntaxRule): SyntaxRule =
    x.should_splice = true
    x

func named*(x: SyntaxRule, name: string): SyntaxRule =
    x.name = name
    x

func maybe_paren(x: string, y: bool, left = "(", right = ")"): string =
    if y: left & x & right else: x

func str*(self: SyntaxRule, group = true, toplevel = false): string =
    if self.name != "": return self.name

    case self.kind:
    of NilRule:
        "∅"
    of SeqRule:
        if self.is_plus:
            self.rules[0].str & "+"
        elif self.is_list:
            let val = self.rules[0]
            let sep = self.rules[1].rule.rules[0]
            (val.str & "^" & sep.str).maybe_paren(group)
        else:
            self.rules.map_it(it.str(group=false)).join(" ").maybe_paren(not toplevel, "[", "]")
    of AltRule:
        if self.is_opt:
            (self.rules[0].str & "?").maybe_paren(group)
        else:
            self.rules.map_it(it.str).join(" | ").maybe_paren(group)
    of TokRule:
        if self.value == "":
            "Atom"
        else:
            "'" & self.value & "'"
    of ExpRule:
        if self.group.is_none:
            return "Expr"
        case self.relation
        of StrongerEqual: $self.group.get
        of StrongerThan: $self.group.get
    of RepRule:
        (self.rule.str & "*").maybe_paren(group)

func `$`*(self: SyntaxRule): string =
    self.str

# -- Convenience constructors

func opt*(rule: SyntaxRule): SyntaxRule =
    alt_rule(@[rule, SyntaxRule(kind: NilRule)], is_opt=true)

func opt*(value: string): SyntaxRule =
    opt(tok_rule(value))

func star*(r: SyntaxRule): SyntaxRule =
    rep_rule(r)

func plus*(r: SyntaxRule): SyntaxRule =
    # x+ = x x*
    seq_rule(@[r, r.star.splice], is_plus=true)

func list*(rule, sep: SyntaxRule): SyntaxRule =
    # x^y = x (y x)*
    seq_rule(@[rule, seq_rule(@[sep, rule]).star.splice], is_list=true)

func list*(rule: SyntaxRule, sep: string): SyntaxRule =
    rule.list(tok_rule(sep))

func `&`*(x: SyntaxRule, y: SyntaxRule): SyntaxRule =
    if x.kind == SeqRule and y.kind == SeqRule:
        seq_rule(x.rules & y.rules)
    elif x.kind == SeqRule:
        seq_rule(x.rules & @[y])
    elif y.kind == SeqRule:
        seq_rule(y.rules & @[x])
    else:
        seq_rule(@[x, y])

func `|`*(x: SyntaxRule, y: SyntaxRule): SyntaxRule =
    if x.kind == AltRule and y.kind == AltRule:
        alt_rule(x.rules & y.rules)
    elif x.kind == AltRule:
        alt_rule(x.rules & @[y])
    elif y.kind == AltRule:
        alt_rule(y.rules & @[x])
    else:
        alt_rule(@[x, y])
