
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
x: y --> x : y
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
json"""big string with a sigil"""
"""
    multi-line
    strings
"""
```


## Expressions


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
