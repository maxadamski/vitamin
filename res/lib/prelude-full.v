# Core language definitions

U8 : Type

U64 : Type

I64 : Type

F64 : Type

String-Literal : Type

Number-Literal : Type

Size = newtype U64

Int = newtype I64

Float = newtype F64

Bool = newtype U8

None = newtype U8

true = 1 as Bool

false = 0 as Bool

none = 0 as None

Any = Union()

Never = Inter()

Unit = Record()

Optional = (a: Type) => Union(a, None)

`_ ?` = Optional

`??` = (x, y: Expr) => qq(if uq(x) == none uq(y) else uq(x))

Pointer = newtype (a: Type) => Size

`& _` = Pointer

`& mut _` = newtype Pointer

`mut _` = newtype Pointer

`mut _` = Mutable

Array = newtype (a: Type, n: Size) => Pointer(a)

append : (x: mut List($A)) -> Unit

concat : (x: List(List($A))) -> List(A)

len : (x: List($A)) -> unwrap(x).len

`_ [ _ ]` : (x: List($A), index: Size) -> A

`:=` : (x: mut $A) -> Unit

List = newtype (a: Type) => Struct(buf: a, len: Size)

Expr : Type

is-atom : (expr: Expr) -> Bool

is-term : (expr: Expr) -> Bool

token : (atom: Expr) -> mut 

exprs : (term: Expr) -> List(mut Expr)

type-of = (x: $A) => A

id = (x: $A) => x

`==` : macro (x, y: Expr) -> Bool

`!=` = macro (x, y: Expr) -> Bool => not x == y

case-type : macro (x: Optional(Expr), y: List(Record(Exp, Exp))) -> Type

`case` : macro (x: Optional(Expr), y: List(Record(Exp, Exp))) -> case-type(x, y)

`if` : macro (a, b: Expr, c: List(Record(Exp, Exp)), d: Optional(Expr)) => `case`(none, concat([(a, b)] cons((a, b), c, (quote(_)))))

`not` = (x: Bool) -> Bool => if x false else true

`and` = (x: Bool, y: Bool) -> Bool => if x y else false

`or` = (x: Bool, y: Bool) -> Bool => if x true else y
