U8  : Type
U64 : Type
I64 : Type
F64 : Type

Bool : Type
None : Type

String-Literal : Type
Number-Literal : Type

Size  = unique U64
Int   = unique I64
Float = unique F64

Any   = inter-type()
Never = union-type()
Unit  = {}

type-of = (x: B) => B
id = (x: A) => x

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
assert Unit == {}
assert type-of(()) == {}
assert type-of({}) == Type
assert type-of((x=true)) == {x: Bool}
assert type-of((x=true, y=false)) == {x y: Bool}
assert type-of((x=true, y=42)) == {x: Bool, y: I64}
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
assert {x: Bool, y: Bool} == {y: Bool, x: Bool}

# test data type field type propagates backward in a group
assert {x y: Bool} == {x: Bool, y: Bool}

Pointer = unique (A: Type) => Size

assert Pointer(Bool) == Pointer(Bool)
assert Pointer(Bool) != Size
assert Pointer(Size) != Size

#None = [| none |]
#use None

#Bool = [| true, false |]
#use Bool

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
#

