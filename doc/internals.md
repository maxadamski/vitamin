# Vitamin Compiler Internals

First class types solve many of programmers' aches and all,
but they are hard to implement (or at least seem to be).
To compensate my static language should have ultra powerful
compile time metaprogramming capabilites.

# Syntax Tree

Vitamin's syntax tree datatype is `term`, which is an `atoms` or a (nullable) list of `terms`
An Atom is just a nullable Unicode Text.
There is no distinction between numbers and strings in the syntax tree.

```
Term := Atom | {Term}
```

## Notation

Below are shortcuts used for representing terms in this document.
If a term has a non-empty term list, it is delimited with parentheses.

| shorthand        | full term       | meaning |
|------------------|-----------------|---------|
| `hello`          | `'hello'`         | atom without whitespace |
| `'hello, world'` | `'hello, world'`  | atom with whitespace |
| `''`             | `''`              | zero-length atom |
| `()`             |                   | zero-length term |
| `foo(x y z)`     | `'foo' 'x' 'y' 'z'`     | term with term list |
| `foo(bar(baz))`  | `'foo' ('bar' ('baz'))` | term with term list |

## Syntactic Sugar

The parser immediately desugars "literals" into terms,
so the concept of a literal doesn't exist after initial parsing.

NOTE: If the parameter is capitalized, it's a term, otherwise, it's an atom

Basic terms:

```
atom
Callee(Argument...)
block(Expression...)
lambda(Head Body)
number(sign integer-part decimal-part) // will add sigils, exponents, suffixes and other bases in the next compiler
string(text) // will add sigils, multiline and interpolation in the next compiler
```

Examples:

```
x           => x
`a b c`     => 'a b c'
f(x, y)     => f(x y)
{ f; g; h } => block(f g h)
[ x in f ]  => lambda(x f)
-124e-3i    => number(- im 124 '' - 3)
3.14        => number(+ re 3 14 '' '' '')
'hello'     => string(hello)
"hello"     => string(hello)
"a\(f(x))b" => string('x' f(x) 'z')
```

Expression deferred to the Pratt parser:

```
x * 2 ^ 3   => parse(x * 2 ^ 3)
```

# Evaluation

What happens when a file is evaluated.
1. Files are parsed into expression trees
2. Flat expressions are parsed into trees
3. Macro calls are expanded
    - Call arguments are not evaluated
    - Macro body is **evaluated**
    - A macro can only call other macros or already compiled modules
    - Macro must return a Tree

# Lambda

- A default value is an expression, which can be evaluated at compile time
- A parameter is called a keyword parameter if it has a default value
- A parameter is called a variadic parameter if it's type ends in ellipsis (`...`)
- A variadic parameter cannot have a default value
- Otherwise a parameter is called a positional parameter

## Definition

Let's look at a definition of a named function:

```
fun foo<g1, gn>(x1: t1, x2: t2, x3: t3 = a3, x4: t4 = a4, x5: t5...) -> R {
    ...
}
```

Internally a Lambda is added to the current scope, with the follownig properties:

name:
- foo

generic types:
- g1
- g2

positional parameters:
- x1 of type t1
- x2 of type t2

keyword parameters:
- x3 of type t3 and default value eval(a3)
- x4 of type t4 and default value eval(a4)

variadic parameter:
- x5 of type Arguments<t5>

return type:
- R

## Overloading

Having defined a function 'foo' (1), a new function 'foo' (2) _cannot_
 be defined if any of the cases below occur:

- foo1 and foo2 have the same number of positional parameters (including zero)
- foo1 and foo2 both take a variadic parameter

The above rules allow the compiler to disambiguate a call a the compile time.

Multiple dispatch may be added in the future.

## Invocation

Having defined a function 'foo' with `P` positional parameters, `K` keyword parameters,
 and an optional variadic parameter `V`
 
The function 'foo' can be only invoked if it is given:
- `P` positonal arguments
- `k` keyword arguments, where `0 <= k <= K`
- `v` variadic arguments, where `0 <= v` if `V` is defined
 
Additional rules apply:
- positional arguments must be placed in the order of definition
- keyword and variadic arguments must be placed after positional arguments
- each keyword argument must be accompanied by it's keyword
_ a keyword may only be used once

Note that these rules do not specify the order of keyword and variadic arguments
 in their groups or in respect to each other.


## Type System

### Type information

A type is represented by the following union:

```
enum Type {
    Lambda([Type])
    Simple(String)
}
```

Let's walk through all the cases.
- `lambda` represents n-ary kind (where n is the length of the `Type` list)
- `simple` represents a simple type such as `Int` or `T`

The table below covers the representation of Vitamin's built-in types.

Note the simplified notation:
- `Lambda(a, b, c)` => `(a, b, c)`
- `Simple("a")` => `a`

| Name               | Repr                       |
|--------------------|----------------------------|
| Int etc.           | Int                        |
| List<T> etc.       | (List, T)                  |
| Hash<K, V> etc.    | (Hash, K, V)               |
| Functor<F<\_>>     | (Functor, (F, ()))         |
| (X1, ..., Xn)      | (Tuple, X1, ..., Xn)       |
| (X1, ..., Xn) -> Y | (Lambda, X1, ..., Xn, Y)   |
| (X1) -> (X2) -> Y  | (Lambda, X1, (Fun, X2, Y)) |

## Type constraints

A type constraint is represented by the following union:

```
enum TypeConstraint {
    IsGeneric(Type)
    IsSubtype(Type, Type)
    IsType(Type, Type)
}
```

Type constraints are stored in the object _alongside_ the object type

```
interface Lambda {
    type: Type
    constraints: List<TypeConstraint>
    
    fun validate
}
```

```
fun all_items_match<
    C1: Container, C2: Container,
    C1.Item == C2.Item,
    C1.Item: Equatable>(
    left_container: C1,
    right_container: C2) -> (
    Bool, List<Bool>,
    ErrorType) {
    
    return
}

fun main(argc: Int, argv: Array<String>) {

}

func allItemsMatch<C1: Container, C2: Container>
    (_ someContainer: C1, _ anotherContainer: C2) -> Bool
    where C1.Item == C2.Item, C1.Item: Equatable {
```

## Interface definition

```
trait Functor<F<_>> {
    fun fmap<T, U>(f: (T) -> U) -> (v: F<T>) -> F<U>
}


```
