import parse, syntax_rule
import sets, tables, strutils, strformat

#
# Convenience parser functions
#

func add_infix_mix(self: var Parser, group, tok, fun: string, rule: SyntaxRule) =
    self.infix_rules[tok] = Parselet(group: group, function: fun, rule: rule)

func add_infix_mix(self: var Parser, group, tok: string, rule: SyntaxRule) =
    self.add_infix_mix(group, tok, tok, rule)

func add_prefix_mix(self: var Parser, group, tok, fun: string, rule: SyntaxRule) =
    self.prefix_rules[tok] = Parselet(group: group, function: fun, rule: rule)

func add_prefix_mix(self: var Parser, group, tok: string, rule: SyntaxRule) =
    self.add_prefix_mix(group, tok, tok, rule)

func add_infix(self: var Parser, group, tok: string, fun = tok, left_assoc = StrongerThan, right_assoc = StrongerThan) =
    self.add_infix_mix(group, tok, fun, tok_rule(tok) & exp_rule(group, right_assoc))

func add_prefix(self: var Parser, group, tok: string, fun = tok, assoc = StrongerThan) =
    self.add_prefix_mix(group, tok, fun, tok_rule(tok) & exp_rule(group, assoc))

func add_infix_none(self: var Parser, group: string, tokens: varargs[string]) =
    for x in tokens: self.add_infix(group, x, x, StrongerThan, StrongerThan)

func add_infix_left(self: var Parser, group: string, tokens: varargs[string]) =
    for x in tokens: self.add_infix(group, x, x, StrongerEqual, StrongerThan)

func add_infix_right(self: var Parser, group: string, tokens: varargs[string]) =
    for x in tokens: self.add_infix(group, x, x, StrongerThan, StrongerEqual)

func add_prefix_none(self: var Parser, group: string, tokens: varargs[string]) =
    for x in tokens: self.add_prefix(group, x, x, StrongerThan)

func add_prefix_left(self: var Parser, group: string, tokens: varargs[string]) =
    for x in tokens: self.add_prefix(group, x, x, StrongerEqual)

func add_groups(self: var Parser, groups: string) =
    for group in groups.split(' '):
        self.tighter_than[group] = init_hash_set[string]()

func add_order(self: var Parser, order: string) =
    let groups = order.split(" > ")
    for i, group in groups:
        for looser in groups[i+1..<groups.len]:
            for tight in group.split(' '):
                for loose in looser.split(' '):
                    self.tighter_than[tight].incl(loose)

#
# Convenience syntax rule constructors
# 

func tr(x: string): SyntaxRule = tok_rule(x, raw=true)

func ts(x: string): SyntaxRule = tok_rule(x, save=true)

func t(x: string): SyntaxRule = tok_rule(x)

func e(x: string): SyntaxRule = exp_rule(x, StrongerEqual)

func E(x: string): SyntaxRule = exp_rule(x, StrongerThan)

func I(): SyntaxRule =
    let stat_sep = (";".tr | "$CNT".tr).named("Stmt-Sep")
    let rule = "$IND".tr & "Any".e.list(stat_sep.plus).splice.opt & stat_sep.star & "$DED".tr
    rule.named("Block")

func b(group: string): SyntaxRule = (I() | group.e).named(fmt"Block({group})")

func B(group: string): SyntaxRule = (I() | group.E).named(fmt"(Block({group}))")

#
# Parser definition
#

# TODO: evaluate this during compile-time

var parser* = Parser()

# operator group definitions
parser.add_groups "Comma Semicolon Statement Group Lambda-Type Apply Pow Pow-Base Mul Add Inverse"
parser.add_groups "As Qualifier Member Not And Or Xor Cmp Lambda Definition Assignment Typing"

# oprerator group order definitions
parser.add_order "Apply > Group > Pow-Base > Inverse > Pow > Mul > Add > As > Assignment Definition"
parser.add_order "Apply > Group > Not > Cmp > And Or Xor > Statement > Lambda > Assignment Definition"
parser.add_order "Add Mul Inverse > Cmp"
parser.add_order "Apply > Typing"
parser.add_order "Member Typing > Definition"
parser.add_order "And > Or"
parser.add_order "Apply Group Cmp And Or Not Mul > Statement"
parser.add_order "Member > Apply Assignment"
parser.add_order "Qualifier > Group Typing Definition Lambda"
parser.add_order "Mul > Lambda"
parser.add_order "Group > Definition Typing > Comma > Semicolon"
parser.add_order "Lambda > Qualifier"
parser.add_order "Group > Lambda-Type > Typing Qualifier Lambda Definition"

# non-assocative infix operators
parser.add_infix_none "As", "as"

# left-associative infix operators
parser.add_infix_left "Member", "."
parser.add_infix_left "Definition", "="
parser.add_infix_left "Typing", ":"
parser.add_infix_left "Add", "+", "-"
parser.add_infix_left "Mul", "*", "/", "mod", "div"
parser.add_infix_left "And", "and"
parser.add_infix_left "Or", "or"
parser.add_infix_left "Xor", "xor"

# right-associative infix operators
parser.add_infix_right "Assignment", ":="
parser.add_infix_right "Lambda-Type", "->"

# non-associative prefix operators
parser.add_prefix_none "Not", "not"
parser.add_prefix_none "Inverse", "-", "-"
parser.add_prefix_none "Statement", "use", "assert", "return"

# associative prefix operators
parser.add_prefix_left "Qualifier", "opaque", "macro", "pure"

#parser.infix_rules[","] = ("Comma", ",", ((",".t & "Comma".E).plus & ",".opt).splice )
#parser.infix_rules[";"] = ("Semicolon", ",", ((";".t & "Semicolon".e).plus & ";".opt).splice )
#parser.prefix_rules["("] = ("Parentheses", "()", "(".t & "Any".b.star & ")".t)


# group = ((Any+)^',' ','?)^';' ';'?
let group0 = (("Any".E.plus.list(",") & ",".opt).list(";") & ";".opt).splice.named("Group(';' | ',' | $WS)")

let group1 = (("Any".E.list(",") & ",".opt.splice).list(";") & ";".opt).splice.named("Group(';' | ',')")

parser.add_infix_mix "Comma", ",", (",".t & "Comma".E).splice.star

parser.add_prefix_mix "Group", "(", "(_)", "(".t & group0.opt & ")".t

parser.add_prefix_mix "Group", "[", "[_]", "[".t & group0.opt & "]".t

parser.add_infix_mix "Apply", "[", "[]", "[".t & group1.opt & "]".t

parser.add_infix_mix "Apply", "(", "()", "(".t & group1.opt & ")".t

parser.add_infix_mix "Pow-Base", "^", "^".t & "Pow".e

parser.add_infix_mix "Lambda", "=>", "=>".t & "Lambda".b

parser.add_prefix_mix "Statement", "while",
    ("while".t & "Statement".E & ":".tr & "Any".b).splice

parser.add_prefix_mix "Statement", "for",
    ("for".t & "Statement".E & "in".t & "Statement".E & ":".tr & "Any".b).splice

parser.add_prefix_mix "Statement", "case", 
    "case".t & "Statement".E.opt &
    ("$CNT".tr.opt & "of".t & "Statement".E & ":".tr & "Any".b).plus.splice

parser.add_prefix_mix "Statement", "if", splice(
    "if".t & "Statement".E & ":".tr & "Any".b &
    ("$CNT".tr.opt & "elif".t & "Statement".E & ":".tr & "Any".b).star &
    ("$CNT".tr.opt & "else".t & ":".tr & "Any".b).opt
)

let cmp_operator = "==".ts | "!=".ts | "<".ts | "<=".ts | ">".ts | ">=".ts
for token in ["==", "!=", ">", ">=", "<", "<="]:
    parser.add_infix_mix "Cmp", token, "compare", (cmp_operator & "Cmp".E).splice.plus.splice
