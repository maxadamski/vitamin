
Has-Prelude : Type
Num-Literal, Str-Literal, List-Literal : Type
U8, I8, U64, I64 : Type
Byte = U8
Size = U64
Int = I64
Arguments : (x: Type) -> Type
Expr, Atom, Term : Type
`=` : (pattern value: quoted(Expr)) -> expand(Expr)
`->` : (params result: quoted(Expr)) -> expand(Expr)
`=>` : (head body: quoted(Expr)) -> expand(Expr)
lambda-infer : (params result body: Expr) -> Type
lambda : (params result body: quoted(Expr)) -> lambda-infer(params, result, body)
Lambda : (params result: quoted(Expr)) -> Type
record-infer : (values: Expr) -> Type
record : (values: quoted(Expr)) -> record-infer(values)
type-of : (expr: quoted(Expr)) -> Type
level-of : (type: quoted(Expr)) -> Int
`Record` : (fields: variadic(quoted(Expr))) -> Type
Unit = Record()
Union, Inter : (types: variadic(Type)) -> Type
Any = Inter()
Never = Union()
Expr = Union(Atom, Term)
unwrap : (e: quoted(Expr)) -> type-of(e)
eval : (e: Expr) -> type-of(e)
#`as` : (x: quoted(Expr), y: Type) -> y
Bool : Type
None : Type
none : None
`test` : (name: Str-Literal, body: quoted(Expr)) -> Unit
`xtest` : (name: Str-Literal, body: quoted(Expr)) -> Unit
`assert` : (cond: quoted(Expr)) -> Unit
`==` : (lhs rhs: quoted(Expr)) -> Bool
compare : (expr: quoted(Expr)) -> Bool
`quote` : (expr: quoted(Expr)) -> Expr
str-r = (x: Str-Literal) => x
num-u8  : (x: Num-Literal) -> U8
num-i8  : (x: Num-Literal) -> I8
num-u64 : (x: Num-Literal) -> U64
num-i64 : (x: Num-Literal) -> I64
print : (xs: variadic(Any), sep = ' ', end = '\n') -> Unit
opaque Bool = Byte
true = 1u8 as Bool
false = 0u8 as Bool
`and` = (x y: Bool) -> Bool => case x of true y of false false
`or` = (x y: Bool) -> Bool => case x of true true of false y
`not` = (x: Bool) -> Bool => case x of true false of false true