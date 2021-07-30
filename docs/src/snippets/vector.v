# Vectors of length `n` and element type `a` are pointers to mutable values of type `a`
unique Vector(n: Size, a: Type) = Record(items: &mut a)

# Parameters `n`, `m` and `a` will be computed and passed implicitly
concat(x: Vector($n, $a), y: Vector($m, a)) -> Vector(n + m, a) =
  items = new(mut, a, count=n + m)
  copy(from=x.items, to=items, count=n)
  copy(from=y.items, to=offset(items, n), count=m)
  (items=items) as Vector(n + m, a)

# Assume these vectors are defined somewhere else
a : Vector(3, Int)
b : Vector(2, Int)
assert type-of(concat(a, b)) == Vector(5, Int)
