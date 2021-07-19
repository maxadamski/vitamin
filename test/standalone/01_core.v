## Tests of core language functionality

Num-Literal : Type
I64, U64, Str : Type
Size = U64
Int = I64
Lazy : (x: Type) -> Type
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
`quote` : (expr: Quoted(Expr)) -> Expr
gensym : () -> Atom
type-of : (expr: Quoted(Expr)) -> Type
level-of : (type: Type) -> Int
Symbol-Type : Type
Symbol : (atom: Quoted(Atom)) -> Symbol-Type
Array : (type: Type) -> Type
Any = Inter()
Never = Union()
Unit = Record()
true = Symbol(true)
false = Symbol(false)
none = Symbol(none)
Bool = Set(true, false)
None = Set(none)
`test` : (name: Quoted(Atom), body: Quoted(Expr)) -> Unit
`xtest` : (name: Quoted(Atom), body: Quoted(Expr)) -> Unit
`assert` : (cond: Quoted(Expr)) -> Unit
`==` : (lhs rhs: Quoted(Expr)) -> Bool
compare : (expr: Quoted(Expr)) -> Bool
`and`(x y: Lazy(Bool)) -> Bool = case x of true y of false false
`or`(x y: Lazy(Bool)) -> Bool = case x of true true of false y
`not`(x: Bool) -> Bool = case x of true false of false true

assert error(Has-Prelude) # run this file without prelude (-P option)

test "Variable identity"
    # identity
    assert Type == Type

    Test-A = Type
    Test-B = Type
    Test-C = Type

    # variable identity
    assert Test-A == Test-A

    # variable commutativity
    assert Test-A == Test-B
    assert Test-B == Test-A

    # variable transitivity
    assert Test-A == Test-B
    assert Test-B == Test-C
    assert Test-A == Test-C

test "Function type equality"
    assert ((x: Type) -> Type) == ((x: Type) -> Type)
    assert ((x: Type) -> Type) != ((y: Type) -> Type)
    assert ((x: Type) -> (y: Type) -> Type) == ((x: Type) -> (y: Type) -> Type)

test "Assumed variables"
    # assumed equality
    assert I64 == I64

    # assumed type
    assert type-of(I64) == Type

    I64-Alias = I64

    # assumed alias equality
    assert I64 == I64-Alias

test "Multiple assumption shorthand syntax"
    A, B, C : Type
    assert type-of(A) == Type
    assert type-of(B) == Type
    assert type-of(C) == Type

test "Unique values have different identities"
    A : Type
    P = Unique(A)
    Q = Unique(A)

    # type-of(opaque x) is by definition type-of(x)
    assert type-of(P) == type-of(A)
    assert type-of(Q) == type-of(A)

    # each opaque value is unique
    assert P != A
    assert Q != A
    assert P != Q

test "Unique functions"
    foo(x: Type) = x
    bar = Unique(foo)
    A = Type
    assert foo(A) == A
    assert error(bar(A))

test "Unique value unwrapping"
    A : Type
    P = Unique(A)
    Q = Unique(A)
    assert unwrap(P) == A
    assert unwrap(Q) == A
    assert unwrap(P) == unwrap(Q)

test "Integer literals"
    forty-two = 42

    # type of literal
    assert type-of(42) == I64
    assert type-of(forty-two) == I64

test "Unique values"
    My-Bool = Unique(Int)
    My-None = Unique(Int)

    true  = 1 as My-Bool
    false = 0 as My-Bool
    none  = 0 as My-None

    # cast identity
    assert true == true
    assert false == false
    assert none == none

    # cast type
    assert type-of(true) == My-Bool
    assert type-of(false) == My-Bool
    assert type-of(none) == My-None
    assert type-of(true) != Int
    assert type-of(false) != Int
    assert type-of(none) != Int

test "Value set types"
    red = Symbol(red)
    grn = Symbol(grn)
    blu = Symbol(blu)

    assert type-of(red) == Symbol-Type
    assert Set(red, red) == Set(red)
    assert Set(red, blu) != Set(red, grn)
    assert Set(red, grn, red) == Set(red, grn)
    assert Set(red, grn, blu) == Set(blu, grn, red)
    assert type-of(red as Set(red, grn, blu)) == Set(red, grn, blu)
    assert type-of(red as Set(red, grn)) != Set(grn, blu)

test "Type union laws"
    A, B, C : Type
    assert type-of(Never) == Type
    assert Union(A) == A
    assert (A | Any) == Any
    assert (A | Never) == A
    assert (A | A) == A # simplification
    assert (A | B) == (B | A) # commutativity
    assert (A | (B | C)) == ((A | B) | C) # associativity
    assert (A | (B | C)) == ((A | B) | (A | C)) # distributivity

test "Type intersection laws"
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

test "Union of value set types"
    red = Symbol(red)
    grn = Symbol(grn)
    blu = Symbol(blu)
    A : Type
    assert (Set(red, grn) | Set(red, blu)) == Set(red, grn, blu)
    assert (Set(red, grn) | (A | Set(red, blu))) == (Set(red, grn, blu) | A)

test "Intersection of value set types"
    red = Symbol(red)
    grn = Symbol(grn)
    blu = Symbol(blu)
    A : Type
    assert (Set(red, grn) & Set(red, blu)) == Set(red)
    assert (Set(red, grn) & (A & Set(red, blu))) == (Set(red) & A)

test "Unit records"
    unit = ()
    assert Unit == Record()
    assert unit == ()
    assert type-of(Unit) == Type
    assert type-of(unit) == Unit
    assert type-of((x=Unit)) == Record(x: Type)
    assert type-of((x=unit)) == Record(x: Unit)

test "Single row records"
    Single = Record(x: Type)
    assert type-of(Single) == Type
    assert Single == Record(x: Type)
    assert type-of((x=Unit)) == Single

test "Record row shorthand syntax"
    A, B, C : Type
    R1 = Record(a: A, b: B, c: B, d: C)
    R2 = Record(a: A, b c: B, d: C)
    assert R1 == R2

test "Row order doesn't affect record type equality"
    assert Record(x: Type, y: I64) == Record(y: I64, x: Type)
    assert type-of((x=Unit, y=42)) == type-of((y=42, x=Unit))

test "Type upcast to Any"
    assert type-of(Type as Any) == Any

test "Type upcast is idempotent"
    assert type-of((true as Any) as Any) == Any

test "Type upcast is invertible"
    assert type-of((true as Any) as Bool) == Bool

test "Opaque functions"
    x, y : Type
    Raw-Pointer = (a: Type) -> Opaque(Type) => Size
    assert Raw-Pointer(x) != Size
    assert Raw-Pointer(x) != Raw-Pointer(y)
    assert Raw-Pointer(x) == Raw-Pointer(x)
    assert unwrap(Raw-Pointer(x)) == Size
    assert unwrap(Raw-Pointer(y)) == Size
    assert unwrap(Raw-Pointer(x)) == unwrap(Raw-Pointer(y))

test "Bool operators"
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

    # TODO: fix short-circuiting

test "Short named function syntax"
    nullary2 = () -> None => none
    nullary1() -> None = none
    assert type-of(nullary1) == type-of(nullary2)

    unary2 = (x: None) -> None => x
    unary1(x: None) -> None = x
    assert type-of(unary1) == type-of(unary2)

    multiline1(x y: Bool) -> Bool =
        print("whatever")
        x and y

    multiline2 = (x y: Bool) -> Bool =>
        print("whatever")
        x and y

    assert type-of(multiline1) == type-of(multiline2)

test "Short named function syntax with inferred return"
    nullary1() = none
    nullary2 = () => none
    assert type-of(nullary1) == type-of(nullary2)

    unary1(x: None) = x
    unary2 = (x: None) => x
    assert type-of(unary1) == type-of(unary2)

    multiline1(x y: Bool) =
        print("whatever")
        x and y

    multiline2 = (x y: Bool) =>
        print("whatever")
        x and y

    assert type-of(multiline1) == type-of(multiline2)
