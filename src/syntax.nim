import options, sets, tables, strutils, strformat
import parse, common/syntaxrule
import common/exp

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

func tr(x: string): SyntaxRule = tok_rule(x, raw=true, save=false)

func ts(x: string): SyntaxRule = tok_rule(x, save=true)

func t(x: string): SyntaxRule = tok_rule(x)

func e(x: string): SyntaxRule = exp_rule(x, StrongerEqual)

func E(x: string): SyntaxRule = exp_rule(x, StrongerThan)

func I(): SyntaxRule =
    let stat_sep = (";".tr | "$CNT".tr).named("Stmt-Sep")
    let rule = "$IND".tr & "Any".e.list(stat_sep.plus).with_op("block").opt & stat_sep.star & "$DED".tr
    rule.named("Block")

func b(group: string): SyntaxRule = (I() | group.e).named(fmt"Block({group})")

#func B(group: string): SyntaxRule = (I() | group.E).named(fmt"(Block({group}))")

#
# Parser definition
#

# TODO: evaluate this during compile-time

var parser* = Parser()

# operator group definitions
parser.add_groups "Comma Semicolon Statement Group Lambda-Type Apply Annotation Pow Pow-Base Mul Add Inverse"
parser.add_groups "Use As Member Not And Or Xor Cmp Lambda Definition Assignment Typing Set-Type Prefix-Type Variable-Modifier"

# oprerator group order definitions
parser.add_order "Apply > Group > Pow-Base > Inverse > Pow > Mul > Add > As > Assignment Definition"
parser.add_order "Apply > Group > Cmp Not > And Or Xor > Statement > Lambda > Assignment Definition"
parser.add_order "Add Mul Inverse > Cmp > Lambda"
parser.add_order "Group > Prefix-Type > Set-Type > Lambda-Type > Comma > Typing > Assignment Definition"
parser.add_order "Lambda-Type Apply > Set-Type > Lambda"
parser.add_order "Annotation > Definition Typing Lambda Lambda-Type"
parser.add_order "Member > Annotation"
parser.add_order "Apply > Typing"
parser.add_order "Member Typing > Statement Definition"
parser.add_order "Variable-Modifier > Typing Definition Apply"
parser.add_order "And > Or"
parser.add_order "Apply Group Cmp And Or Not Mul As > Statement"
parser.add_order "Member > Not Add Mul And Or Xor Cmp Lambda Apply Assignment"
parser.add_order "Mul > Lambda"
parser.add_order "Group > Comma > Assignment Definition Typing > Semicolon"
parser.add_order "Group Apply > Lambda-Type > Typing Lambda Definition"
parser.add_order "Definition Typing Group Apply > Use"

# non-assocative infix operators
parser.add_infix_none "As", "as", "??", "in"

# left-associative infix operators
parser.add_infix_left "Member", "."
parser.add_infix_left "Typing", ":"
parser.add_infix_left "Add", "+", "-"
parser.add_infix_left "Mul", "*", "/", "mod", "div"
parser.add_infix_left "And", "and"
parser.add_infix_left "Or", "or"
parser.add_infix_left "Xor", "xor"
parser.add_infix "Set-Type", "|", fun="Union", left_assoc=StrongerThan
parser.add_infix "Set-Type", "&", fun="Inter", left_assoc=StrongerThan

# right-associative infix operators
parser.add_infix_right "Assignment", ":=", "+=", "-=", "*=", "/="
parser.add_infix_right "Lambda-Type", "->"

# non-associative prefix operators
parser.add_prefix_none "Apply", "$", "$$"
parser.add_prefix_none "Not", "not"
parser.add_prefix_none "Statement", "assert", "return"
parser.add_prefix_none "Use", "use"
parser.add_prefix_none "Variable-Modifier", "opaque"
parser.add_prefix "Inverse", "-", fun="inv"

# associative prefix operators
parser.add_prefix_left "Prefix-Type", "?", ".."
parser.add_prefix_left "Member", ".", "*"

func loose_list(rule, sep: SyntaxRule): SyntaxRule =
    rule.list(sep & "$CNT".tr.star)

func group(): SyntaxRule =
    (("Any".E.plus.list((",".t | "$CNT".tr) & "$CNT".tr.star) & ",".opt).loose_list(";".t) & ";".opt).named("Group(';' | ',' | $WS)")

let slice = (("Any".e.opt & ":".ts & "Any".e.opt) | "Any".e).named("slice")

parser.add_infix_mix "Comma", ",", ((",".t & "Comma".E).splice.star.splice & ",".opt).splice

parser.add_prefix_mix "Group", "(", "(_)", "(".t & group().opt & ")".t

parser.add_prefix_mix "Group", "[", "[_]", "[".t & group().opt & "]".t

parser.add_infix_mix "Apply", "[", "[]", ("[".t & slice.list(",") & ",".opt & "]".t).splice

parser.add_infix_mix "Apply", "(", "()", "(".t & group().opt & ")".t

parser.add_prefix_mix "Annotation", "@", splice("@".t & "Annotation".E & ("(".t & group().opt & ")".t).opt & ("$CNT".tr.opt & "Any".E).opt)

parser.add_infix_mix "Pow-Base", "^", "^".t & "Pow".e

parser.add_infix_mix "Definition", "=", "=".t & "Definition".b

parser.add_infix_mix "Lambda", "=>", "=>".t & "Lambda".b

#parser.add_prefix_mix "Statement", "quote", "quote".t & "Any".b

parser.add_prefix_mix "Statement", "break", "break".t

parser.add_prefix_mix "Statement", "while",
    ("while".t & "Statement".E & ":".opt & "Any".b).splice

parser.add_prefix_mix "Statement", "for",
    ("for".t & "Statement".E & ":".opt & "Any".b).splice

parser.add_prefix_mix "Statement", "case", splice(
    "case".t & "Statement".E.opt &
    ("$CNT".tr.opt & "of".tr & "Statement".E & ":".opt & "Any".b).plus
)

parser.add_prefix_mix "Statement", "if", splice(
    "if".t & "Statement".E & ":".opt & "Any".b &
    ("$CNT".tr.opt & "elif".tr & "Statement".E & ":".opt & "Any".b).star &
    ("$CNT".tr.opt & "else".tr & ":".opt & "Any".b).opt
)

for token in ["test", "xtest"]:
    parser.add_prefix_mix "Statement", token,
        splice(token.t & tok_rule("", tag=some(aStr), save=true) & ":".opt & "Any".b)

let cmp_operator = "==".ts | "!=".ts | "<".ts | "<=".ts | ">".ts | ">=".ts
for token in ["==", "!=", ">", ">=", "<", "<="]:
    parser.add_infix_mix "Cmp", token, "compare", (cmp_operator & "Cmp".E).splice.plus.splice
