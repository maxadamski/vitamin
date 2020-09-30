U8  : Type
U64 : Type
I64 : Type
F64 : Type

Size  = unique U64
Int   = unique I64
Float = unique F64

String-Literal : Type
Number-Literal : Type

Any   = @inter()
Never = @union()
Unit  = {}

type-of = (x: A) => A

id = (x: A) => x

#None = [| none |]
#use None
#Bool = [| true, false |]
#use Bool
Bool : Type
None : Type

Optional = (x: Type) => x | None

Mutable-Pointer = unique (x: Type) => Size
Pointer = unique (x: Type) => Size

#`not` = (x: Bool) -> Bool => if x == true do false else true
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

# @extern
# @unique
# @opaque
# @export
# @import
# @macro
# @pure
# @lazy
# @load

#Variant = @enum(foo, bar(bool: Bool))
#Struct  = @data(name: String-Literal, age: Number-Literal)

#@union = @extern (x: ..Type) -> Type
#@inter = @extern (x: ..Type) -> Type
#@tuple = @extern (x: ..Type) -> Type

# Func-Row  = { name: String, type: Type, value: ?type }
# Data-Row  = { name: String, type: Type }
# Data-Type = { rows: [Row], rest: ?Data-Type }
# Enum-Type = { rows: [Row], rest: ?Enum-Type }

