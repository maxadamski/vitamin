The Vitamin Programming Language Reference Manual
=================================================

# Program structure

Here is how a simple Vitamin program looks.

	fizzbuzz = (x: Int) =>
		if   i mod 15 == 0 'FizzBuzz'
		elif i mod  3 == 0 'Fizz'
		elif i mod  5 == 0 'Buzz'
		else to-string(i)

	main = () =>
		for i in 1..100
			print(fizzbuzz(i))

# Lexical structure

## Names
 

## Groups


# Literals 

## Number Literals

Number literals are textual representations of numbers.

	42 : Number-Literal
	2.71828 : Number-Literal

There is no loss of precision

	3.1415926535897932384626433 : Number-Literal
	100_000_000_000_000_000_000 : Number-Literal

### Units

Decimal number literals can be processed at compile-time by a macro `@unit-x`, where `x` is a unit - a token following the literal (without whitespace).

	@unit-km = (x: Number-Literal) => ...
	assert 18km == @unit-km(18)

### Bases

Binary, octal and hexadecimal number literals are provided for convenience,
with the limitation, that they cannot be followed by a unit.

	0xdead_beef : Number-Literal
	0o766 : Number-Literal
	0b0010_1010 : Number-Literal

For other number bases use a string with a custom sigil.

### Evaluation 

At variable definition, number literals evaluate to the highest signed or floating point number type available, or according to implicit conversions, if required.


## String Literals

String literals begin and end with single or double quotes.

They can also span multiple lines.

	'hello, world' : String-Literal

### Sigils

String literals are processed at compile-time by a function `@sigil-x`, where `x` is a sigil - the token that precedes (without whitespace) the literal.

	@sigil-v = (x: String-Literal) => ...
	v'0.0.1' == @sigil-v('0.0.1')

By default, if no sigil is specified, strings are processed by `@sigil-f`, which processes escaped characters and interpolates expressions inside escaped parentheses.

	'2 + 2 = \(2 + 2)' == '2 + 2 = 4'


# Variables

## Definitions

Here is how you define a variable `x` of type `A` with expression `e`.

	x : A = e

The type may be omitted.

	x = ...

Variables cannot be redefined.

## Assumptions

You can assume a type of a variable, before defining it.

	x : A

When defining an assumed variable, the type must exactly match the type at assumption.

*Example*

Let's assume that there exists an external procedure `write`. To call it, we need to provide information about it's type. In the future this will be automatically inferred from `.h` files.

	write : (handle: I32, buffer: &U8, length: Size) -> Size

## Scope

Names of variables may be reused in an inner scope. In this situation, the variable in the outer scope is said to be shadowed and cannot be accessed.

	x = 2
	if condition
		x = 4
		assert x == 4
	assert x == 2


# Memory

Although you can't redefine variables, you can define a variable as mutable memory, which can be written to with the assignment operator `:=`.

	a = ref 3
	a := 4

Symmetrically, there is a way to place a value in immutable memory (protected memory location), which cannot be written to. The following is practically equivalent to a regular variable definition.

	b = iref 42
	assert-error b := 0


**Internals**

Given the following functions in scope:

	Mut.new : (A: Type, count: Size = 1) -> Mut(A)
	Mut.del : (x: Mut(A)) -> Unit
	Mut.get : (x: Mut(A)) -> A
	Mut.set : (x: Mut(A), value: A) -> Unit

	Gc.new, Gc.get, Gc.set
	
	Mut-Stack.new : (A: Type) -> Mut-Stack(A)
	Mut-Stack.get : (x: Mut-Stack(A)) -> A
	Mut-Stack.set : (x: Mut-Stack(A), value: A) -> Unit

	Imm.ref : (x: A) -> Imm(A)
	Imm.get : (x: Imm(A)) -> A

	Imm-Stack.ref : (x: A) -> Imm-Stack(A)
	Imm-Stack.get : (x: Imm-Stack(A)) -> A

1. `var x : A` is the same as `x = Mut.new(A)`
2. `var x := e` is the same as `x = Mut.ref(e)`

Using memory in an expression automatically dereferences it.

	a + 2    # 4 : I64
	print(b) # prints 42

Of course, you can obtain a pointer to mutable and immutable memory (also see `Core.Memory.address`).

	&a # ptr 0xDEADBEEF

	
## Allocating on the heap

Allocating memory on the heap is done like this:

	# allocate memory for 1024 bytes and fill it with 0 
	x : mut A = allocate(U8, value=0, count=1024)

Explicitly allocated memory needs to be freed.

	free(x)

Double-free is undefined.

## Allocating on the stack

You can explicitly allocate memory on the stack.

	x : mut A = allocate-stack(I64, value=0)

Remember to free the memory before exiting the scope.

	free(x)

In fact defining a variable as memory `x : mut I64 = 42` is equivalent to:

	x : mut I64 = allocate-stack(I64, value=42)
	guard free(x)

Double-free is undefined.

## Pointer Aliasing

1. Pointers to memory of different types may not alias.
	`x != y if x : ptr mut A; y : ptr mut B`
2. Pointers to mutable memory of the same type may alias.
	`x may equal y if x y : ptr mut A or x y : ptr imm A`

There is no speed penalty or alias analysis if pointers refer to immutable memory `x y : ptr imm A`.

## Shorthand

For readability and user experience, there are a few conveniences:

1. `imm` and `mut` are transitive, until specified otherwise.
2. `imm A` and `mut A` are shorthands for `Immutable(A)` and `Mutable(A)`

For example:

	a : I64 = 42         # x : I64 
	b : I64 = read-int() # x : imm I64 = ... (the result is copied to `b`)
	mut { I64, String, imm U64 } == mut { mut I64, mut String, imm U64 }

	imm ptr ptr A == imm ptr imm ptr imm A
	mut ptr ptr A == mut ptr mut ptr mut A
	mut ptr imm ptr A = mut ptr imm ptr imm A
	mut ptr ptr imm A = mut ptr mut ptr imm A


	
	          | definition |  mutations
	----------|------------|-----------
	Immutable | x = e      |
	Mutable   |



## Compatibility with C

Here is a table of Vitamin memory types and the equivalent in C (or D).

This table doesn't use shorthand forms for clarity.

	Vitamin C        | C and family      | Description
	-----------------|-------------------|---------------------------------
	x: A             | immutable(A) x    | constant  A
	x: imm A         | A const x         | read-only A
	x: mut A         | A x               | mutable   A
	x: imm A         | immutable(A*) x   | constant  pointer to constant  A
	x: imm ptr A     | n/a               | constant  pointer to read-only A
	x: ptr mut A     | n/a               | constant  pointer to mutable   A
	x: imm ptr A     | A const * const x | read-only pointer to read-only A
	x: imm ptr mut A | A * const x       | read-only pointer to mutable   A
	x: mut ptr mut A | A * x             | mutable   pointer to mutable   A
	x: mut ptr imm A | A const * x       | mutable   pointer to read-only A

# Types

In Vitamin types are values.

The type system is based on the Martin-Lof dependent type theory.

## Universe Types

The type of `Universe(n)` is `Universe(n + 1)`, where `n >= 0 and n : Natural`.

Type `Universe(n)` is a subtype of `Universe(n + 1)`.

Also, for convenience `Type = Universe(0)`.

## Function Types

Function types are types of lambda expressions.

A function has two parameter lists: positional and keyword. Either or both parameter list may be absent. If there is only the keyword parameter list, it must begin with a semicolon.

In contrast to many functional languages, the whole parameter list is part of the function type, and not merely syntactic sugar for curried functions.

The general form of a function type is:

	(x1: X1, ..., Xn; y1: Y1, ..., yn: Yn) -> Z
	
Where $(x_i, X_i)$ and $(y_i, Y_i)$ are the i-th positional and keyword parameter-type pairs name, and $Z$ is the function return type. $X_i$ and $Y_i$ are expressions, which evaluate to types and may depend on the value of the previous parameters.

A default value may be provided for each parameter.

	(x: A = a) -> ...

In which case, the type may be inferred.

	(x = a) -> ...

If no default values are given, there is a shorthand for subsequent values of the same type.

	(x: Float, y z: Int) -> ... == (x: Float, y: Int, z: Int) -> ...

The type may also be inferred if another parameter depends on the value.

	(A, x: A) -> ... == (A: Type, x: A) -> ...

A parameter may even be omitted if it's name is an uppercase letter.
	
	# assuming A is defined or assumed
	(x: A, y: B) -> ... == (A: Type, B: Type, x: A, y: B) -> ...

Function with an empty parameter list.

	f : () -> A
	x = f() # called (x : A)
	y = f   # not called (f : () -> A)

An implicit parameter is a parameter with a default value `_`. If not passed, it will be derived or if it fails, the scope will be searched bottom-up for a value of a compatible type (must be marked by `@implicit` and be unambiguous).
	
	Repr = (A: Type) => { repr : (x: A) -> String }
	# evidence that I64 can be transformed to String
	@implicit repr-I64 : Repr(I64) = (repr=...)
	# evidence that Foo can be transformed to String
	@implicit repr-Foo : Repr(Foo) = (repr=...)
	# generic function, which searches for evidence of Repr(A) for a given A
	repr = (A: Type = _, ev: Repr(A) = _, x: A) => ev.repr(x) 
	# shorter
	repr = (?A: Type, ?ev: Repr(A), x: A) => ev.repr(x)
	# even shorter
	repr = (?A, ?ev: Repr(A), x: A) => ev.repr(x)
	# the shortest!
	repr = (?ev: Repr(A), x: A) => ev.repr(x)

**TODO:** Make a macro for automatic synthesis of protocols.

Missing parameters, which are depended upon, are added automatically in order of appearance.

	show : (?ev: Show(A) 

The last parameter of the positional parameter list may be variadic.

	print : (strings: ..String; sep = ' ', end = '\n')
	print('hello', 'world', sep=', ', end='!\n') # prints 'hello, world!'

*Rules for the function parameter lists:*

- positional and keyword parameter lists must be separated by a semicolon at defition
- parameter names must be unique
- keyword parameters must be passed with a keyword 
- positional parameters may be passed with a keyword
- parameters passed with a keyword may be passed in any order
- positional parameters not passed with a keyword must be passed in order
- parameters may specify a default value
- parameters with a default value may not be passed
- the @derive default value derives the argument based on compile-time information
- the @search default value searches for compatible values in the implicit scope


## Structure Types

The structure type represents an unordered collection of *rows* - labels paired with dependent types. It is extensible, because unspecified additional rows may be given as a parameter.

The general form of the structure type, or rather an extensible dependent product type is:

	{x1: A1, ..., xn: An, ..R}

Where $x_i$ is a row label and $A_i$ is the row type, which may be an expression using the value of any other row, provided the dependencies form a DAG. We say that a structure type is extensible if may contain other rows $..R$.

The type of a structure type is:

	Type(max(universe(A1), ..., universe(An), universe(R)))

If a structure is extensible, but the extra rows are discarded, the extra rows don't need to be named.

	discard-rows : {x y: F64, ..} -> {x y: F64}

Otherwise, extra rows may be used polymorphically.

	preserve-rows : {x y: mut F64, ..R} -> {x y: F64, ..R}

A default value may be provided for each field.

	{x: A = a}

In which case, the type may be inferred.

	{x = a} == {x: type(a) = a}

If no default values are given, there is a shorthand for subsequent values of the same type.

	{x: Float, y z: Int} == {x: Float, y: Int, z: Int}

To construct a value of a structure type use round parentheses.

	x = (name='John Smith', age=35)
	x : {name: String, age: I64}

To make use of default values, the structure must be constructed *as if* it was a function call (it's not!).

	T = {length = 0, color = "blue"}
	x = T()
	x == (length=0, color="blue")

## Tuple Types

The tuple type represents an ordered sequence of non-dependent types:

	{A1, ..., An}

The type of the tuple type is:

	Type(max universe(A_i))

**TODO** Should I make tuples extensible?

## Enum Types

The enum type represents a dependent generalized abstract data type (GADT). This is a type which allows you to specify all of its possible values.

It's general form is:

	[| x1 : A1, ..., xn: An |]


Where $x_i$ is the constructor of the i-th alternative, and $A_i$ is the type of the value.

The constructor may be a value or a function.

	Bool = [| true: Bool, false: Bool }

	Maybe = (A: Type) => [|
		some: (value: A) -> Maybe(A)
		none: Maybe(A)
	|] 

If the type of the constructor is omitted, the type of it's value is the type itself.

	Bool = [| true, false |]
	type(Bool.true) == Bool

	Maybe = (A: Type) => [| some : (value: A), none |]
	type(Maybe.some(true)) == Maybe(Bool)

**TODO** should I make enums extensible?

## Union and Intersection Types

The union represents a type whose values may be of any of the alternative non-dependent types.

	A1 | ... | An

The type of the union type is:

	Type(max universe(A_i))

The intersection of no types is `&`, and is used to define `Any`. All types are subtypes of `Any`. Some languages call this a top type.

The union of no types is `|`, and is used to define `Never`, a type representing an impossible value. Such a value is useful to represent an infinite loop or a function that never returns (for example `Basic.exit`), since they will *never* produce a value. Some languages call this type `noreturn` or a bottom type.

The following laws apply.

	1. A|B     == A|B      # commutativity
	2. A|(B|C) == (A|B)|C  # associativity
	3. A|B     == A        # simplification (if B is subtype of A)
	4. A is subtype of A|B
	5. if A and B are subtypes of C, then A|B is subtype of C

The following reductions follow.

	A|Any   == Any
	A|Never == A
	A|A     == A

# Expressions

## Lambda

Same as function type.

	(x1: X1, ..., xn: Xn; y1: Y1, ..., yn: Yn) -> Z => e

Result can always be inferred. Parameter types are not always inferred at the moment.

	(p1, ..., pn) => e

**TODO:** Infer parameter types from body, without context (hard).

## If Expression

`if` expressions branch to one of code blocks depending on a given condition, which evaluates to `Bool`.

	# simple expression
	if c1 e1 else e2

	# multiple conditions
	if c1 e1
	elif c2 e2
	...
	else en

The type of an `if` expression is `type(e1) | ... | type(en)`

## When Expresion

**TODO:** Document this

Syntax:

`pattern = constructor(pattern, ..., pattern) | name (':' type)? | _`

Structural pattern matching:

	when x
	case p1 e1
	case p2 e2
	...
	case pn en 

If-else alternative:

	when
	case c1 e1
	case c2 e2
	...
	case cn en

## While Loop

While loop opens a new scope and evaluates a block while a condition evaluates to `true`.

Type of a `while` expression is `Unit`. If the loop is infinite its type is `Never`. 

	var i := 0
	while i < 10
		print(i)
		i += 1

## For Loop

For loop iterates over a value of type `A` if there is evidence of `Iterable(A)`.

Type of the `for` expression is `Unit`.

	for i in range(0, 10)
		print(i)
 
 This loop is equivalent to:
	
	iter = iterate(range(0, 10))
	while not empty(iter)
		print(i)
		i = next(iter)

**TODO:** Implement iterator protocol


# Macros

## Macro Lambda

A macro is a lambda which does not evaluate a parameter if its type is `Syntax.Expr`, and instead passes the parsed abstract syntax tree to the function.

	`+` = @macro (x y: Expr) =>
	    quote(add(unquote(x), unquote(y)))
	
	`for-2` = @macro (name vals body: Expr) =>
	    var = gensym()
	    quote(
	        unquote(var) = iterate(unquote(vals))
	        while not empty(unquote(var))
		    unquote(body)
		    unquote(var) = next(unquote(var)))

## Dollar Lambda

If an expression uses variables starting with a dollar sign it's automatically wrapped in a lambda. This operation works top-down on the syntax tree and is not transitive.

	foo($1 + $2) desugars to foo(($1, $2) => $1 + $2)

**TODO:** implement this (low prio)

## Guard Macro

Guard allows you to evaluate an expression at the end of a scope.

For example, let's ensure a file handle is closed when exiting scope:

	file = open('foobar.txt')
	guard close(file)
	# do other stuff

## Use Macro

Imports all names into current scope.

	point = (x=2, y=3)
	use point
	print(x) # prints 2

Useful in processing evidence and objects.

	Point = {x y: F64}
	magnitude = (self: Point) => use self; sqrt(x*x + y*y)
	# or shorter
	magnitude = (use self: Point) => sqrt(x*x + y*y)
	

## With Macro

	request('get', 'someurl') with
	    on-success = res =>
	        2 + 2
	        print(res)
		
	    on-error = () =>
	        print("couldn't get someurl")
	        exit(1)

Desugars to

	request('get', 'someurl',
	    on-success = res => (2 + 2; print(res)),
	    on-error = () => (print(...); exit(1)))

## Custom Syntax

	@syntax

# Miscellaneous

## Modules

Should structures act as modules?

## Overload Resolution

## Implicit Conversions

If an expression does not match the expected type at definition or function call,
then *at most one* implicit conversion is applied.

Implicit conversions are defined like this

	@implicit I64-from-NumLiteral : NumLiteral -> I64 = ...


# Less is more

When designing Vitamin I avoided features, which needlesly bloated the core language.

That's why you will find some common language features in the standard library instead!

- Mutablitiy of values is specified at the type level.
- No constants and variables - just definitions, which cannot change.
- No distinction between type, function and value definitons.
- No distinction between named and anonymous functions.
- No generic types - just functions returning a type.
- No generic functions - just functions accepting types as the first arguments.
- No modules - just constant structures and first-class scope.
- No traits - just implicit parameters searching for evidence.


# Credits

Helpful papers and websites:
- post on pratt parsing ([link][pratt-parsing])
- post on intransitive operator precedence ([link][intransitive-precedence])
- agda mixfix operator paper ([link][mixfix-operators])
- row-polymorphic data types paper ([link][row-polymorphism])

Major inspirations: 
- C - speed and (relative) simplicity
- Python - syntax
- Nim - incredible features, identifiers, lexer trick for indentation
- D - UFCS, transitive mutability information
- Elm - row-polymorphic records, helpful compiler
- Scala, Agda, Idris - type system, implicits
- Ceylon - unions and intersections
- Lisp - extensibility, kebab-case ;)
- ATS, Rust - linear types

Minor inspirations:
- Julia - macros, number units, keyword parameters
- Elixir - macros, string sigils, immutability
- Swift - operator groups
- Nemerle - macros with custom lexing and parsing

[pratt-parsing]: https://www.engr.mun.ca/~theo/Misc/pratt_parsing.htm
[intransitive-precedence]: https://blog.adamant-lang.org/2019/operator-precedence/
[mixfix-operators]: http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.157.7899
[row-polymorphism]: https://www.microsoft.com/en-us/research/publication/first-class-labels-for-extensible-rows



# Appendix A - Core Types

```vitamin
# -- core.v

# Machine number types
U8 U16 U32 U64 : Type  # unsigned integers
I8 I16 I32 I64 : Type  # signed integers
F32 F64 : Type         # floating point
Size : Type            # largest unsigned type

# All values are subtypes of Any
Any : Type = `&`()

# There are no values of type Never
Never : Type = `|`()

# There is one value of type Unit - the empty structure `()`
Unit : Type = {}

# -- bool.v

# There are two values of type Bool
Bool : Type = [| true, false |] 

# -- optional.v

# There is one value of None
None : Type = [| none |]

# An optional is either a value of type `A` or `None`
# Shorthand for `Optional(A)` is `?A` or `opt A`
Optional = (A: Type) => A | None

# -- memory.v

Immutable-Memory = unique (A: Type) -> Type => A

Mutable-Memory = unique (A: Type) -> Type => A

Immutable-Pointer = unique (A: Type) -> Type => Size

Mutable-Pointer = unique (A: Type) -> Type => Size

# -- dynamic-array.v

# Shorthand for `Dynamic-Array(A)` is `[A]`
Dynamic-Array = (A: Type) => { length: USize = 0, capacity: USize = 0, buffer: &A }
Dynamic-Array = (length: USize = 0, capacity: USize = 0) -> Dynamic-Array(A) => (length=length, capacity=capacity, buffer=allocate(...))

# -- sized-array.v

# Shorthand for `Sized-Array(n, A)` is `[n,A]`
Sized-Array = (n: USize, A: Type) => { buffer: &A }

# -- string.v

String = { bytes: [U8] }
```

# Appendix B - Syntax Rules

```
parameter-s = '?' name (':' expression)?
parameter-v = name ':' '..' expression
parameter-n = name+ ':' expression
parameter-1 = name (':' expression)? ('=' expression)?
parameter = parameter-s | parameter-1 | parameter-n
parameter-list = '(' parameter* parameter-v? (';' parameter*)? ','? ')'
function-type = (parameter-list | expression) '->' expression
function = (paramater-list ('->' expression)? | name) '=>' expression

argument = (name '=')? expression
apply = expression '(' (argument ',')** ')' ('do' function)?

Parameter     | Sweet syntax      | Desugared syntax
--------------|-------------------|-----------------
parameter     | x : A = a         | Par(x, a, A)
parameter-1-1 | x                 | x : _ = @undefined
parameter-1-2 | x : A             | x : A = @undefined
parameter-1-3 | x = a             | x : _ = a
parameter-s-1 | ?x                | x : _ = @implicit
parameter-s-2 | ?x : A            | x : A = @implicit
parameter-n-1 | x-1 ... x-n : A   | x-1 : A, ..., x-n : A

Function      | Sweet syntax         | Desugared syntax
--------------|----------------------|-----------------
function      | (x-1, ..., x-n) -> A | Func(Pars(x-1, ..., x-n), A)
function-1    | (x) -> A             | (_: x) -> A
function-2    | x -> A               | (_: x) -> A

Function      | Sweet                      | Desugared
--------------|----------------------------|----------
lambda        | (x-1, ..., p-n) -> A => y  | Lambda(Pars(x-1, ..., x-n), A, y)
lambda-1      | (x-1, ..., p-n) => y       | (x-1, ..., p-n) -> _ => y
lambda-2      | (x) => y                   | disallowed
lambda-3      | x => y                     | (x : _) => y
lambda-4      | f($1, ..., $n)             | ($1, ..., $n) => f($1, ..., $n)

Argument      | Sweet        | Desugared
--------------|--------------|-----------------
argument-1    | x = a        | Arg(x, a)
argument-2    | a            | _ = a

Type          | Sweet                    | Desugared
--------------|--------------------------|-----------------
union         | A-1 | ... | A-n | ..a    | Union(A-1, ..., A-n, ..a)
tuple         | {A-1, ..., A-n}          | Tuple(A-1, ..., A-n)
structure     | {r-1, ..., r-n, ..a}     | Data(c-1, ..., c-n, ..a)
tagged union  | enum { c-1, ..., c-n }   | Enum(c-1, ..., c-n)

Enum Row      | Sweet                    | Desugared
--------------|--------------------------|-----------------
enum-row-1    | x : (p-1, ..., p-n) -> T | Row(x, _, Func(Pars(p-1, ..., p-n), T))
enum-row-2    | x                        | x : T 
enum-row-3    | x : A                    | x : (_ : A) -> T

Data Row      | Sweet                    | Desugared
--------------|--------------------------|-----------------
data-row-1    | x : A = a                | Row(x, a, A)
data-row-1    | x : A                    | x : A = @undefined
data-row-1    | x = a                    | x : _ = a
```
