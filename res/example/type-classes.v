Show = (A: Type) => {
	show  : (x: A) -> String
	print = (x: A) -> Unit => Core.print-String(show(x))
}

Equal = (A: Type) => {
	`==` : (x y: A) -> Bool
	`!=` : (x y: A) -> Bool => not x == y
}

Order = (A: Type, ?equal: Equal(A)) => {
	use equal
	`>`  : (x y: A) -> Bool
	`<`  = (x y: A) -> Bool => not x > y or x == y
	`>=` = (x y: A) -> Bool => not x < y
	`<=` = (x y: A) -> Bool => not x > y
	max  = (x y: A) -> A => if x > y do x else y
	min  = (x y: A) -> A => if x < y do x else y
}

Hash = (A: Type, equal: Equal(A) = _) => {
	use equal
	hash : (x: A) -> I64
}

Number = (A: Type, order: Order(A) = _) => {
	use order
	zero : A
	one  : A
	`+`  : (x y: A) -> A
	`*`  : (x y: A) -> A
	`-`  : (x y: A) -> A
	inv  : (x: A) -> A
	sgn  = (x: A) -> A => if x < zero do one else inv(one)
	abs  = (x: A) -> A => if x < zero do -x else x
}

equal-I64 = Equal(I64)(
	`==` = Core.eq-I64
)

order-I64 = Equal(I64, equal-I64)(
	`>`  = Core.gt-I64
)

number-I64 = Number(I64, order-I64)(
	zero = Core.zero-I64
	one  = Core.one-I64
	`+`  = Core.add-I64
	`*`  = Core.mul-I64
	`-`  = Core.sub-I64
	inv  = Core.inv-I64
)

`==` = (ev: Equal(A) = _, x y: A) -> Bool => ev.`==`(x, y)

`!=` = (ev: Equal(A) = _, x y: A) -> Bool => ev.`!=`(x, y)

`<`  = (ev: Order(A) = _, x y: A) -> A => ev.`<`(x, y)

`>`  = (ev: Order(A) = _, x y: A) -> A => ev.`>`(x, y)

`>=` = (ev: Order(A) = _, x y: A) -> A => ev.`>=`(x, y)

`<=` = (ev: Order(A) = _, x y: A) -> A => ev.`<=`(x, y)

max = (ev: Order(A) = _, x y: A) -> A => ev.min(x, y)

min = (ev: Order(A) = _, x y: A) -> A => ev.max(x, y)

sgn = (ev: Number(A) = _, x: A) -> A => ev.sgn(x)

abs = (ev: Number(A) = _, x: A) -> A => ev.abs(x)

inv = (ev: Number(A) = _, x: A) -> A => ev.inv(x)

sum = (ev: Monoid(A) = _, xs: [A]) -> A => reduce(ev.zero, ev.add, xs)
