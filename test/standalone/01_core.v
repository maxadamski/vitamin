# Tests of core language functionality

# NOTE: Try to use ontly the most basic syntax sugar

Num-Literal, Str-Literal, List-Literal : Type
U8, I8, U64, I64 : Type
Byte = U8
Size = U64
Int = I64
Arguments : (x: Type) -> Type
`=` : (pattern value: quoted(Expr)) -> expand(Expr)
`->` : (params result: quoted(Expr)) -> expand(Expr)
`=>` : (head body: quoted(Expr)) -> expand(Expr)
lambda-infer : (params result body: Expr) -> Type
lambda : (params result body: quoted(Expr)) -> lambda-infer(params, result, body)
Lambda : (params result: quoted(Expr)) -> Type
record-infer : (values: Expr) -> Type
record : (values: quoted(Expr)) -> record-infer(values)
type-of : (expr: quoted(Expr)) -> Type
level-of : (type: quoted(Expr)) -> Int
`Record` : (fields: variadic(quoted(Expr))) -> Type
Unit = Record()
Union, Inter : (types: variadic(Type)) -> Type
Any = Inter()
Never = Union()
Atom, Term : Expr
Expr = Union(Atom, Term)
unwrap : (e: quoted(Expr)) -> type-of(e)
eval : (e: Expr) -> type-of(e)
#`as` : (x: quoted(Expr), y: Type) -> y
Bool : Type
None : Type
none : None
`test` : (name: Str-Literal, body: quoted(Expr)) -> Unit
`xtest` : (name: Str-Literal, body: quoted(Expr)) -> Unit
`assert` : (cond: quoted(Expr)) -> Unit
`==` : (lhs rhs: quoted(Expr)) -> Bool
compare : (expr: quoted(Expr)) -> Bool
`quote` : (expr: quoted(Expr)) -> Expr
str-r = (x: Str-Literal) => x
num-u8  : (x: Num-Literal) -> U8
num-i8  : (x: Num-Literal) -> I8
num-u64 : (x: Num-Literal) -> U64
num-i64 : (x: Num-Literal) -> I64
print : (xs: variadic(Any), sep = ' ', end = '\n') -> Unit

assert error(Has-Prelude) # run this file without prelude (-P option)

#
# Literals
#

test "number literals"
	forty-two = 42
	assert type-of(42) == Num-Literal
	assert type-of(forty-two) == Num-Literal

test "string literals"
	hello = 'hello'
	assert type-of(hello) == Str-Literal
	assert type-of("hello") == Str-Literal

test "number literal units"
	num-dummy = (x: Num-Literal) => none
	assert 42dummy == num-dummy(42)

test "string literal sigils"
	str-dummy = (x: Str-Literal) => none
	assert dummy"hello" == str-dummy("hello")

test "numbers ignore underscores"
	assert 1_000_000i64 == 1000000i64

xtest "special base 2, 8 and 16 notation"
	assert 0b101010 == 42
	assert 0o766 == 502
	assert 0xDEAD_BEEF == 3735928559

#
# Integers
#

test "number literal converts to 8-bit signed integer"
	0i8
	127i8
	-128i8
	assert error(128i8)
	assert error(-129i8)

test "number literal converts to 8-bit unsigned integer"
	0u8
	255u8
	assert error(256u8)
	assert error(-1u8)

test "number literal converts to 64-bit signed integer"
	0i64
	9223372036854775807i64
	-9223372036854775808i64
	assert error(9223372036854775808i64)
	assert error(-9223372036854775809i64)

test "number literal converts to 64-bit unsigned integer"
	0u64
	18446744073709551615u64
	assert error(18446744073709551616u64)
	assert error(-1u64)

test "integer comparison"
	assert 0u8 == 0u8
	assert 0u8 != 1u8
	assert 0i8 == 0i8
	assert 0i8 != 1i8
	assert 0i64 == 0i64
	assert 0i64 != 1i64
	assert 0u64 == 0u64
	assert 0u64 != 1u64

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

test "variables with incompatible types are not comparable"
	A : Type
	B : Type
	x : A
	y : B
	assert error(x == y)

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

test "monomorphic identity function"
	id = (x: Num-Literal) => x
	assert id(42) == 42

test "polymorphic identity function"
	id = (x: Type) => (y: x) => y
	assert id(Num-Literal)(42) == 42
	assert type-of(id(Num-Literal)) == ((y: Num-Literal) -> Num-Literal)
	assert type-of(id(Num-Literal)(42)) == Num-Literal

test "upwards funarg (argument)"
	foo = (x: Type) => (y: Type) => x
	assert foo(Num-Literal)(Str-Literal) == Num-Literal

test "upwards funarg (body)"
	foo = (x: Type) =>
		a = x
		(y: Type) =>
			a
	assert foo(Num-Literal)(Str-Literal) == Num-Literal

test "monomorphic identity function with assumed argument"
	id = (x: Type) => x
	A : Type
	assert id(A) == A

test "function type equality"
	A = (x: Type) -> Type
	B = (x: Bool) -> Type
	assert A == A
	assert A != B

test "function types with different parameter labels are equal"
	A = (x: Type) -> Type
	B = (y: Type) -> Type
	assert A == B

test "function types are equivalent up to label renaming"
	A = (a: Type, aa: a) -> Type
	B = (b: Type, bb: b) -> Type
	assert A == B

#
# Unique variables
#

test "opaque value is not equal to its underlying value"
	A : Type
	x : A
	opaque y = x
	assert x != y

test "type of opaque value is equal to the type of its underlying value"
	A : Type
	x : A
	opaque y = x
	assert type-of(x) == type-of(y)

test "opaque value is equal to its underlying value after unwrapping"
	A : Type
	x : A
	opaque y = x
	assert x == unwrap(y)

test "opaque type is not a subtype of the underlying value"
	A : Type
	opaque B = A
	assert not is-subtype(A, B)

test "can't unwrap declared but undefined variable"
	A : Type
	assert error(unwrap(A))

test "can explicitly coerce to opaque type"
	A : Type
	opaque B = A
	x : A
	y = x as B
	assert type-of(y) == B

test "can't implicly coerce to opaque type"
	A : Type
	opaque B = A
	x : A
	assert error(y : B = x)

test "opaque function application doesn't evaluate"
	a : Type
	opaque f = (x: Type) => x
	assert f(a) != a

test "opaque function applications with equal arguments are equal"
	a : Type
	opaque f = (x: Type) => x
	assert f(a) == f(a)

test "opaque function applications with non-equal arguments are not equal"
	a, b : Type
	opaque f = (x: Type) => x
	assert f(a) != f(b)

test "unwrapped opaque function application evaluates"
	a : Type
	opaque f = (x: Type) => x
	assert unwrap(f)(a) == a

test "unwrapping opaque function application forces evaluation"
	opaque f = (x: Type) => x
	assert unwrap(f(Type)) == Type

test "can't force evaluation of undefined function"
	f : (x: Type) -> Type
	assert error(unwrap(f(Type)))

test "can't force evaluation when arguments are undefined"
	a : Type
	opaque f = (x: Type) => x
	assert error(unwrap(f(a)))

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
	gensym : () -> Atom
	x = gensym()
	assert type-of(x) == Atom
	assert gensym() != gensym()

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
	foo, bar : () -> Unit

	nullary2 = () -> None => none
	nullary1() -> None = none
	assert type-of(nullary1) == type-of(nullary2)

	unary2 = (x: None) -> None => x
	unary1(x: None) -> None = x
	assert type-of(unary1) == type-of(unary2)

	multiline1(x y: Bool) -> Any =
		foo()
		bar()

	multiline2 = (x y: Bool) -> Any =>
		foo()
		bar()

	assert type-of(multiline1) == type-of(multiline2)

test "short named function syntax with inferred return"
	foo, bar : () -> Unit

	nullary1() = none
	nullary2 = () => none
	assert type-of(nullary1) == type-of(nullary2)

	unary1(x: None) = x
	unary2 = (x: None) => x
	assert type-of(unary1) == type-of(unary2)

	multiline1(x y: Bool) =
		foo()
		bar()

	multiline2 = (x y: Bool) =>
		foo()
		bar()

	assert type-of(multiline1) == type-of(multiline2)

test "short named opaque function syntax"
	a : Type
	opaque foo(x: Type) = x
	assert foo(a) != a
	assert foo(a) == foo(a)


#
# Booleans
#

opaque Bool = Byte
true = 1u8 as Bool
false = 0u8 as Bool
`and` = (x y: quoted(Expr)) -> expand(Expr) => quote(case $x of true $y of false false)
`or` = (x y: quoted(Expr)) -> expand(Expr) => quote(case $x of true true of false $y)
`not` = (x: Bool) -> Bool => case x of true false of false true

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

test "dependent function"
	A, B : Type
	t = (y: Bool) => case y of true A of false B
	assert t(true) == A
	assert t(false) == B
	f : (x: Bool) -> t(x)
	assert type-of(f(true)) == A
	assert type-of(f(false)) == B

test "dependent record"
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

#
# Function application
#

test "positional parameters must be passed in order"
	foo = (x: Bool, y: Str-Literal) => ()
	assert foo(true, "hello") == ()
	assert error(foo("hello", true))

test "positional parameters can be passed with a keyword"
	foo = (x: Bool, y: Bool) => x
	assert foo(true, y=false) == true
	assert foo(x=true, y=false) == true

test "positional parameters cannot be passed with a keyword more than once"
	foo = (x: Bool) => x
	assert error(foo(x=true, x=false))

test "positional parameters can be passed with a keyword out of order"
	foo = (x: Bool, y: Bool) => x
	assert foo(y=false, true) == true
	assert foo(y=false, x=true) == true

test "default parameter can be passed with a keyword"
	foo = (x: Bool = true) => x
	assert foo(x=false) == false

test "default parameter can be omitted"
	foo = (x: Bool = true) => x
	assert foo() == true

test "default parameter cannot be passed more than once"
	foo = (x: Bool = true) => x
	assert error(foo(x=false, x=true))

test "default parameter cannot be passed without keyword"
	foo = (x: Bool = true) => x
	assert error(foo(false))

test "first parameter is positional, second parameter is keyword"
	foo = (x: Bool, y: Bool = true) => y
	assert foo(true) == true
	assert foo(false) == true
	assert error(foo(false, false))
	assert foo(true, y=false) == false
	assert foo(y=false, true) == false
	assert error(foo(true, x=false))
	assert error(foo(x=false, true))
	assert foo(x=true, y=false) == false
	assert foo(y=false, x=true) == false

test "positional and keyword parameters cannot be passed with a non-matching keyword"
	foo = (x: Bool) => x
	bar = (x: Bool = false) => x
	assert error(foo(y=true))
	assert error(bar(y=true))

test "variadic parameters accept zero arguments"
	foo = (x: variadic(Bool)) => Type
	assert foo() == Type

test "variadic parameters accept one or more arguments"
	foo = (x: variadic(Bool)) => Type
	assert foo(true) == Type
	assert foo(true, true) == Type
	assert foo(true, true, true) == Type

xtest "default type of variadic parameter is Arguments"
	foo = (x: variadic(Bool)) => type-of(x)
	assert foo() == Arguments(List-Literal)
