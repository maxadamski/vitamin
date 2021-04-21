
#
# Core
#

U8, U64 : Type

I8, I64 : Type

F64 : Type

Size = U64

Int = I64

Float = F64

Bool = opaque U8
true = 1 as Bool
false = 0 as Bool

None = opaque U8
none = 0 as None

Ptr = opaque (a: Type) -> Type => Size

Unit = Record()

Never = Inter()

Any = Union()

Term, Atom : Type

Expr = Term | Atom

`assert` : (x: Untyped) -> Unit

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

`and` = (x y: lazy Bool) -> Bool =>
	if x y else false

`or` = (x y: lazy Bool) -> Bool =>
	if x true else y

`not` = (x: Bool) -> Bool =>
	if x false else true

#
# String
#

Str = opaque Ptr(U8)

concat : (left right: Str) -> Str

join : (items: ..Str; start sep end: Str) -> Str

split : (it: Str, separator: Str; count: ?Int = none) -> [Str]

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

read : (file = stdin, bytes: Size|None = none) -> Str

write : (file = stdout, string: Str) -> Unit

print = (file = stdout, values: ..Str; sep = ' ', end = '\n') =>
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
List = (A: Type) => Record(items: &A, len: Size = 0, cap: Size = 0)

Sized = Record(len: Size, ...)

`[` = (A: Type) => Dynamic-Array(A)

Iterator = (A: Type) => Record(array: &[A], index: Size = 0)

empty = (it: Sized) => it.len == 0

head = (it: [A]) => if empty(it) none else it[0]

last = (it: [A]) => if empty(it) none else it[it.len - 1]

tail = (it: [A]) => it[1:]

init = (it: [A]) => it[0:-2]

slice = (it: [A], i j: Size) =>
	i2 = if i < 0 it.len + i else i
	j2 = if j < 0 it.len + j else j
	(len=j2 - i2, buf=offset(xs.buf, i2))

iterator = (it: &[A]) -> Iterator(A) =>
	(array=it, index=0)

next = (it: Iterator(A)) -> A =>
	it.index += 1
	it.array[it.index]

empty = (it: Iterator(A)) -> Bool =>
	it.index >= it.array.count

get-item = (it: [A], index: Size) -> A =>
	memory(offset(it.items, index * size(A)))

set-item = (it: [mut A], index: Size, value: A) -> Unit =>
	copy(&value, offset(it.items, index * size(A)), size(A))

resize = (it: & mut [A], capacity: Size) -> Unit =>
	items := allocate(mut A, capacity)
	copy(it.items, items, min(it.count, capacity) * size(A))
	release(it.items)
	it.capacity := capacity # copy number
	it.items := items # copy pointer

append = (it: mut [A], value: A) -> Unit =>
	if it.count >= it.capacity resize(it, it.count * 2)
	it.items[it.count] := value # copy
	it.count += 1

for-each = (it: [A], operation: A -> Unit) =>
	i: mut Size = 0
	while i <= it.count:
		operation(it.items[i])
		i += 1

map = (items: [A], transform: A -> B) -> [B] =>
	result : mut [B]
	result := []
	for item in items
		append(item, result)
	result

reduce = (items: [A], initial: A, combine: (A, A) -> A) -> A =>
	result : mut A
	for item in items
		result := combine(result, item)
	result

filter = (items: [A], predicate: A -> Bool) -> [A] =>
	result : mut [A]
	result := []
	for item in items
		if predicate(item)
			append(item, result)
	result

all = (items: [A], predicate: A -> Bool) -> [A] =>
	for item in items
		if not predicate(item)
			return false
	true

any = (items: [A], predicate: A -> Bool) -> [A] =>
	for item in items
		if predicate(item)
			return true
	false

Bucket = (A: Type) => Record(items: [A])

Bucket-Array = (A: Type) => Record(buckets: [Bucket(A)])

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