# Vitamin C Standard Library

## Operators
`operator(name, binding-power, template)`

## Variables

### Variable Definition
`let _ = _`
`var _ = _`

### Assignment
`_ = _`


## Control Flow

### If Expression
`if _ { _ }`
`if _ { _ } else { _ }` 

### Match Expression
`match _ { _ }`


#### Examples
```
let x = match color {
    case 0xFF0000 ->
        "red"
        
    case 0x00FF00 ->
        "green"
        
    case 0x0000FF ->
        "blue"
        
    case _ ->
        "other"
}
```


### Loops
`for _ in _ { _ }` 
`for _ , _ , _ { _ }`
`while _ { _ }`
`repeat { _ } while _`

##### Examples
```
for i in range(10) {
    print(i)
}

for var i = 0, i < 10, i += 1 {
    print(i)
}

var j = 0
while j < 10 {
    print(j)
    j += 1
}

repeat {
    print("only printed once")
} while false
```


## Data Types

### Type Alias
`type _ = _`

The core form `type` creates an alias to an already existing type.
Such types can be constructed using the alias or the original type name.
Additional constructors may be defined as overloaded functions with the type name.

#### Examples
```
type Atom = String
type IPv4 = (Int8, Int8, Int8, Int8)
type Vector(a) where Num(a) = List(a)
type Point = (x: Int, y: Int)
fun Point() -> Point = Point(0, 0)
```

### Algebraic Data Type
`data _ = _`

The core form `data` creates a new abstract data type.

#### Examples
```
data Color = red | green | blue
data Maybe(a) = none | some(a)
```

### Type Protocol
`protocol _ = _`

### Type Instance
`instance _ = _` 

### C-Style Enumeration
`enum _ : _ = _`

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


### C-Style Structure
`struct _ = _`

The macro `struct` will allow for defining a new datatype with fields and methods in a familiar syntax.


## Modules

### Importing Modules

#### Rules
0. `use` macro imports identifiers into the current scope
0. `show ...` only imports specified identifiers
0. `hide ...` only imports the complement of the specified identifiers
0. `as` renames qualifiers and identifiers
0. `qualified` forces the use of the qualifier
0. Renaming the qualifier to `_` hides it

#### Reference table
| expression                       | what's in scope          | notes                                                  |
|----------------------------------|--------------------------|--------------------------------------------------------|
| use X                            | `a, b, c, X.a, X.b, X.c` | all qualified and unqualified names                    |
| use X qualifed                   | `X.a, X.b, X.c`          | all qualified names                                    |
| use X show a, b                  | `a, b, X.a, X.b`         | selected qualified and unqualified names               |
| use X show a, b qualified        | `X.a, X.b`               | selected qualified and unqualified names               |
| use X hide a, b                  | `c, X.c`                 | filtered qualified and unqualified names               |
| use X as _                       | `a, b, c`                | all unqualified names (special case of new qualifier)  |
| use X as Y                       | `a, b, c, Y.a, Y.b, Y.c` | all qualified and unqualified names, new qualifier     |
| use X as Y show a, b             | `a, b, Y.a, Y.b`         | selected unqualified names, new qualifier              |
| use X as Y show a as x, b as y   | `x, y, Y.x, Y.y`         | selected unqualified names, new qualifier and names    |
| use X show ()                    | nothing                  | only import protocol instances for known identifiers   |

#### Notes
The `as` operator has higher precedence than the `use` operator
```
// these are not equivalent
use X as Y show a, b --> [use [as X Y] show [a b]]
use X show a, b as Y --> [use X show [a [b as Y]]]
```

Using both the select and hiding lists is prohibited:
```
// these can make sense, but they're too much of a hassle
use X show a, b hide c
use X show a hide a
```

The expression `use X as _ qualified` is prohibited, use `use X ()` instead.

