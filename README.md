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

For a complete description see the [language reference manual](https://maxadamski.com/vitamin/manual.html).

Documentation and more examples are also mirrored on the [Vitamin language website](https://maxadamski.com/vitamin). Code excerpts on the website are easier to read, because they have syntax highligting!

**Simple Fizz Buzz**

```vita
fizzbuzz(i: Int) =
	case
	of i mod 15 == 0 'FizzBuzz'
	of i mod  3 == 0 'Fizz'
	of i mod  5 == 0 'Buzz'
	of _ Str(i)

for i in range(100)
	print(fizzbuzz(i))
```


**Type-safe sized vectors**

```vita
# Vectors of length `n` and element type `a` are pointers to mutable values of type `a`
unique Vector(n: Size, a: Type) = Record(items: &mut a)

# Parameters `n`, `m` and `a` will be computed and passed implicitly
concat(x: Vector($n, $a), y: Vector($m, a)) =
  items = new(mut, a, count=n + m)
  copy(from=x.items, to=items, count=n)
  copy(from=y.items, to=offset(items, n), count=m)
  (items=items) as Vector(n + m, a)

# Assume these vectors are defined somewhere else
a : Vector(3, Int)
b : Vector(2, Int)
assert type-of(concat(a, b)) == Vector(5, Int)
```

## How to compile

### Linux, macOS and other Unix-like

Requires Nim 1.4.2 and Nimble.

```sh
chmod +x build
# install dependencies
./build setup
# run tests (optional)
./build test
# compile for the current architecture
./build
```

Vitamin binary `vita` will appear in the `bin` directory.

### Windows

TODO


## How to run

By default, Vitamin expects the contents of `res/lib` to be present in `~/.local/lib/vita` or `/usr/lib/vita`. You can also add other library paths to the `VITAPATH` environment variable (paths separated by a colon `:`).

```sh
# assuming `vita` is in PATH
# run a program
vita script.v
# run an interactive session
vita
```


## Editor support

- Vim: basic syntax support
	- Copy `res/vitamin.vim` to the Vim/Neovim `syntax` directory
	- Add this to `.vimrc`: `au BufRead,BufNewFile *.{v,vita} set filetype=vitamin`

- Visual Studio Code: basic syntax support
	- Install the `Vitamin` extension (`ext install maxadamski.vitamin`)

## Contributions

Feel free to open issues to ask questions or make suggestions.

Contributions are very welcome.

