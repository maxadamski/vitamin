
Enum = (fields: [{Str, ?Expr}]):
	for name, value in fields:
		quote $name : $value

#parse = (tokens: [Atom]) -> ParseResult|Error(ParseError) =>


EExpr = (a: Type) => Variant(
	EBool  : (x: Bool) -> EExpr(Bool)
	EInt   : (x: Int) -> EExpr(Int)
	EEqual : (x y: EExpr(Int)) -> EExpr(Bool)
)

EExpr  = (a: Type) -> Type => EBool | EInt | EEqual
EBool  : (x: Bool) -> EExpr(Bool) 
EInt   : (x: Int) -> EExpr(Int)
EEqual : (x y: EExpr(Int)) -> EExpr(Bool)

bool, int, equal = generate-symbols(3)
bool = symbol('bool')
EExpr = Record(tag: Set(bool, int, equal),  )

eval = (a: Type = _, x: Expr(a)) -> a =>
	case x
	of EBool(x) | EInt(x): x
	of EEqual(x, y): eval(x) == eval(y)

page-load = unique-symbol()
page-unload = unique-symbol()
Key-Press = unique U8
Paste = unique Str
Click = unique Record(x y: I64)
Web-Event = Set(page-load, page_unload) | Key-Press | Paste | Click

get-key-event = () -> Key-Press =>
	8 as Key-Press


Literal : (Int) -> Term Int
Term = unique (a: Type) => Literal(a)