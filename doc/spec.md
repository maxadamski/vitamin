
# The Vitamin Programming Language


## Table of contents

1. [Introduction]()
1. [Lexer Grammar Rules]()
    - Whitespace
    - Comments
    - Identifiers
    - Number literals
    - Rune literals
    - String literals
1. [Parser Grammar Rules]()
1. [Semantics]()



## Introduction



## Lexer Grammar Rules

In this section grammar rules, used to scan Vitamin programs, are presented.


### Whitespace

Newlines and whitespace characters are ignored.

```antlr
Newline : '\r'? '\n' '\r'? -> skip ;
Whitespace : [ \t]+ -> skip ;
```

### Comments

Comments are discarded during the lexing phase (TODO: ability to change this).

Single line comments begin with `//`, and end at the line break.
Multi line comments begin with `/*`, end with `*/`.
However, unlike C, multi line comments can be nested.


```antlr
LineComment : '//' ~[\r\n]* ;
BlockComment : '/*' ( BlockComment | . )* '*/' ;
```

### Identifiers

Like in the C language an identifier consists of underscores `_`,
lowercase `a-z` and uppercase `A-Z` letters of the english alphabet, and numbers `0-9`,
but cannot begin with a number.
A single underscore is a reserved name, and cannot be used as an identifier.

```antlr
fragment NameHead : [_A-Za-z] ;
fragment NameTail : NameHead | [0-9] ;
Name : NameHead NameTail* ;
```

### Number literal

We define regular expressions used to match strings of the number literals' digits.
The `_` number separator is allowed after the most significant digit.
When using the hexadecimal notation, case is insignificant.

```antlr
fragment HexDigits : [0-9A-Fa-f][0-9A-Fa-f_]* ;
fragment DecDigits : [0-9][0-9_]* ;
fragment OctDigits : [0-7][0-7_]* ;
fragment BinDigits : [01][01_]* ;
fragment Sign : [-+] ;
```

An integer number literal can be written in decimal, hexadecimal, octal or binary base,
after using the appropriate suffix.
Only literals written in decimal and hexadecimal base may encode real numbers.
Floating point numbers must have at least one digit before _and_ after the fraction separator.

A positive or negative exponent may also be added.
Decimal numbers have decimal exponents delimited by the letter `e`,
and hexadecimal numbers have hexadecimal exponents delimited by the letter `p`.
The hexadecimal floating point behavior is the same as in the C99 standard ([explanation][1]).

The sign of number is not encoded in the literal.
Instead, the `-` and `+` operators provide this functionality.

```antlr
fragment RealNumber
    :      DecDigits ( '.' DecDigits )? ( [eE] Sign? DecDigits )?
    | '0x' HexDigits ( '.' HexDigits )? ( [pP] Sign? HexDigits )?
    | '0o' OctDigits
    | '0b' BinDigits
    ;
```

Finally the `i` suffix can be used to mark the imaginary part of complex numbers.

```antlr
Number : Sigil? RealNumber [i]? ;
```

It's worth noting, that unlike C, there are no suffixes for different number types,
as number literals are untyped. To specify a desired type use the `as!` operator.

More information on numbers can be found in the "Number types" section.

#### Examples:

```vitamin
// Decimal numbers
1, 42i, 1_000_000, 0766, 1_, 00000, 10__0000__0000
// Decimal floating point numbers
3.1415, 1.0, 0.123, 1e9, 1e+9, 7.12e-6, 2.0i
// Hexadecimal numbers
0x0, 0x123456, 0xFFFF33, 0xDead_Beef
// Hexadecimal floating point numbers
0xC.3p0     // (12*16^0 + 3*16^-1) * 2^0 = 12.1875
0xAB.CDp4   // (10*16^1 + 11*16^0 + 12*16^-1 + 13*16^-2) * 2^4 = 2748.8125
// Binary numbers
0b0, 0b1, 0b1100_1100, 0b10i
// Octal numbers
0o0, 0o766, 0o1_234_567
// Invalid numbers
1.
.123
```

### String literal

At the moment Vitamin offers raw and escaped single-line strings.
This will change soon, when a custom lexer is written.

More information on strings can be found in the "String type" section.

```antlr
EscapedString
    : '"' ( '\\' . | ~('"' | NEWLINE) )* '"' ;

RawString
    : '"' ( '""' | ~('"' | NEWLINE) )* '"' ;
```

```antlr
String : Sigil? (EscapedString | RawString) ;
```

#### Examples

```vitamin
"", "Hello, World!", "Hello, 世界!"
"string \" with \t escape chars \n"
```

### ~~Rune literal~~

**Rune literals are now string literals with a `c` sigil!**

A rune represents one Unicode code point (like in Go).

More information on runes can be found in the "Rune type" section.

(Move to "Rune type")
Also, see the section 5 [on this page][2] for quick information on UTF-8.

#### Examples:

```vitamin
c'a', c'A', c'8', c'π'
c' '  // a space
c'\n' // a line feed
c'\\' // a backslash
c'🐨' // koala
c'日' // sun
```

## Parser Grammar Rules

In this section we will discuss the grammar used in the parsing phase of the compilation.

### Type

Vitamin simplifies C type declarations, by changing syntax of function pointers and arrays.
The `void` type is renamed to `()`, and anonymous struct, union, and enum types were removed.
Additionally, set, tuple and dictionary types were added (with special syntax).

```antlr
type
    : path
    | '()'
    | '(' type (',' type)* ')'
    | '[' type (',' Number)? ']'
    | '*' type
    | 'const' type
    | type '->' type
    ;
```

#### Examples

In effect type declarations can be read from left to right.

```vitamin
()              // void
const T         // constant T
(T, U, V)       // T and U and V

*T              // pointer to T
**T             // pointer to (pointer to T)
const *T        // constant pointer to T
const * const T // constant pointer to constant T

[T, n]          // array of T, with size n
[[T, m], n]     // array of (array of T, with size m), with size n
[T]             // dynamic array of T
[[T]]           // dynamic array of (dynamic array of T)
*[T, n]         // pointer to array of T, with size n
*[*T, n]        // pointer to array of (pointer to T), with size n

() -> ()        // function (taking no arguments, and) returning void
(T) -> (U)      // function taking T, and returning U

// function taking a constant pointer to (array of T, with size 10),
// and returning U and (pointer to V)
(const *[T, 10]) -> (U, *V)

Map(K, V)       // dictionary with keys K, and values V
Set(T)          // set of T
```

### Literal

```antlr
literal
    : '[' expr_list? ','? ']'
    | '(' expr_list? ','? ')'
    | Number | String | Rune
    | 'true' | 'false' | 'nil'
    ;
```

#### Examples

```vitamin
[]         // empty array
[a, b, c]  // array of a and b and c
[a, b, c,] // array of a and b and c, with a trailing comma
()         // empty tuple
(a, b, c)  // tuple of a and b and c
true       // true
false      // false
nil        // nil (replaces NULL)
```

## Macros






## Functions





## Use Statements

#### Rules

0. Use the `use` keyword to import identifiers into the current scope
0. Use the `select` list to only import specific identifiers
0. Use the `except` list to skip specific identifiers
0. Use the `as` operator to rename a qualifier or identifier
0. Use the `qualified` keyword to force the use of the qualifier
0. Rename the qualifier to `_` to prevent it's use

####  Grammar

```
use = 'use' name
```

#### Reference table

| import expression                | what's in scope          | notes                                                  |
|----------------------------------|--------------------------|--------------------------------------------------------|
| use X                            | `a, b, c, X.a, X.b, X.c` | all qualified and unqualified names                    |
| use X qualified                  | `X.a, X.b, X.c`          | all qualified names                                    |
| use X select a, b                | `a, b, X.a, X.b`         | selected qualified and unqualified names               |
| use X select a, b qualified      | `X.a, X.b`               | selected qualified and unqualified names               |
| use X except a, b                | `c, X.c`                 | filtered qualified and unqualified names               |
|                                  |                          |                                                        |
| use X as _                       | `a, b, c`                | all unqualified names (special case of new qualifier)  |
| use X as Y                       | `a, b, c, Y.a, Y.b, Y.c` | all qualified and unqualified names, new qualifier     |
| use X as Y select a, b           | `a, b, Y.a, Y.b`         | selected unqualified names, new qualifier              |
| use X as Y select a as x, b as y | `x, y, Y.x, Y.y`         | selected unqualified names, new qualifier and names    |
|                                  |                          |                                                        |
| use X select ()                  | nothing                  | only import protocol instances for known identifiers   |

#### Notes

The `as` clause must appear before the select/hiding list:

```
// this is valid
use X as Y select a, b
// but this is not
use X select a, b as Y
```

Using both the select and hiding lists is prohibited:

```
// these can make sense, but they're too much of a hassle
use X (a, b) hiding (c)
use X (a) hiding (a)
```

The expression `use X as _ qualified` is prohibited, use `use X ()` instead.


## Types

### Grammar
```
TypeCtx   --> Type [ 'where' WhereExpr ]
Type      --> Name [ Tuple(Type) ] | Name "'"
WhereExpr --> Type | Tuple(Type)
```

#### Grammar Expansion

Terms marked with a question mark are either present or an empty term `()`.
Terms surrounded by brackets are enclosed in a tuple term `(TUPLE x1 x2 ... xn)`.

```
Type     --> (TypeName TypeArgs TypeCtx) | TypeVar
         --> (name [Type ..] [Type ..])  | name
         
DataType --> (data Type [DataCase ...])
DataCase --> (name [CaseArg ...]) 
CaseArg  --> (case_arg Name? Type Expr?)
```

## User-Defined Datatypes

### `type` - Type Alias
The core form `type` creates an alias to an already existing type.
Such types can be constructed using the alias or the original type name.
Additional constructors may be defined as overloaded functions with the type name.

#### Examples
```
type Atom = String
type IPv4 = (Int8, Int8, Int8, Int8)
type Vector(a') where Num(a') = List(a')
type Point = (x: Int, y: Int)
fun Point() -> Point = Point(0, 0)
```

#### Grammar
```
user-type --> 'type' type-spec [ '=' type ]
```

---

### `data` - Algebraic Data Type
The core form `data` creates a new abstract data type.

#### Examples
```
data Color = red | green | blue
data Maybe(a') = none | some(a')
```

#### Grammar
```
Data-Type --> 'data' Type-Spec '=' Data-Case { '|' Data-Case }
Data-Case --> Case-Name [ '(' Aata-Arg+ ')' ] 
Case-Arg  --> [ Name ':' ] Type [ '=' Expr ]
```

---

### `protocol` - Type Parametric Polymorphism
```
protocol --> 'protocol' type-spec '=' '{' function* '}'
```

---

### `instance` - Protocol Instance
```
instance --> 'instance' type-spec '=' '{' function* '}'
```

---

### `enum` - C-Style Enumeration
The macro `enum` can be used to create C-like enumerations.
The enum value type must conform to the `EnumSequence` protocol

#### Examples
```
enum Color: Int = r(0xff0000) | g(0x00ff00) | b(0x0000ff)
enum Wheels: Int = one(1) | two | four(4)
```

For example, the mentioned enum `Wheels` roughly expands to:
```
data Wheels = one | two | four
value(self: Wheels) -> Int = self
    | one  => 1
    | two  => 2
    | four => 4
Wheels(value: Int) -> Maybe(Wheels) = value
    | 1 => some(one)
    | 2 => some(two)
    | 4 => some(four)
    | _ => none
```

---

#### Grammar
```
'enum' name ':' type '=' name1 '(' value1 ')' '|' name2 ( '(' value ')' )? '|' ...
```

### `struct` - C-Style Structure
The macro `struct` will allow for defining a new datatype with fields and methods in a familiar syntax.


## On the inclusion of new features

### Who takes priority when deciding on language core features:

program user > library user > programmer > language implementer

### Commitments of the language:

To the users of your program:
- programs suit the user's needs
- programs are fast and correct
- programs are easy to acquire and run

To the users of your code:
- code is easy to acquire and use
- code is generic and reusable
- code is readable and self-documenting

To the programmer:
- language enables comfortable and fast development (project setup, compilation, ide)
- language offers helpful debugging tools
- language offers obvious and non-magical solutions to problems
- language is familiar, featureful and extensible

## On creating new operators

Binary known for their cummutativity (for example `+`) should have commutative behaviour.

Exercise restraint when creating custom operators with exotic symbols.

[1]: https://www.exploringbinary.com/hexadecimal-floating-point-constants
[2]: http://utf8everywhere.org/
