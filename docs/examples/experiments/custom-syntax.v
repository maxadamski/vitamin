
Syntax = Variant(
	seqence(rules: [Syntax]),
	either(rules: [Syntax]),
	repeat(min max: ?Int = none, rule: Syntax),
	param(name: String, type: Type),
	token(value: String),
)

# expr = (name: String) => param(name, Expr)
# maybe = (rule: Syntax) => repeat(min=0, max=1, rule)
# some = (rule: Syntax) => repeat(min=0, max=none, rule)
# many = (rule: Syntax) => repeat(min=1, max=none, rule)
# some-sep = (rule: Syntax, sep: String) => maybe(many-sep(rule, token(sep)))
# many-sep = (rule: Syntax, sep: String) => sequence([rule, some(sequence([token(sep), rule]))])
# 
# match-expr = sequence([
# 	token('match'), expr('value'), token('$IND'),
# 	many(sequence([ expr('cond'), token('=>'), expr('branch') ]))
# 	token('$DED'),
# ])
# 
# call-expr = sequence([
# 	token('func'), token('('), some-sep(expr('arg'), ','), token(')')
# ])

block-expr = g"'do' IND exprs DED | IND exprs DED | 'do' exprs"
if-expr    = g"'if' cond1 {block} ( 'elif' cond2 {block} )* ( 'else' {block} )?"
while-expr = g"'while' cond {block}"
param      = g"name (':' type)? ('=' default)?"
func-expr  = g"'(' ({param} ','),* ( ';' ({param} ','),* )? ','? ')' ( '->' expr )? '=>' {block}"
match-expr = g"'match' value IND ( condition '=>' branch )+ DED"
call-expr  = g"func '(' (expr ','),* ','? ')'"

add-group('Add-Group')
add-group('Mul-Group')
add-precedence('Mul-Group', '>', 'Add-Group')

syntax Add
	rule = g"lhs '+' rhs"
	group = Add-Group
	lhs > Add-Group
	rhs > Add-Group


add-expr   = g"x '+' y"
add-expr.group = add-group
add-expr.add-constraint("x > y")

add-expr   = g"x '==' y"
add-expr.add-constraint("x == y")

use Vitamin

Vitamin.parser.add-expression(call-expr, (func: Expr, expr: [Expr]) => ...)

f(a: Allowed-As-A, b: Allowed-As-B)
