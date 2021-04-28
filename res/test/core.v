## Tests of core functionality (run without prelude)

Term : Type
Atom : Type
Expr = Term | Atom

I64 : Type
Str : Type

### `Type` built-in and definitions

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


### Assumptions

I64 : Type

# assumed equality
assert I64 == I64

# assumed type
assert type-of(I64) == Type

I64-Alias = I64

# assumed alias equality
assert I64 == I64-Alias

Size = opaque I64
Int = opaque I64

# type-of(opaque x) is by definition type-of(x)
assert type-of(Size) == Type
assert type-of(Int) == Type

# each opaque value is unique
assert Size != Int

# opaque equality
assert Size != I64
assert unwrap(Size) == I64
assert unwrap(Int) == I64
assert unwrap(Size) == unwrap(Int)


### Integer literals

forty-two = 42

# type of literal
assert type-of(42) == I64
assert type-of(forty-two) == I64


### Opaque values

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

# opaque breaks transitivity
assert true != 1
assert false != 0
assert none != 0


### Value Sets

red = Symbol(red)
grn = Symbol(grn)
blu = Symbol(blu)

assert type-of(red) == Set(red)
assert type-of(red as Set(red, grn, blu)) == Set(red, grn, blu)
assert type-of(red as Set(red, grn)) != Set(grn, blu)


### Unions and Intersections

Any = Union()
Never = Inter()

# type of set types
assert type-of(Any) == Type
assert type-of(Never) == Type

#assert (Set(red, grn) | Set(red, blu)) == Set(red, grn, blu)
#assert (Set(red, grn) & Set(red, blu)) == Set(red)


### Records

Unit = Record()
unit = ()

assert Unit == Record()
assert unit == ()
assert type-of(Unit) == Type
assert type-of(unit) == Unit
assert type-of((x=Unit)) == Record(x: Type)

Single = Record(x: Type)
assert type-of(Single) == Type
assert Single == Record(x: Type)
assert type-of((x=Unit)) == Single

Double = Record(x: Type, y: I64)
assert type-of(Double) == Type
assert Double == Record(x: Type, y: I64)
assert Double == Record(y: I64, x: Type)
assert type-of((x=Unit, y=42)) == Double
assert type-of((y=42, x=Unit)) == Double


### Casts

assert type-of(Type as Any) == Any
assert type-of(true as Any) == Any
assert type-of((true as Any) as Any) == Any
assert type-of((true as Any) as Bool) == Bool


### Opaque functions

x : Type
y : Type

Pointer = opaque (a: Type) => Size

assert Pointer(x) != Size
assert Pointer(x) != Pointer(y)
assert Pointer(x) == Pointer(x)
assert unwrap(Pointer(x)) == Size
assert unwrap(Pointer(y)) == Size
assert unwrap(Pointer(x)) == unwrap(Pointer(y))


### Strings

Ptr = opaque (a: Type) => Size
Mut = opaque (a: Type) => a
Imm = opaque (a: Type) => a

#s = "hello, world"
#print(deref(s as Size, 0))
#print(deref(s as Size, 1))
#print(deref(s as Size, 2))
