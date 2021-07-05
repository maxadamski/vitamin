# If the short function definition macro `_ ( _ ) = _` is called multiple times in the same scope
# to create a function with the same name, but different (not exactly equal)  type signatures,
# then each function definition is wrapped in an anonymous record value, which is then used.

# for example, two "overloaded" definitons of `+`

`+`(x y : I64) = add-I64(x, y)

`+`(x y : F64) = add-F64(x, y)

# desugar to the following two anonymous record values:

use (
    `+` = (x y : I64) => add-I64(x, y)
)

use (
    `+` = (x y : F64) => add-F64(x, y)
)


# but the definition of `foo`

foo(x y z : Bool) = x and y or z

# desugars to this:

foo = (x y z : Bool) => x and y or z
