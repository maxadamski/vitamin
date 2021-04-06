
U8 : Type
I64 : Type
U64 : Type

Int = I64
Size = U64

Bool = opaque U8
true = 1 as Bool
false = 0 as Bool

None = opaque U8
none = 0 as None

`prefix &` = opaque (a: Type) -> Type => Size

