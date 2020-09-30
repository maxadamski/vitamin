Bucket = (A: Type) => { items: [A] }

Bucket-Array = (A: Type) => { buckets: [Bucket(A)] }

Iterator = (A: Type) => {
	array: Bucket-Array(A)
	var bucket: Size := 0
	var item: Size := 0
}

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
