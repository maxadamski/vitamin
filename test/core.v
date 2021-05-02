## Tests of core language functionality

Term : Type
Atom : Type
Expr = Term | Atom

assert error(Has-Prelude) # run this file without prelude (-P option)

I64 : Type
U64 : Type
Str : Type

Size = U64
Int = I64

Any = Union()
Never = Inter()
Unit = Record()
unit = ()

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

test "Assumed variables"
    # assumed equality
    assert I64 == I64

    # assumed type
    assert type-of(I64) == Type

    I64-Alias = I64

    # assumed alias equality
    assert I64 == I64-Alias

test "Opaque types"
    Size = opaque I64
    Int = opaque I64

    # type-of(opaque x) is by definition type-of(x)
    assert type-of(Size) == Type
    assert type-of(Int) == Type

    # each opaque value is unique
    assert Size != Int
    assert Size != I64
    assert unwrap(Size) == I64
    assert unwrap(Int) == I64
    assert unwrap(Size) == unwrap(Int)

test "Integer literals"
    forty-two = 42

    # type of literal
    assert type-of(42) == I64
    assert type-of(forty-two) == I64

test "Opaque values"
    Bool = opaque Int
    None = opaque Int

    true  = 1 as Bool
    false = 0 as Bool
    none  = 0 as None

    # cast identity
    assert true == true
    assert false == false
    assert none == none

    # cast type
    assert type-of(true) == Bool
    assert type-of(false) == Bool
    assert type-of(none) == None
    assert type-of(true) != Int
    assert type-of(false) != Int
    assert type-of(none) != Int

test "Set types"
    red = Symbol(red)
    grn = Symbol(grn)
    blu = Symbol(blu)

    assert type-of(red) == Set(red)
    assert type-of(red as Set(red, grn, blu)) == Set(red, grn, blu)
    assert type-of(red as Set(red, grn)) != Set(grn, blu)

test "Empty union"
    # type of set types
    assert type-of(Any) == Type

test "Empty intersection"
    assert type-of(Never) == Type

test "Union of set types"
    red = Symbol(red)
    grn = Symbol(grn)
    blu = Symbol(blu)
    assert (Set(red, grn) | Set(red, blu)) == Set(red, grn, blu)

test "Intersection of set types"
    red = Symbol(red)
    grn = Symbol(grn)
    blu = Symbol(blu)
    assert (Set(red, grn) & Set(red, blu)) == Set(red)

test "Unit records"
    assert Unit == Record()
    assert unit == ()
    assert type-of(Unit) == Type
    assert type-of(unit) == Unit
    assert type-of((x=Unit)) == Record(x: Type)

test "Records"
    Single = Record(x: Type)
    assert type-of(Single) == Type
    assert Single == Record(x: Type)
    assert type-of((x=Unit)) == Single

test "Records invariant to row order"
    Double = Record(x: Type, y: I64)
    assert type-of(Double) == Type
    assert Double == Record(x: Type, y: I64)
    assert Double == Record(y: I64, x: Type)
    assert type-of((x=Unit, y=42)) == Double
    assert type-of((y=42, x=Unit)) == Double

test "Upcast to Any"
    true = Symbol(true)
    assert type-of(Type as Any) == Any
    assert type-of(true as Any) == Any
    assert type-of((true as Any) as Any) == Any
    #assert type-of((true as Any) as Bool) == Bool

test "Opaque functions"
    x : Type
    y : Type

    Raw-Pointer = opaque (a: Type) => Size

    assert Raw-Pointer(x) != Size
    assert Raw-Pointer(x) != Raw-Pointer(y)
    assert Raw-Pointer(x) == Raw-Pointer(x)
    assert unwrap(Raw-Pointer(x)) == Size
    assert unwrap(Raw-Pointer(y)) == Size
    assert unwrap(Raw-Pointer(x)) == unwrap(Raw-Pointer(y))