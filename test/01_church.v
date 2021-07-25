N : Type
z : N
s : N -> N

Num  = (A: Type) -> (f: A -> A) -> (x: A) -> A

zero = (A: Type) => (f: A -> A) => (x: A) => x

xtest "zero"
    assert type-of(zero(N)) == ((f: N -> N) -> (x: N) -> N)
    assert type-of(zero(N)(s)) == ((x: N) -> N)
    assert type-of(zero(N)(s)(z)) == N
    assert zero(N)(s)(z) == z

one = (A: Type) => (f: A -> A) => (x: A) => f(x)

xtest "one"
	assert one(N)(s)(z) == s(z)

two = (A: Type) => (f: A -> A) => (x: A) => f(f(x))

xtest "two"
	assert two(N)(s)(z) == s(s(z))

three = (A: Type) => (f: A -> A) => (x: A) => f(f(f(x)))

xtest "three"
	assert three(N)(s)(z) == s(s(s(z)))

xtest "add"
    add = (m n: Num) => (A: Type) => (f: A -> A) => (x: A) => m(A)(f)(n(A)(f)(x))
    assert add(one, one)(N)(s)(z) == s(s(z))
    assert add(one, two)(N)(s)(z) == s(s(s(z)))
    assert add(two, two)(N)(s)(z) == s(s(s(s(z))))
    assert add(one, three)(N)(s)(z) == s(s(s(s(z))))

xtest "mul"
    mul = (m n: Num) => (A: Type) => (f: A -> A) => (x: A) => m(A)(n(A)(f))(x)
    assert mul(one, two)(N)(s)(z) == s(s(z))
    assert mul(one, three)(N)(s)(z) == s(s(s(z)))
    assert mul(two, two)(N)(s)(z) == s(s(s(s(z))))
    assert mul(two, three)(N)(s)(z) == s(s(s(s(s(s(z))))))

