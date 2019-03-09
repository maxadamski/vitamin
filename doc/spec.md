
# The Vitamin Programming Language


## Table of contents

1. Introduction
1. Lexical Structure
    - Whitespace
    - Comments
    - Atoms
    - Numbers
    - Strings
1. Expressions
    - Lambda
    - Call
    - Form
1. Macros
    - Quasiquotation
1. Type System
    - Alias Type
    - Data Type
    - Protocol
    - Instance
1. Module System
1. Standard Forms
    - Variables
    - Functions
    - Types
    - Modules
    
## Introduction


## Lexical Structure

### Whitespace

#### Grammar
```
Whitespace ::= [ \n\r\t\v\f\0]+ ;
```

```
Newline ::=  '\r'? '\n' '\r'?
```

#### Semantics
There are four lexer modes: `()`, `[]`, `{}` and `ESC`.
Lexer modes are pushed to and popped from a stack.

Tokens `(`, `[`, `{`, `}`, `]`, `)` push and pop their respective modes.
Token `\\` pushes the `ESC` mode, and a `Newline` pops it.

If the mode stack is empty or the `{}` mode is at the top, a `Newline` is replaced by an `EOS` token.
Otherwise `Newline` tokens are ignored.

### Comments

Single line comments begin with `//`, and end at the line break.
Multi line comments begin with `/*`, end with `*/`, and can be nested.

#### Grammar
```
Comment  ::= Comment1 | Comment2
Comment1 ::= '//' [^\r\n]*
Comment2 ::= '/*' ( Comment2 | . )* '*/'
```

### Atoms
An atom is a string of any unicode characters except whitespace.

At the lexical level, there are two special groups of atoms: strong and weak separators.

When a strong separator is found the lexer stops reading the atom and continues onto another rule.

A weak separator is only converted into it's own token only if it's immediately followed by a strong separator.
For the purposes of this rule, whitespace, comments and parentheses are also strong separators.

#### Grammar
```
Atom ::= .+
// characters separated by space
SSep ::= . , ; // /* \ ( ) [ ] { } " ` \t \v \n \r \f \0 space
WSep ::= :
```

#### Examples
```
x y    --> x y
x.y    --> x . y
x,y    --> x , y
x:+y   --> x:+y
x :+ y --> x :+ y
x :, y --> x : , y
x: y   --> x : y
```


### Numbers
The `_` number separator is allowed after the most significant digit.
Case is insignificant when using bases greater than 10.

#### Grammar
```
Digits1 ::= [0-9][0-9_]*
Digits2 ::= [0-9A-Za-z][0-9A-Za-Z_]*
Number1 ::= Digits1 ('.' Digits1)? ([eE] [+-]? Digits1)? 'i'?
Number2 ::= Digits1 '#' Digits2
```

#### Examples
```
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

### Strings
Vitamin supports extensible single-line, and multi-line strings.

If an atom `f` is placed right before a string, the string token is passed to a macro `sigil_f` at compile time.

#### Grammar
```
String1 ::= '"' [^\n\r"]* '"'
String2 ::= '"""' ('\\' '"' | [^"""])* '"""'
```

#### Examples
```
"", "Hello, World!", "Hello, 世界!"
"string \" with \t escape chars \n"
sigil"string with a sigil"
"""multi-line " string "" with \""" escapes """
sigil"""big string with a sigil"""
"""
    multi-line
    strings
"""
```


## Expressions

### Stage-1 Grammar
```
prog ::= EOS* ( expr ( EOS+ expr )* )? EOS*
expr ::= prim+
prim ::= BEG prog END | Atom | Num | Str
```
Where BEG: `{`, END: `}`, EOS: `;`

### Stage-2 Grammar
```
e   ::= e_n | e_r | e_l
e_n ::= E   op_nonass   E
e_r ::=   ( op_prefix | E op_r )+ E
e_l ::= E ( op_suffix | op_l E )+
```

### Operators
Vitamin support user-defined mixfix operators.
These can not only be infix, prefix and infix, but also consist of multiple parts.

Mixfix operator are defined as a sequence of atoms and holes (expression placeholders),
where there is at least one atom between each consecutive pair of holes.

Each operator is assigned to a precedence group.
A precedence group can contain multiple operators,
but an operator can belong to only one precedence group.

A precedence group can form greater/smaller than relations with other groups.
Precedence group relations form a directed acyclic graph.

Vitamin uses _partial operator precedence_, so if operators `f` and `g` are unrelated,
then using them next to each other is a syntax error, and using paretheses is required.
This allows users to avoid specifying unintuitive precedence relations,
so for example logic and arithmetic operators can be unrelated.

Operator precedence relations are not transitive.
- `f ≐ f` is true (reflexivity)
- if `f ≐ g`, then `g ≐ f` (symmetry)
- if `f ≐ g` and `g ≐ h`, then `f ≐ h` (transitivity)

- `f ⋖ f` is false (irreflexivity)
- if `f ⋖ g`, then `g ⋖ f` does not follow (assymetry)
- if `f ⋖ g` and `g ⋖ h`, then `f ⋖ h` does **not** follow (intransitivity)
- if `f ≐ g` and `f ⋖ h`, then `g ⋖ h`

When assigning precedence groups,
operators are distinguished by their first atom and it's position.

##### Examples
- Operator `f _` will have the same precedence as `f _ g _ h`,
    but not `g _` or `_ f _ g _ h`.

#### Holes
Now consider an operator of precedence `p`.

- If the operator contains a hole `_`, it expects an expression of precedence `q >= p`
- If the operator contains a hole `↑`, it expects an expression of precedence `q > p`
- If the operator contains a hole `→` preceded by atom `◊`,
    it expects `n >= 1` expressions of precedence `q > p` separated by `◊`.
    
##### Examples
- `_ , →` will match `x1 , x2 , ... , xn` as `(, x1 x2 ... xn)`
- `_ + ↑` - left associative addition
- `↑ ^ _` - right associative exponentiation
- `if _ then _ else _` will match `if x then y else z`, but not `if if a then b else c then x else y`

##### Notes
Internally, an operator is either a null or a left parselet.
Null parselets are parser rules invoked when an operator begins with an atom,
while left parselets are invoked when an operator starts with a hole.
Other programming languages using top-down operator parsing,
would implement prefix operators as null parselets,
and infix/suffix operators as left parselets.

### Vitamin C Operators

The function call syntax in Vitamin is effectively represented like this:
```
call/0 ::= _ ( )
call/1 ::= _ ( _ )
call/N ::= _ ( _ , → )

anon/0 ::= _ ( ) { _ }
anon/1 ::= _ ( _ ) { _ }
anon/N ::= _ ( _ , → ) { _ }
```

Other standard operators:
```
set  --> _ = ↑
add  --> _ + ↑
sub  --> _ - ↑
mul  --> _ * ↑
fdiv --> _ / ↑
exp  --> ↑ ^ _
idiv --> _ div ↑
imod --> _ mod ↑
neg  --> - ↑

tuple  --> _ , →
lpair  --> ↑ : _
rpair  --> _ -> ↑

concat --> _ ++ →
cons   --> ↑ :: _

not  --> not _
and  --> _ and ↑
or   --> _ or ↑

notin  --> _ not in _
in     --> _ in _

setadd --> ↑ += ↑
setsub --> ↑ += ↑
setmul --> ↑ *= ↑
setdiv --> ↑ /= ↑

eq   --> _ == →
ne   --> _ != →
le   --> _ <= →
ge   --> _ >= →
lt   --> _ < →
gt   --> _ > →

defcon    --> let _ = _
defvar    --> var _ = _
defmacro  --> def _ ( _ ) = _
deffun/3  --> fun _ ( _ ) = _
deffun/4  --> fun _ ( _ ) : _ = _
deftype   --> type _ = _
defdata   --> data _ = _
defprot   --> protocol _ = _
definst   --> instance _ = _

cond/1 --> if ( _ ) _
cond/2 --> if ( _ ) _ else _
loop/1 --> while ( _ ) _
```


## Macros


## Functions


## Standard Forms


## Some Thoughts

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

### Creating new operators

Binary known for their commutativity (for example `+`) should have commutative behaviour.

Exercise restraint when creating custom operators with exotic symbols.
