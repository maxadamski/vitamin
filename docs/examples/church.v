Nat : Type
z : Nat
s : Nat -> Nat

Num  = (A: Type) -> (A -> A) -> (A -> A)
zero = (A: Type) => (f: A -> A) => f
one  = (A: Type) => (f: A -> A) => (x: A) => f(f(x))
add = (m, n: Num) => (A: Type) => (f: A -> A) => (x: A) => m(A)(f)(n(A)(f)(x))
mul = (m, n: Num) => (A: Type) => (f: A -> A) => (x: A) => m(A)(n(A)(f))(x)
two = add(one, one)
mul(two, two)
print(two(N)(s)(z))
