import 'core'

Dynamic-Array = (A: Type) => { items: &A, len: Size = 0, cap: Size = 0 }

Sized = {len: Size, ...}

`[` = (A: Type) => Dynamic-Array(A)

Iterator = (A: Type) => { array: &[A], index: Size = 0 }

empty = (it: Sized) => it.len == 0

head = (it: [A]) => if empty(it) do none else it[0]

last = (it: [A]) => if empty(it) do none else it[it.len - 1]

tail = (it: [A]) => it[0,-1]

init = (it: [A]) => it[0,-2]

slice = (it: [A], i j: Size) =>
	i2 = if i < 0 do it.len + i else i
	j2 = if j < 0 do it.len + j else j
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
	if it.count >= it.capacity do resize(it, it.count * 2)
	it.items[it.count] := value # copy
	it.count += 1

for-each = (it: [A], operation: A -> Unit) =>
	i: mut Size = 0
	while i <= it.count
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

