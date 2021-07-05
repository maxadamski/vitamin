# style 1

EExpr = (a: Type) => Variant(
	EBool  : (x: Bool) -> EExpr(Bool)
	EInt   : (x: Int) -> EExpr(Int)
	EEqual : (x y: EExpr(Int)) -> EExpr(Bool)
)

# style 2

EExpr  = (a: Type) -> Type => EBool | EInt | EEqual
EBool  : (x: Bool) -> EExpr(Bool) 
EInt   : (x: Int) -> EExpr(Int)
EEqual : (x y: EExpr(Int)) -> EExpr(Bool)

eval(x: EExpr($a)) -> a =
	case x
	of EBool(x) | EInt(x):
		x
	of EEqual(x, y):
		eval(x) == eval(y)
