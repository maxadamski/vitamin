
Has-Prelude : Type

Num-Literal, Str-Literal : Type
U8, I8, U64, I64 : Type
inv : (x: Num-Literal) -> Num-Literal
u8 : (x: Num-Literal) -> U8
i8 : (x: Num-Literal) -> I8
u64 : (x: Num-Literal) -> U64
i64 : (x: Num-Literal) -> I64
Size = U64
Int = I64
Quoted, Expand, Varargs : (x: Type) -> Type
`=` : (pattern value: Quoted(Expr)) -> Expand(Expr)
`->` : (params result: Quoted(Expr)) -> Expand(Expr)
`=>` : (head body: Quoted(Expr)) -> Expand(Expr)
lambda-infer : (params result body: Expr) -> Type
lambda : (params result body: Quoted(Expr)) -> lambda-infer(params, result, body)
Lambda : (params result: Quoted(Expr)) -> Type
record-infer : (values: Expr) -> Type
record : (values: Quoted(Expr)) -> record-infer(values)
`Record` : (fields: Quoted(Expr)) -> Type
type-of : (expr: Quoted(Expr)) -> Type
level-of : (type: Quoted(Expr)) -> Int
Any = Inter()
Never = Union()
Unit = Record()
eval : (e: Expr) -> type-of(e)
Lazy : (a: Type) -> Type
`as` : (x: Quoted(Expr), y: Type) -> y
Bool : Type = unique(Int)
true = 1 as Bool
false = 0 as Bool
None : Type
none : None
`test` : (name: Quoted(Atom), body: Quoted(Expr)) -> Unit
`xtest` : (name: Quoted(Atom), body: Quoted(Expr)) -> Unit
`assert` : (cond: Quoted(Expr)) -> Unit
`==` : (lhs rhs: Quoted(Expr)) -> Bool
compare : (expr: Quoted(Expr)) -> Bool
`quote` : (expr: Quoted(Expr)) -> Expr
gensym : () -> Atom
`and`(x y: Lazy(Bool)) -> Bool = case x of true y of false false
`or`(x y: Lazy(Bool)) -> Bool = case x of true true of false y
`not`(x: Bool) -> Bool = case x of true false of false true