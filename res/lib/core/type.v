U8  : Type
U64 : Type
I64 : Type
F64 : Type

true  = opaque 1
false = opaque 0
none  = opaque 0


Nat : Type = set(zero) | succ
zero : Nat = opaque 0
succ : Nat -> Nat

plus = (x y : Nat) -> Nat =>
	match (x, y)
		(zero, n) => n
		(succ(m), n) => succ(plus(m, n))

true-alias  = true
true-unique = opaque true
assert true-alias = true
assert not true-unique = true
assert not true-unique = true-unique

a = unique b

unique b != unique b

Point = {I32, I32, I32}
Color = {I32, I32, I32}
Point == Color

Point = unique {I32, I32, I32}
Color = unique {I32, I32, I32}

Unique = (a: Type) => {id: UniqueId, value: a}
true  = Unique(id: 666, value: 1)
false = Unique(id: 667, value: 0)
true != unique 1





x = (1, 2, 3)
assert x as Point == x as Point
assert x as Color == x as Color
assert is-error(x as Point == x as Color)

(1, 2, 3) as Point1
(1, 2, 3) as Point2





b = unique c
a = unique b
assert not a = unique c


x = x mod 2

x = y -> y = x
x = y = z
x = U(y)

x = U(x)



assert type-of(true) == Unique(Int)

Handle = {handle: Size, mode: U8}
Ptr = opaque (type: Type) => Size
Mut = Ptr

true + 1 == 2

A2 = A
unique B = A2
B2 = B

assert A === B
assert C !== B


Mut(Int) == Ptr(Int)

unique Mut = unveil(Ptr)
unique Imm = unveil(Mut)

assert Ptr == Ptr
assert Ptr != Mut
assert forall(a: Type, Ptr(a) != Mut(a))


Color = (
	opaque red = 0xFF0000
	opaque grn = 0x00FF00
	opaque blu = 0x0000FF
	Hex = {code: U8}
	Color = red | grn | blu | Hex
)

reveal
unveil
unwrap
unpack

Color = @unveil(.red)



Handle is Type

String-Literal : Type
Number-Literal : Type

Size  : Opaque(Type) = opaque U64
Int   : Opaque(Type) = opaque I64
Float : Opaque(Type) = opaque F64

Any   = Union()
Never = Intersection()
Unit  = {}

unique f = (x: Int) => x

x = 2
unique y = x
assert x == x
assert y == y
assert x != y

Symbol = {id: Id}
Opaque = {id: Id, type: Type, value: type}

true.id

{id: Size, type: Int, value: 0}

`==` (x y: Opaque) => x.id == y.id

x = 1
y = unique x
z = y

x == 1 and x == x and x != y and x != z
y != 1 and y != x and y == y and y == z
z != 1 and z != x and z == y and z == z

y != x and y != 1
z 
y != 1
z == y
z != x
z != 1



# Comparison of opaque values 
# 1. x == x
# 2. x != unique x
# 3. f(x1, ..., xn) == g(x1, ..., xn) if 
# 3. f(x1, ..., xn) == f(x1, ..., xn), where f = unique g

# forall xi : Ti, f : Unique( (Ti) -> R ) . f(xi) == f(xi)
# 1. x == x, where x is opaque
# 2. f(x1, ..., xn) == f(y1, ..., yn), where f is opaque and xi == yi
# 


type-of = (x: B) => B

id = (x: A) => x

Bool = true | false

Tril = true | false | none

Option  = (x: A) => (A | none)

Pointer = (x: A) => Opaque(Size)

Mutable = opaque Pointer

Immutable = opaque Pointer

`==` : (x y: A) -> Bool

`!=` : (x y: A) -> Bool => not x == y

`===` : (x y: A) -> Bool

`!==` = (x y: A) -> Bool => not x === y

`not` = (x: Bool)   -> Bool => if x do false else true

`and` = (x y: Bool) -> Bool => if x do y else false

`or`  = (x y: Bool) -> Bool => if x do true else y

`xor` = (x y: Bool) -> Bool => x != y

`?` = Optional

`mut` = Mutable

`imm` = Immutable

`??` = (it: ?A, default: A) -> A =>
	if it == none do default else it

`*` : (x: mut A | imm A) -> A

`&` = (x: Type | A) -> if x is Type do Type else Pointer(x) =>
	if x is Type do Pointer(x) else address(x)

allocate : (A: Type; count: Size = 1, fill: ?A = none, stack = false) -> &A

free : (pointer: &mut A) -> Unit

copy : (to: &mut A, from: &A; count: Size = 1) -> Unit

move : (to: &mut A, from: &mut A) -> Unit

offset : (it: &A, bytes: Size) -> &A

value : (src: &A) -> A

address : (x: A) -> &A

