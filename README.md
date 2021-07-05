The Vitamin Programming Language
================================

Vitamin grants you great power you need it, and doesn't get in your way, when you don't.

**NOTE:** The language is currently a work-in-progress, so expect most things not to work!

## Features

- [x] Clear semantics
- [x] Rich and safe type system
- [x] Potential for speed
- [x] Powerful metaprogramming
- [x] Helpful compiler


## Get a taste

Get to know Vitamin with some example programs.

For a complete description see the [language reference manual](docs/manual.md).

Documentation and more examples are also mirrored on the [Vitamin language website](https://maxadamski.com/vitamin). Code excerpts on the website are easier to read, because they have syntax highligting!

**Simple Fizz Buzz**

```vitamin
fizzbuzz(i: Int) =
	case
	of i mod 15 == 0 'FizzBuzz'
	of i mod  3 == 0 'Fizz'
	of i mod  5 == 0 'Buzz'
	of _ to-string(i)

for i in irange(1, 100)
	print(fizzbuzz(i))
```


**Type-safe sized vectors**

```vitamin
# Vectors of length `n` and element type `a` are pointers to mutable `a` 
opaque Vector(n: Size, a: Type) = &mut a

# Parameters `n`, `m` and `a` will be computed and passed implicitly
concat(x: Vector($n, $a), y: Vector($m, a)) -> Vector(n+m, a) =
	items = new(mut a, count=n+m)
	copy(from=x.items, to=items, count=n)
	copy(from=y.items, to=offset(items, n), count=m)
	items as Vector(n+m, a)

result = concat([1 1 2], [3 5])
assert type-of(result) == Vector(5, Int)
assert result == [1 1 2 3 5]
```

## How to compile

### Linux, macOS and other Unix-like

Requires Nim 1.4.2 and Nimble.

```sh
chmod +x build
# install dependencies
./build setup
# compile for the current architecture
./build
```

Vitamin binary `vita` will appear in the `bin` directory.

### Windows

TODO


## How to run

Vitamin expects the `VITAPATH` environmental variable to be set to the path containing the contents of `res/lib`.

```sh
# assuming `vita` is in PATH
# run a program
vita script.v
# run an interactive session
vita
```


## Contributions

Feel free to open issues to ask questions or make suggestions.

Contributions are very welcome.

