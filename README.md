The Vitamin Programming Language
================================

Vitamin grants you great power you need it, and doesn't get in your way, when you don't.


## Features

- [x] Clear semantics
- [x] Rich and safe type system
- [x] Potential for speed
- [x] Powerful metaprogramming
- [x] Helpful compiler


## Get a taste

Get to know Vitamin with some example programs.

For a complete description see the [language reference manual](docs/manual.md).

**Simple Fizz Buzz**

```vitamin
fizzbuzz = (i: Int) =>
	if   i mod 15 == 0 'FizzBuzz'
	elif i mod  3 == 0 'Fizz'
	elif i mod  5 == 0 'Buzz'
	else to-string(i)

for i in 1..100
	print(fizzbuzz(i))
```


**Type-safe sized vectors**

```vitamin
# Vectors of length `n` and element type `a` are pointers to mutable `a` 
Vector = unique (n: Size, a: Type) -> Type => &mut a

# Parameters `n`, `m` and `a` will be computed and passed implicitly
concat = (n m: Size = _, a: Type = _, x: Vector(n, a), y: Vector(m, a)) -> Vector(n+m, a) =>
	items = new-mutable(a, count=n+m)
	copy(from=x.items, to=items, count=n)
	copy(from=y.items, to=offset(items, n), count=m)
	items

result = concat([1 1 2], [3 5])
assert result is Vector(5, Int)
```

## How to run


Vitamin expects the `RXPATH` environmental variable to be set to the path containing the contents of `res/lib`.

The `rx` tool requires Python 3.7 or later. 

```sh
# assuming rx is in PATH
# run a program
rx script.v
# run an interactive session
rx
```

## Contributions

Feel free to open issues to ask questions or make suggestions.

Contributions are very welcome.
