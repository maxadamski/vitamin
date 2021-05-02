The Vitamin Programming Language Reference Manual
=================================================

# Program structure

Here is how a simple Vitamin program looks.

	fizzbuzz = (x: Int) =>
		case
		of i mod 15 == 0 'FizzBuzz'
		of i mod  3 == 0 'Fizz'
		of i mod  5 == 0 'Buzz'
		of _ to-string(i)

	main = () =>
		for i in 1..100
			print(fizzbuzz(i))

# Lexical structure

A Vitamin file is a series of atoms.

## Atoms

### Name

A name is an identifier composed of one or more alphanumeric characters, where the first character is a letter or underscore. Next characters can also be digits or dashes.

**Warning**

Because dashes are valid name characters, the following sequence is scanned as one identifier.

	x-y   # x-y

To use the common subtraction operator, you have to add whitespace between the `-` character.

	x - y # x  -  y


### Symbols

A symbol is an identifier composed of one or more non-alphanumeric characters.

**Exception**

If a dash `-` is preceded by symbol characters and is immediately followed by a digit, it is not added to the previous symbol, but created as a separate atom. As a consequence, you do not need to add whitespace before dashes which follow symbols, but precede number literals.

	arr[5:-2]  # arr  [  5  :  -  2  ]


### Separators

A separator is a particular sequence of characters, which are greedily combined into atoms. Example separators include commas `,`, semicolons `;` and many kinds of parentheses `(` and `)`, `[` and `]`, `{` and `}`. If a bar `|` follows an opening brace, or precedes a closing brace, it is added to the atom. This results in the following two-character separators: `(|` and `|)`, `[|` and `|]`, `{|` and `|}`. 


## Indentation

Vitamin keeps track of the indentation level.

If the first atom on a new line is preceded by some number of tabs and spaces, a special atom is added to the token list.

- If the sequence of tabs and spaces is identical to the previous line a `$CNT` atom is emitted.
- If the prefix of the sequence fully matches the sequence at top of the indentation stack, the new sequence is pushed onto the stack and an `$IND` atom is emitted.
- If the prefix of the sequence fully matches a sequence on the stack, then values are popped from the stack until this sequence is at the top. For each popped value a `$DED` atom is emitted.
- Otherwise the indentation is inconsistent at this line and an error is raised.

## Groups

Characters between opening and closing parentheses form a group. A group is also formed between the `$IND` and `$DED` atoms.

Characters inside a group are lexically analyzed and parsed on-demand, so a syntax macro can receive the raw character stream, instead of the token or expression stream, if you desire. This bypasses the Vitamin lexer and parser, so you can perform completely custom analysis.


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

	x = e

Variables cannot be redefined.

## Assumptions

You can assume a type of a variable, before defining it. Variables cannot be used before definition.

	x : A

When defining an assumed variable, the type must exactly match the type at assumption.

*Example*

Let's assume that there exists an external procedure `write`. To call it, we need to provide information about it's type. In the future this will be automatically synthesized from `.h` files.

	write : (handle: I32, buffer: &U8, length: Size) -> Size

## Scope

Names of variables may be reused in an inner scope. In this situation, the variable in the outer scope is said to be shadowed and cannot be accessed.

	x = 2
	if condition
		x = 4
		assert x == 4
	assert x == 2


## Pointers

Although you can't redefine variables, if a variable holds a writable pointer, you can change the value it points to with the assignment operator `:=`.

	a : &mut Int
	a := 42
	assert a == 0


### Capabilites

Each pointer carries capabilities in its type. Pointer capabilites mark what can be done with the pointer and to the value a pointer points to. Using more constraining capabilities, makes code safer and enables additional optimizations.

Pointers with all capability sets can be compared for identity. Additionally, the following rules apply.

- Pointers with the `tag` capability set can only be compared for identity
- Pointers with the `rdo` capability set can only be read from
- Pointers with the `wro` capability set can only be written from
- Pointers with the `mut` capability set can both be read from and written to.
- Pointers with the `imm` capability set can only be read from. The pointee value is guaranteed to never (observably) change.

For convenience, the capabilites are shown in the table below.

| cap |  cmp  | read  | write | const |
|:----|:-----:|:-----:|:-----:|:-----:|
|`tag`|   x   |       |       |       |
|`rdo`|   x   |   x   |       |       |
|`wro`|   x   |       |   x   |       |
|`mut`|   x   |   x   |   x   |       |
|`imm`|   x   |   x   |       |   x   |


Pointers with the `cmp` capability can be compared for identity with the identity comparison `===` operator.

Pointers with the `read` capability can be read from with the dereference `*` operator.

Pointers with the `write` capability can written to with the assignment `:=` operator.

In the stadard library, capability sets are symbols. All capability sets are enumerated in the set type `Cap`. There are additional types enumerating capability sets with common capabilities, such as `Cap-Readable` and `Cap-Writable`.


### Covertions

The standard library defines implicit convertions between pointers to values of the same type, but of different capability sets.

A pointer to type `a` with capability set `cap1` can be converted to a pointer to type `a` with capability set `cap2` iff the capabilites of `cap2` are a subset of capabilites of `cap1`.

The following conversions follow:

- `mut` -> `rdo` or `wro` or `tag`
- `imm` -> `rdo` or `tag`
- `wro` -> `tag`
- `rdo` -> `tag`

Additionaly, a pointer of type `a` with capability `read` can be converted (automatically dereferenced) to value of of type `a`.


### Aliasing

1. Pointers to memory of different types do not alias.

**IF** `x: Ptr(_, a)` and `y: Ptr(_, b)` and `a != b` **THEN** writing to `x` will not affect the result of reading from `y`.

2. Pointers to mutable memory of the same type may alias.

**IF** `x: Ptr(c1, a)` and `y: Ptr(c2, a)` and `c1 : Set(mut, wro)` and `c2 : Set(mut, rdo)` **THEN** writing to `x` may change the result of reading `y`.

3. Pointers to immutable memory do not alias

**IF** `x: Ptr(imm, a)` **THEN** writing to any other pointer `y` will not change the value when reading from `x`.


### Compatibility with C

When writing assuming a foreign C function type in Vitamin, use the table below for translating the parameter types.

**Note**: The first `const` from the right is in square brackets, because it doesn't matter, as C parameters are passed by value.

C parameter type      | Vitamin parameter type
----------------------|-----------------------
`A [const] x`         | `A`
`A * [const] x`       | `Ptr(mut, A)`
`A const * [const] x` | `Ptr(rdo, A)`


### Allocation

To obtain a pointer, you must first allocate memory. This is done with an allocator and the `new` and `ref` funcitons.

Memory allocated with unmanaged allocators needs to be freed with `del`. Double-free is undefined.

Supported managed allocators: `stack`, `temp`, `rc`.

Supported unmanaged allocators: `heap`.

	heap, stack, temp, rc : Allocator

	new : (alloc: Allocator = _, cap: Cap = _, a: Type) -> Ptr(cap, a)
	ref : (alloc: Allocator = _, cap: Cap = _, a: Type = _, x: a) -> Ptr(cap, a)
	del : (alloc: Allocator = _, cap: Cap = _, a: Type = _, x: Ptr(cap, a)) -> Unit

*Example: Explicitly allocating on the heap*

	# allocate memory for one string
	x : &mut A = new(heap, mut, Str)
	defer del(x)

*Example: Stack allocated integer*

	i = ref(stack, mut, Int, 0)

the same thing, but with syntactic sugar:

	var i := 0




# Types

In Vitamin types are values.

The type system is based on the Martin-Löf dependent type theory.

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

	(A: _, x: A) -> ... == (A: Type, x: A) -> ...

A parameter may even be omitted.
	
	(x: $A, y: $B) -> ... == (A: Type, B: Type, x: A, y: B) -> ...

Function with an empty parameter list.

	f : () -> A
	x = f() # called (x : A)
	y = f   # not called (f : () -> A)

An implicit parameter is a parameter with a default value `_`. If not passed, it will be derived or if it fails, the scope will be searched bottom-up for a value of a compatible type (must be marked by `@implicit` and be unambiguous).
	
	Repr = (A: Type) => Record(repr: (x: A) -> Str)
	# evidence that I64 can be transformed to Str
	repr-I64 : Repr(I64)(repr=...)
	# evidence that Foo can be transformed to Str
	repr-Foo : Repr(Foo) = (repr=...)
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

	print : (strings: ..Str; sep = ' ', end = '\n')
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


## Record Types

The record type represents an unordered collection of *rows* - labels paired with dependent types. It is extensible, because unspecified additional rows may be given as a polymorphic parameter.

The general form of the record type, or rather an extensible dependent product type is:

	Record(x1: A1, ..., xn: An, R)

Where $x_i$ is a row label and $A_i$ is the row type, which may be an expression using the value of any other row, provided the dependencies form a DAG. We say that a record type is extensible if may contain other rows $R$.

The type of a record type is:

	Universe(max(level-of(A1), ..., level-of(An), level-of(R)))

If a record is extensible, but the extra rows are discarded, the extra rows don't need to be named.

	discard-rows : Record(x y: F64, ...) -> record(x y : F64)

Otherwise, extra rows may be used polymorphically.

	preserve-rows : Record(x y: F64, R) -> Record(x y : F64; R)

A default value may be provided for each field.

	Record(x: A = a)

In which case, the type may be inferred.

	assert Record(x = a) == Record(x: type-of(a) = a)

If no default values are given, there you can use a shorthand for subsequent values of the same type.

	assert Record(x: Float, y z: Int) == Record(x: Float, y: Int, z: Int)

To construct a value of a record type use round parentheses.

	x = (name='John Smith', age=35)
	assert type-of(x) == Record(name: Str, age: I64)

To make use of default values, the record must be constructed *as if* it was a function call.

	Default-Struct = Record(length = 0, color = 'blue')
	x = Default-Struct()
	assert x.length == 0
	assert x.color == 'blue'

If a record is a superset of another record, use the `use` operator to "inherit" all the fields.

	Point-2D = Record(x: Float, y: Float)
	Point-3D = Record(use Point-2D, z: Float)
	assert Point-3D == Record(x: Float, y: Float, z: Float)


## Tuple Types

The tuple type represents an ordered sequence of non-dependent types:

	Tuple(A1, ..., An)

The type of the tuple type is:

	Universe(max(level-of(A1), ..., level-of(An)))


**TODO** Should I make tuples extensible?


## Variant Types

The enum type represents a dependent generalized abstract data type (GADT). This is a type which allows you to specify all of its possible values.

It's general form is:

	Variant(x1: A1, ..., xn: An)

Where $x_i$ is the constructor of the i-th alternative, and $A_i$ is the type of the value.

The constructor may be a value or a function.

	Bool = Variant(true : Bool, false : Bool)

	Maybe = (A : Type) => Variant(
		some : (value: A) -> Maybe(A)
		none : Maybe(A)
	)

If the type of the constructor is omitted, the type of it's value is the type itself.

	Bool = Variant(true, false)
	assert type-of(Bool.true) == Bool

	Maybe = (A : Type) => Variant(some : (value : A), none)
	assert type-of(Maybe.some(true)) == Maybe(Bool)

**TODO** should I make enums extensible?

## Union and Intersection Types

The union represents a type whose values may be of any of the alternative non-dependent types.

	A1 | ... | An

The type of the union type is:

	Universe(max(level-of(A1), ..., level-of(An)))

The intersection of no types is `&`, and is used to define `Any`. All types are subtypes of `Any`. Some languages call this a top type.

The union of no types is `|`, and is used to define `Never`, a type representing an impossible value. Such a value is useful to represent an infinite loop or a function that never returns (for example `Basic.exit`), since they will *never* produce a value. Some languages call this type `noreturn` or a bottom type.

The following laws apply.

	1. A|B     == B|A      # commutativity
	2. A|(B|C) == (A|B)|C  # associativity
	3. A|B     == A        # simplification (if B is subtype of A)
	4. A is subtype of A|B
	5. if A and B are subtypes of C, then A|B is subtype of C

The following reductions follow.

	A|Any   == Any
	A|Never == A
	A|A     == A


# Set Types

**TODO: document this** 


# Symbols

**TODO: document this** 


# Functions

	Function-Type = Record(
		Paremeter = Record(
			name : Str
			type : Expr|Type|None
			default : Expr|type|None
			autopass = false
			autoquote = false
		)

		params : List(Parameter)
		result : Exp|Type|None
		opaque : Bool
	)

	Baked-Function-Type = Record(
		Parameter = Record(
			name : Str
			type : Type
			value : type|None
		)

		context : Type
		params : List(Parameter)
		result : Type
	)

	Function = Record(
		type : Function-Type
		body : Expr
	)

	Baked-Function = Record(
		type : Baked-Function-Type
		address : Size
	)


# Overload Resolution


# Implicit Conversions

If an expression does not match the expected type at definition or function call,
then *at most one* implicit conversion is applied.

Implicit conversions are defined like this

	@implicit I64-from-NumLiteral : NumLiteral -> I64 = ...


# Expressions


## `=>`

Same as function type.

	(x1 : X1, ..., xn : Xn; y1 : Y1, ..., yn : Yn) -> Z => e

Result can always be inferred. Parameter types are not always inferred at the moment.

	(p1, ..., pn) => e

**TODO:** Infer parameter types from body, without context (hard).


## `case`

**TODO:** Document this

Syntax:

`pattern = constructor(pattern, ..., pattern) | name (':' type)? | _`

Structural pattern matching:

	case <value>
	of <pattern-1> <expression-1>
	of <pattern-2> <expression-2>
	...
	of <pattern-n> <expression-n> 

If-else alternative:

	case
	of <condition-1> <expression-1>
	of <condition-2> <expression-2>
	...
	of <condition-n> <expression-n>


## `if`

`if` expressions branch to one of code blocks depending on a given condition, which evaluates to `Bool`.

	if <condition-1> <expression-1>
	elif <condition-2> <expression-2>
	...
	else <expression-n>

The type of an `if` expression is `type(e1) | ... | type(en)`


## `while`

While loop opens a new scope and evaluates a block while a condition evaluates to `true`.

Type of a `while` expression is `Unit`. If the loop is infinite its type is `Never`. 

	var i := 0
	while i < 10
		print(i)
		i += 1


## `for`

For loop iterates over a value of type `A` if there is evidence of `Iterable(A)`.

Type of the `for` expression is `Unit`.

	for i in range(0, 10)
		print(i)
 
 This loop is equivalent to:
	
	iter = iterate(range(0, 10))
	while not empty(iter)
		i = next(iter)
		print(i)

**TODO:** Implement iterator protocol


## `.` (member access)

Vitamin features the familiar dot `.` operator known mostly from object-oriented languages.

There are three main uses of the dot operator.
Firstly, you can access member values of data types. Secondly, you can mutate the value of a member value.
Accessing the member value of a data type with the dot operator is equivalent to doing so with the builtin `member` macro.
Also, pleaso note, that there is no separate macro for mutating the member value. This use emerges from the combination of the `member` macro and the `:=` mutatation operator.

Lastly, you can use the dot operator to pass the left operand as the first argument to function application on the right hand side.
The ability to pass arguments in this way is sometimes known as Uniform Function Call Syntax (UFCS).

Here are examples of common `.` macro usage:

Getting a member value

	use Core
	person : {name: Str}
	assert (person.name) is-the-same-as (member(person, 'name'))

Setting a member value

	person : {name: mut Str}
	new-name : Str
	assert (person.name := new-name) is-the-same-as (member(person, 'name') := new-name)

Passing value as the first function argument (UFCS)

	add : (x y: Int) -> Int
	a, b : Int
	assert a.add(b) is-the-same-as add(a, b)


## `macro`

Lambdas marked with the `macro` qualifier must return a value of type `Expr`. When calling a macro, the returned abstract syntax tree expression is evaluated.

	`+` = macro (x y: Expr) =>
		quote add($x, $y)
	
	`for-2` = macro (name vals body: Expr) =>
	    var = gensym()
		quote
			$var = iterate($vals)
			while not empty($var)
				$body
				$var = next($var)


## `$` (short lambda)

**NOT IMPLEMENTED**

If an expression uses variables starting with a dollar sign it's automatically wrapped in a lambda. This operation works top-down on the syntax tree and is not transitive.

	foo($1 + $2) desugars to foo(($1, $2) => $1 + $2)


## `$` (function parameter)

**NOT IMPLEMENTED**

Add an entry to the function paramer list.

Names prefixed with `$`, used in function parameter types will be added to the function parameter list as implicit parameters. Only the first occurence of a name *should* be prefixed wih `$`. The type of the dollar parameter will be inferred.

	id : (x: $a) -> a

Desugars to:

	id : (a = _, x: a) -> a


## `quote`

Get the representation of the abstract syntax tree of a given expression.

	x: Expr = quote 2 + 3 * 4


## `$` (unquote)

Insert the result of an expression into the syntax tree of the quoted expression.

The argument of `$` must be of type `Expr` (either `Atom` or `Term`).

*Example*

	a = quote 2 + 2
	b = quote assert $a == 4
	eval(b)

**Warning**

Inside `quote`, other uses of the dollar `$` operator will be interpreted as unquote.


## `$$` (unquote splicing)

Insert *all subexpressions* of the result of an expression into the syntax tree of the quoted expression.

The argument of `$$` must be a value of type `Term` .

**Warning**

Other uses of the double dollar `$$` operator will be interpreted as unquote splicing.


## `defer`

Defer postpones the evaluation of an expression to the end of a block.

**Example**

Ensure a file handle is closed when exiting scope.

	file = open('foobar.txt')
	defer close(file)
	# do other stuff


## `use`

Imports all names into current scope.

	point = (x=2, y=3)
	use point
	print(x) # prints 2

Useful in processing evidence and objects.

	Point = Record(x y: F64)
	magnitude = (self: Point) => use self; sqrt(x*x + y*y)
	# or shorter
	magnitude = (use self: Point) => sqrt(x*x + y*y)

Import some names into current scope:

	point = (x=2, y=3, z=4)
	use point.(x, y)

	# assertions
	assert is-defined(x)
	assert is-defined(y)
	assert not is-defined(z)


## `import`

**NOT IMPLEMENTED**

Import module and bring all members into scope:

	import tensor as t
	# above is equivalent to:
	tensor = Core.import('tensor')
	use tensor

Import module and bring some members into scope:

	import tensor.(Tensor, `*`, `+`)

	# above is equivalent to:
	tensor = Core.import('tensor')
	use tensor.(Tensor, `*`, `+`)

Import module without changing scope:

	import tensor.()

	# above is equivalent to
	tensor = Core.import('tensor')

	
## `with`

**NOT IMPLEMENTED**

Alternative arguments passing style:

	request('get', 'someurl') with
	    on-success = res =>
	        2 + 2
	        print(res)
		
	    on-error = () =>
	        print("couldn't get someurl")
	        exit(1)

Desugars to:

	request('get', 'someurl',
	    on-success = res => (2 + 2; print(res)),
	    on-error = () => (print(...); exit(1)))


## `undefined`

	undefined : Never

Defining or assuming variable with the special value `undefined` will not actually define or assume that variable. For example, the following expressions will do absolutely nothing.

	x = undefined
	y : undefined

In conjunction with `if` and `case` expressions, `undefined` can be used for conditional definitions. For example, if you wanted to assume a 64-bit signed integer type, but only if the target architecture supports them, you could write the definition as follows.

	I64 : if (target-bit-width == 64) Type else undefined


## `unreachable`

	unreachable : Never

Evaluating the special value `unreachable` at compile-time will result in a compilation error. When `unreachable` is encountered at runtime the program will crash. 



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
- post on implementing dependent type theory ([link][andrej-dependent])

Major inspirations: 
- C - speed and (relative) simplicity
- Python - syntax
- Nim - incredible features, identifiers, lexer trick for indentation
- D - UFCS, transitive mutability information
- Elm - row-polymorphic records, helpful compiler
- OCaml - polymorphic variants
- Scala, Agda, Idris - type system, implicits
- Ceylon - unions and intersections
- Lisp - macros, extensibility, kebab-case ;)
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
[andrej-dependent]: http://math.andrej.com/2012/11/08/how-to-implement-dependent-type-theory-i/