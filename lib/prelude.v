
{`:` Atom Type}
{`:` Term Type}
#define(Expr, Term | Atom)
{define Expr {Union Term Atom}}

Lambda : (params result: Quoted(Expr)) -> Type
Lazy : (x: Type) -> Type
Quoted : (x: Type) -> Type

record-aux : (values: Expr) -> Type
record : (values: Quoted(Expr)) -> record-aux(values)
`Record` : (fields: Quoted(Expr)) -> Type
`quote` : (expr: Quoted(Expr)) -> Expr
`gensym` : () -> Atom
`type-of` : (expr: Quoted(Expr)) -> Type

Any = Inter()
Never = Union()
Unit = Record()

`as` : (expr: Quoted(Expr), type: Type) -> type
`test` : (name: Quoted(Atom), body: Quoted(Expr)) -> Unit
`assert` : (cond: Quoted(Expr)) -> Unit

assert error(Has-Prelude) # run this file without prelude (-P option)

I64 : Type
U64 : Type
Str : Type

Size = U64
Int = I64

true = Symbol(true)
false = Symbol(false)
none = Symbol(none)
Bool = Set(true, false)
None = Set(none)

`==` : (lhs rhs : Quoted(Expr)) -> Bool
