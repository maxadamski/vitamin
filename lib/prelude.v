
Type : Type
Has-Prelude : Type

Num-Literal, Str-Literal, List-Literal : Type
U8, I8, U64, I64 : Type
Byte = U8
Size = U64
Int = I64
Atom, Term, Expr, None : Type
Arguments : (x: Type) -> Type
type-of : (expr: quoted(Expr)) -> Type = __builtin__("type-of")
Unit = Record()
Union : (types: variadic(Type)) -> Type = __builtin__("Union")
Inter : (types: variadic(Type)) -> Type = __builtin__("Inter")
Any = Inter()
Never = Union()
`test` : (name: Str-Literal, body: quoted(Expr)) -> Unit = __builtin__("test")
`xtest` : (name: Str-Literal, body: quoted(Expr)) -> Unit = __builtin__("xtest")
`assert` : (cond: quoted(Expr)) -> Unit = __builtin__("assert")
str-r = (x: Str-Literal) => x
num-u8  : (x: Num-Literal) -> U8 = __builtin__("num-u8")
num-i8  : (x: Num-Literal) -> I8 = __builtin__("num-i8")
num-u64 : (x: Num-Literal) -> U64 = __builtin__("num-u64")
num-i64 : (x: Num-Literal) -> I64 = __builtin__("num-i64")
print : (xs: variadic(Any), sep = ' ', end = '\n') -> Unit = __builtin__("print")
opaque Bool = Byte
false = 0u8 as Bool
true = 1u8 as Bool
none : None
Expr = Union(Atom, Term)