
#
# Core
#

Atom, Term : Type

Expr = Term | Atom

Quoted, Lazy, Args, Eval : (a: Type) -> Type

Unit = Record()

Never = Inter()

Any = Union()

undefined : Never

unreachable : Never

U8, U64 : Type

I8, I64 : Type

F64 : Type

Size = U64

Int = I64

Float = F64

true = Symbol(true)
false = Symbol(false)
Bool = Set(true, false)

none = Symbol(none)
None = Set(none)

Tril = Set(true, false, none)

`assert` : (x: Quoted(Expr)) -> Unit

`?` = (a: Type) -> Type => a | None

imm = Symbol(imm)
mut = Symbol(mut)
ro = Symbol(ro)
wo = Symbol(wo)
Access = Set(imm, mut, ro, wo)

Ptr = opaque (access: Access, a: Type) => Size

Ops-U8 : Record(
	`+` `-` `*` `div` `mod` : (x y: U8) -> U8
	`==` `!=` `<` `>` `<=` `>=` : (x y: U8) -> Bool
)

Ops-I8 : Record(
	`inv` : (x: I8) -> I8
	`+` `-` `*` `div` `mod` : (x y: I8) -> I8
	`==` `!=` `<` `>` `<=` `>=` : (x y: I8) -> Bool
)

Ops-I64 : Record(
	`inv` : (x: I64) -> I64
	`/` : (x y: I64) -> F64
	`+` `-` `*` `div` `mod` : (x y: I64) -> I64
	`==` `!=` `<` `>` `<=` `>=` : (x y: I64) -> Bool
)

Ops-U64 : Record(
	`/` : (x y: U64) -> F64
	`+` `-` `*` `div` `mod` : (x y: U64) -> U64
	`==` `!=` `<` `>` `<=` `>=` : (x y: U64) -> Bool
)

Ops-F64 : Record(
	`inv` : (x: F64) -> F64
	`+` `-` `*` `/` : (x y: F64) -> F64
	`div` `mod` : (x y: F64) -> I64
	`==` `!=` `<` `>` `<=` `>=` : (x y: F64) -> Bool
)

`and` = (x y: Lazy(Bool)) -> Bool =>
	case x
	of true y
	of false false 

`or` = (x y: Lazy(Bool)) -> Bool =>
	case x
	of true true
	of false y

`not` = (x: Bool) -> Bool =>
	case x
	of true false
	of false true

#
# Array
#

List = (A: Type) -> Type => Record(items: Ptr(A), len: Size = 0, cap: Size = 0)

#
# String
#

Str = opaque Ptr(U8)

concat : (left right: Str) -> Str

join : (items: Args(List(Str)); start sep end: Str) -> Str

split : (it: Str, separator: Str; count: ?Int = none) -> List(Str)

has-prefix = (it prefix: Str) -> Bool =>
	it.len >= prefix.len and it[:prefix.len] == prefix

has-suffix = (it suffix: Str) -> Bool =>
	it.len >= suffix.len and it[it.len - suffix.len:] == suffix

to-upper : (it: Str) -> Str

to-lower : (it: Str) -> Str

to-title : (it: Str) -> Str

contains : (it substring: Str) -> Bool

index : (it substring: Str) -> ?U64

left-pad : (it: Str, width: U64, fill: Str = ' ') -> Str

replace : (it old new: Str; count: ?Int = none) -> Str

exit : (code: Int) -> Unit

#
# IO
#


File-Handle = opaque Size

stdin  = 0 as File-Handle
stdout = 1 as File-Handle
stderr = 2 as File-Handle

open : (path: Str, mode = 'r') -> File-Handle

close : (file: File-Handle) -> Unit

read : (file = stdin, bytes: ?Size = none) -> Str

write : (file = stdout, string: Str) -> Unit

print = (file = stdout, values: Args(List(Str)); sep = ' ', end = '\n') -> Unit =>
	if values.len > 0
		write(file, values[0])
		for x in values
			write(file, sep)
			write(file, x)
	write(file, end)

#
# List (Dynamic Array)
#


#[

Iterator = (A: Type) -> Type => Record(array: Ptr(List(A)), index: Size = 0)

Sized = Record(len: Size, ..R)

empty = (it: Sized) -> Bool => it.len == 0

head = (A: Type = _, it: List(A)) -> A => if empty(it) none else it[0]

last = (A: Type = _, it: List(A)) -> A => if empty(it) none else it[it.len - 1]

tail = (A: Type = _, it: List(A)) -> A => it[1:]

init = (A: Type = _, it: List(A)) -> A => it[0:-2]

slice = (A: Type = _, it: List(A), i j: Size) -> List(A) =>
	i2 = if i < 0 it.len + i else i
	j2 = if j < 0 it.len + j else j
	(len=j2 - i2, buf=offset(xs.buf, i2))

iterator = (A: Type = _, it: Ptr(List(A))) -> Iterator(A) =>
	(array=it, index=0)

next = (A: Type = _, it: Iterator(A)) -> A =>
	it.index += 1
	it.array[it.index]

#empty = (A: Type = _, it: Iterator(A)) -> Bool =>
#	it.index >= it.array.count

get-item = (A: Type = _, it: List(A), index: Size) -> A =>
	memory(offset(it.items, index * size(A)))

set-item = (A: Type = _, it: List(mut A), indAex: Size, value: A) -> Unit =>
	copy(&value, offset(it.items, index * size(A)), size(A))

resize = (A: Type = _, it: Ptr(List(mut A)), capacity: Size) -> Unit =>
	items := allocate(mut A, capacity)
	copy(it.items, items, min(it.count, capacity) * size(A))
	release(it.items)
	it.capacity := capacity # copy number
	it.items := items # copy pointer

append = (A: Type = _, it: List(A), value: A) -> Unit =>
	if it.count >= it.capacity resize(it, it.count * 2)
	it.items[it.count] := value # copy
	it.count += 1

for-each = (A: Type = _, it: List(A), operation: A -> Unit) =>
	i: mut Size := 0
	while i <= it.count:
		operation(it.items[i])
		i += 1

map = (A: Type = _, B: Type = _, items: List(A), transform: A -> B) -> List(B) =>
	result : mut [B]
	result := []
	for item in items
		append(item, result)
	result

reduce = (A: Type = _, items: List(A), initial: A, combine: (A, A) -> A) -> A =>
	result : mut A
	for item in items
		result := combine(result, item)
	result

filter = (A: Type = _, items: List(A), predicate: A -> Bool) -> List(A) =>
	result : mut [A]
	result := []
	for item in items
		if predicate(item)
			append(item, result)
	result

all = (A: Type = _, items: List(A), predicate: A -> Bool) -> List(A) =>
	for item in items
		if not predicate(item)
			return false
	true

any = (A: Type = _, items: List(A), predicate: A -> Bool) -> List(A) =>
	for item in items
		if predicate(item)
			return true
	false

Bucket = (A: Type) => Record(items: [A])

Bucket-Array = (A: Type) =>
	Record(buckets: [Bucket(A)])

Iterator = (A: Type) => Record(
	array: Bucket-Array(A)
	bucket: mut Size := 0
	item: mut Size := 0
)

empty = (it: Iterator(A)) =>
	it.bucket >= it.array.count

next = (it: Iterator(A)) =>
	if it.item >= it.array.buckets[it.bucket].count
		it.bucket += 1
		it.item := 0
	else
		it.item += 1
	it.array.buckets[it.bucket].items[it.item]

for-each = (it: Bucket-Array(A), operation: A -> Unit) =>
	for bucket in it.buckets
		for item in bucket.items
			operation(item)

]#
