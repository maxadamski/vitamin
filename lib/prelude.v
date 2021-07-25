
Has-Prelude : Type

Num-Literal : Type
I64, U64, Str : Type
Size = U64
Int = I64
Quoted : (x: Type) -> Type
Opaque : (x: Type) -> Type
Expand : (x: Type) -> Type
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
`as` : (x: Quoted(Expr), y: Type) -> y
Bool = unique(Int)
true = 1 as Bool
false = 0 as Bool
None = unique(Int)
none = 0 as None
Array : (type: Type) -> Type
Any = Inter()
Never = Union()
Unit = Record()
eval : (e: Expr) -> type-of(e)
Lazy : (a: Type) -> Type
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
