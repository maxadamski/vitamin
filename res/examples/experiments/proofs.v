
# function with a proof as an implicit parameter
safe-index(array: [A], index: U64; in-bounds: Proof(0 <= index < array.len) = _) -> A =
	array[index]

a = [1 2 3 4]

# read an integer from the command line
i = to-int(read-line())

# invalid - no guarantee, that `i` is a valid index

assert is-error(safe-index(a, i))

# valid - proof that `i` is in bounds is implicitly computed during compilation

if 0 <= i < a.len
	# proofs are implicitly inferred from if/match/defer expressions
	assert is-correct(safe-index(a, i))

# vaild - proofs can be explicitly assigned to variables

if proof-1 = proof(0 <= i < a.len)
	# proofs are just values
	print(proof-1)
	assert is-correct(safe-index(a, i, in-bounds=proof-1)

# valid - proofs can be computed at runtime

proof-2 = impure-runtime-bounds-check(i, min=0, max=a.len)
if proof-2:
	assert is-correct(safe-index(a, i, in-bounds=proof-2))
