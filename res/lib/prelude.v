U8  : Type
U64 : Type
I64 : Type
F64 : Type

true  = Unique()
false = Unique()
none  = Unique()

Bool = Union(true, false)
Tril = Union(none, Bool)

String-Literal : Type
Number-Literal : Type

Size  = Opaque(U64)
Int   = Opaque(I64)
Float = Opaque(F64)

Any   = Union()
Never = Intersection()
Unit  = Struct()

type-of = (x: B) => B
id = (x: A) => x

Pointer = (A: Type) => Size

use None = Enum(none)

use Bool = Enum(true, false)

assert type-of(id) == type-of(id)

# test known values have correct types
assert type-of(42) == I64
assert type-of(true) == Bool
assert type-of(false) == Bool
assert type-of(none) == None

# test type of known types is Universe(0)
assert type-of(Any) == Type
assert type-of(Never) == Type
assert type-of(Unit) == Type
assert type-of(Bool) == Type
assert type-of(None) == Type
assert type-of(Int) == Type
assert type-of(Size) == Type
assert type-of(Float) == Type
assert type-of(U8) == Type
assert type-of(I64) == Type
assert type-of(U64) == Type
assert type-of(F64) == Type

assert type-of(true) == Bool
#assert type-of(true as Any) == Any
#assert type-of((true as Any) as Bool) == Bool

# test data values have correct types
assert Unit == Struct()
assert type-of(()) == Struct()
assert type-of(Struct()) == Type
assert type-of((x=true)) == Struct(x: Bool)
assert type-of((x=true, y=false)) == Struct(x, y: Bool)
assert type-of((x=true, y=42)) == Struct(x: Bool, y: I64)
assert Int   != I64
assert Size  != U64
assert Float != F64

assert true == true
assert false == false
assert true != false

assert id(true) == true
assert id(false) == false
assert id(none) == none
assert id(42) == 42
assert id(()) == ()

# test data type fields are invariant to order
assert Struct(x: Bool, y: Bool) == Struct(y: Bool, x: Bool)

# test data type field type propagates backward in a group
assert Struct(x, y: Bool) == Struct(x: Bool, y: Bool)

assert Pointer(Bool) == Pointer(Bool)
assert Pointer(Bool) != Size
assert Pointer(Size) != Size


#Optional = (x: Type) => x | None

#`not` = (x: Bool) -> Bool => if x do false else true
#
#`and` = (x y: Bool) -> Bool => if x do y else false
#
#`or`  = (x y: Bool) -> Bool => if x do true else y
#
#`xor` = (x y: Bool) -> Bool => x != y
#
#`?` = Optional
#
#`mut` = Mutable
#
#`imm` = Immutable
#
#`??` = (it: ?A, default: A) -> A =>
#	if it is None do default else it
#
#use (
#	value : (x: mut A) -> A
#)
#
#use (
#	value : (x: imm A) -> A
#)
#
#`===` : (x y: A) -> Bool
#
#`!==` = (x y: A) -> Bool => not x === y

#Variant = @enum(foo, bar(bool: Bool))
#Struct  = @data(name: String-Literal, age: Number-Literal)

#@union = @extern (x: ..Type) -> Type
#@inter = @extern (x: ..Type) -> Type
#@tuple = @extern (x: ..Type) -> Type

# Func-Row  = { name: String, type: Type, value: ?type }
# Data-Row  = { name: String, type: Type }

# Arg  = (A: Type) => { name: String, value: A }
# Data = { head: Data-Row, tail: ?Data }
# data = (arg: Arg(A)) -> Data(to-data-row(arg))

# type-of(x: Data) = { 
# Enum = { rows: [Row], rest: ?Enum-Type }
