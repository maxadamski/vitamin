## Tests of core language functionality

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
Any = Inter()
Never = Union()
Unit = Record()
eval : (e: Expr) -> type-of(e)
Lazy : (a: Type) -> Type
`as` : (x: Quoted(Expr), y: Type) -> y
Bool : Type
None : Type
none : None
`test` : (name: Quoted(Atom), body: Quoted(Expr)) -> Unit
`xtest` : (name: Quoted(Atom), body: Quoted(Expr)) -> Unit
`assert` : (cond: Quoted(Expr)) -> Unit
`==` : (lhs rhs: Quoted(Expr)) -> Bool
compare : (expr: Quoted(Expr)) -> Bool
`quote` : (expr: Quoted(Expr)) -> Expr
gensym : () -> Atom

assert error(Has-Prelude) # run this file without prelude (-P option)

#
# Variables
#

test "variable is equal to itself by unification"
    A : Type
    x : A
    assert x == x

test "variable is equal to itself by definition"
    A : Type
    x : A
    y : A
    y = x
    assert x == y

test "variables with different names are not syntactically equal"
    T : Type
    x : T
    y : T
    assert x != y

test "variables with different names and incompatible types are not syntactically or definitionally equal"
    A : Type
    B : Type
    x : A
    y : B
    assert x != y

test "definitional equality of variable types"
    A : Type
    B : Type
    x : A
    y = x
    z : B
    assert type-of(x) == type-of(x)
    assert type-of(x) == type-of(y)
    assert type-of(x) != type-of(z)
    assert type-of(y) != type-of(z)
#
# Simple functions
#

test "monomorphic identity function with defined argument"
    id = (x: Type) => x
    assert id(Type) == Type

test "monomorphic identity function with assumed argument"
    id = (x: Type) => x
    A : Type
    assert id(A) != A
    assert id(A) == id(A)

test "function type equality"
    A = (x: Type) -> Type
    B = (x: Bool) -> Type
    assert A == A
    assert A != B

test "function types with different parameter labels are not equal"
    A = (x: Type) -> Type
    B = (y: Type) -> Type
    assert A != B

#
# Unique values
#

test "unique value is not equal to its source value"
    A : Type
    x : A
    y = unique(x)
    assert x != y

test "type of unique value is equal to the type of its source value"
    A : Type
    x : A
    y = unique(x)
    assert type-of(x) == type-of(y)

test "unique value is equal to its source value after unwrapping"
    A : Type
    x : A
    y = unique(x)
    assert x == unwrap(y)

test "unique value is not a subtype of the source value"
    A : Type
    B = unique(A)
    assert not is-subtype(A, B)

test "can explicitly coerce to unique type"
    A : Type
    B = unique(A)
    assert type-of(B) == Type
    x : A
    y = x as B
    assert type-of(y) == B

test "can't implicly coerce to unique type"
    A : Type
    B = unique(A)
    assert type-of(B) == Type
    x : A
    assert error(y : B = x)

test "unique function breaks definitional equality"
    f = (x: Type) => x
    g = unique(f)
    h = g
    a = Type
    assert f(a) == a
    assert f(a) != g(a)
    assert g(a) == h(a)

test "unique function result can be unwrapped"
    f = (x: Type) => x
    g = unique(f)
    h = g
    a : Type
    assert f(a) == unwrap(g)(a)

test "unwrapping unique function result is the same as calling a unique function after unwrappnig"
    f = (x: Type) => x
    g = unique(f)
    a : Type
    assert unwrap(g(a)) == unwrap(g)(a)

test "unique value unwrapping"
    A : Type
    P = unique(A)
    Q = unique(A)
    assert unwrap(P) == A
    assert unwrap(Q) == A
    assert unwrap(P) == unwrap(Q)

test "unique functions"
    x = 1
    y = 2
    Ptr = (a: Int) -> Type => Size
    P = unique(Ptr)
    assert P(x) != Size
    assert P(y) != Size
    assert P(x) == P(x)
    assert P(x) != P(y)
    assert unwrap(P(x)) == Size
    assert unwrap(P(y)) == Size
    assert unwrap(P(x)) == unwrap(P(x))
    assert unwrap(P(x)) == unwrap(P(y))

#
# Type coertions
#

test "type upcast to Any"
    assert type-of(Type as Any) == Any

test "type upcast is idempotent"
    assert type-of((true as Any) as Any) == Any

test "type upcast is invertible"
    assert type-of((true as Any) as Bool) == Bool


#
# Union and intersection types
#

test "type union laws"
    A, B, C : Type
    assert type-of(Never) == Type
    assert Union(A) == A
    assert (A | Any) == Any
    assert (A | Never) == A
    assert (A | A) == A # simplification
    assert (A | B) == (B | A) # commutativity
    assert (A | (B | C)) == ((A | B) | C) # associativity
    assert (A | (B | C)) == ((A | B) | (A | C)) # distributivity

test "type intersection laws"
    A, B, C, D : Type
    assert type-of(Any) == Type
    assert Inter(A) == A
    assert (A & Any) == A
    assert (A & Never) == Never
    assert (A & A) == A # simplification
    assert (A & B) == (B & A) # commutativity
    assert (A & (B & C)) == ((A & B) & C) # associativity
    assert (A & (B & C)) == ((A & B) & (A & C)) # distributivity
    assert (A & (B | C)) == ((A & B) | (A & C)) # distributivity over union
    assert (A & B & (C | D)) == ((A & B & C) | (A & B & D)) # distributivity over union

#
# Gensym
#

test "gensym produces unique Atoms"
    assert gensym() != gensym()

#
# Literals
#

test "integer literals"
    forty-two = 42
    assert type-of(42) == I64
    assert type-of(forty-two) == I64

#
# Syntax sugar
#

test "parenthesised expression"
    A : Type
    assert (A) == A

test "label-less function parameter"
    A = Type -> Type
    B = (_: Type) -> Type
    assert A == B

test "multiple assumption shorthand syntax"
    A, B, C : Type
    assert type-of(A) == Type
    assert type-of(B) == Type
    assert type-of(C) == Type

test "short named function syntax"
    nullary2 = () -> None => none
    nullary1() -> None = none
    assert type-of(nullary1) == type-of(nullary2)

    unary2 = (x: None) -> None => x
    unary1(x: None) -> None = x
    assert type-of(unary1) == type-of(unary2)

    multiline1(x y: Bool) -> Any =
        print("whatever")
        print("whenever")

    multiline2 = (x y: Bool) -> Any =>
        print("whatever")
        print("whenever")

    assert type-of(multiline1) == type-of(multiline2)

test "short named function syntax with inferred return"
    nullary1() = none
    nullary2 = () => none
    assert type-of(nullary1) == type-of(nullary2)

    unary1(x: None) = x
    unary2 = (x: None) => x
    assert type-of(unary1) == type-of(unary2)

    multiline1(x y: Bool) =
        print("whatever")
        print("whenever")

    multiline2 = (x y: Bool) =>
        print("whatever")
        print("whenever")

    assert type-of(multiline1) == type-of(multiline2)

#
# Booleans
#

Bool = unique(Int)
true = 1 as Bool
false = 0 as Bool
# FIXME: Lazy should make binary operators short-circuit (right now it does nothing)
`and`(x y: Lazy(Bool)) -> Bool = case x of true y of false false
`or`(x y: Lazy(Bool)) -> Bool = case x of true true of false y
`not`(x: Bool) -> Bool = case x of true false of false true

test "bool operators"
    assert (not true) == false
    assert (not false) == true

    assert (true and true) == true
    assert (false and true) == false
    assert (true and false) == false
    assert (false and false) == false

    assert (true or true) == true
    assert (false or true) == true
    assert (true or false) == true
    assert (false or false) == false

#
# Records
#

test "record field types are normalized"
    Also-Type = Type
    assert Record(x: Type) == Record(x: Also-Type)

test "single row records"
    Single = Record(x: Type)
    assert type-of(Single) == Type
    assert type-of((x=Unit)) == Single

test "unit records"
    assert Unit == Record()
    assert type-of(Unit) == Type
    assert type-of(()) == Unit
    assert type-of((x=Unit)) == Record(x: Type)
    assert type-of((x=())) == Record(x: Unit)

test "dependent records models a disjoint union"
    L, R : Type
    r : R
    l : L
    Data = (x: Bool) => case x of true R of false L
    assert Data(true) == R
    assert Data(false) == L
    Either = Record(t: Bool, data: Data(t))
    either-r : Either = (t=true, data=r)
    either-l : Either = (t=false, data=l)
    assert error(either-l : Either = (t=false, data=r))
    assert error(either-r : Either = (t=true, data=l))

xtest "record constructor"
    R = Record()
    assert R() == constructor-of(R)()

test "record row shorthand syntax"
    A, B, C : Type
    R1 = Record(a: A, b: B, c: B, d: C)
    R2 = Record(a: A, b c: B, d: C)
    assert R1 == R2

test "row order doesn't affect record type equality"
    assert Record(x: Type, y: I64) == Record(y: I64, x: Type)
    assert type-of((x=Unit, y=42)) == type-of((y=42, x=Unit))

#
# Sets
#

Set : (a: Type) -> Type
#set : (xs: Varargs(Quoted(Expr))) -> unify-types(map(infer-type, xs))

xtest "type of a set is the union of the types of its values"
	Cat, Dog : Type
	lily, simba : Cat
	buddy : Dog
	assert type-of(set(lily, simba, buddy)) == Set(Cat|Dog)

xtest "type of a set of homogeneous values"
	Color : Type
	red, grn, blu : Color
	assert type-of(set(red, grn, blu)) == Set(Color)

xtest "subsets of set"
	a, b, c : Type
	abc = set(a, b, c)
	assert is-subset(set(), abc)
	assert is-subset(set(a), abc)
	assert is-subset(set(b), abc)
	assert is-subset(set(c), abc)
	assert is-subset(set(a, b), abc)
	assert is-subset(set(a, c), abc)
	assert is-subset(set(b, c), abc)

xtest "improper subset of set"
	a, b, c : Type
	abc = set(a, b, c)
	assert is-subset(set(a, b, c), abc)

xtest "sets are invariant to element order"
    a, b, c : Type
    assert set(a, b, c) == set(b, c, a)

xtest "sets merge duplicate items"
    a, b : Type
    assert set(a, a, b) == set(a, b)

xtest "set union"
    red, grn, blu : Type
    A : Type
    assert union(set(red, grn), set(red, blu)) == set(red, grn, blu)

xtest "set intersection"
    red, grn, blu : Type
    A : Type
    assert intersection(set(red, grn), set(red, blu)) == set(red)
