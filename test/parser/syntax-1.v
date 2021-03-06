# This file contains basic syntax tests

x < y < z < q < v

x > y < z < x

x == y < z == z

x == y != z

x => y => z

not x

p and q or u and v

p or q and u or v

2 + 3

2 * 3

2 + 3 + 4

2 * 3 * 4

2 + 3 * 4

(2 + 3) * 4

2 * 3 + 4

2 * 3 ^ 4

2 ^ 3 * 4

2 ^ 3 ^ 4

-x ^ y

x ^ -y + z

x := y := z

x.y := z

x

x, y

x, y, z

x, y, z := a, b, c

p, q = u, v

(y)

f()

f(x)

f(x,)

f(x, y)

f(x, y,)

f(x, y, z)

f(x, y, z,)

f(x=a)

f(x=a,)

f(x=a, y=b)

f(x=a, y=b,)

f(x=a, y=b, z=c)

f(x=a, y=b, z=c,)

()

(x)

(x,)

(x, y)

(x, y,)

(x, y, z)

(x, y, z,)

(x=a)

(x=a,)

(x=a, y=b)

(x=a, y=b,)

(x=a, y=b, z=c)

(x=a, y=b, z=c,)


x.y() := z

a.b().c().d := e.f()

while x: y

while x:
    y

while x:
    y
    z

for x in y: a

for x in y:
    a

for x in y:
    a
    b

case of c1: e1

case of c1: e1 of c2: e2

case
of c1: e1

case
of c1: e1
of c2: e2

case
of c1:
    e1
    f1

case
of c1:
    e1
    f1
of c2:
    e2
    f2

case
of c1:
    e1
    f1
of c2:
    e2
    f2

    
case x of c1: e1

case x of c1: e1 of c2: e2
    
case x
of c1: e1

case x
of c1: e1
of c2: e2

case x
of c1:
    e1
    f1

case x
of c1:
    e1
    f1
of c2:
    e2
    f2

if c1: e1

if c1: e1 else: e2

if c1: e1 elif c2: e2

if c1: e1 elif c2: e2 elif e3: e3

if c1: e1 elif c2: e2 elif c3: e3 else: e4

if c1: if c2: e1 else: e2

if c1:
    e1
    e2

if c1:
    e1
    e2
else:
    e3
    e4

if c1:
    e1
    e2
elif c2:
    e3
    e4

if c1:
    e1
    e2
elif c2:
    e3
    e4
elif c3:
    e5
    e6

if c1:
    e1
    e2
elif c2:
    e3
    e4
elif c3:
    e5
    e6
else:
    e7
    e8

if a:
    e1
    if b:
        e2
        e3
    else:
        e4
        e5
else:
    e5
    e6

f = x => y

f = x =>
    y
    z

x => y

x =>
    y

x =>
    y
    z

x = (x: A, y: B) -> R => f

(a,

    b,
    c,)

hello = (x: String) =>
    print(x)
    exit(0)
    if x:
        e2
        e3
    else:
        e4
        e5

use (x=2, y=3)

#use if x y else z

if x:
	case q
	of x:
		a
	of y:
		b
		c

return x

if x:
    use z
    y
else:
    a
    b

(
    a
    b
    c
)

f(
    p,
    q,
    u,
    v,
)

x -> y -> z

x => y => z

if x y else z

x, y, z = y, z, x

x, y, z, = a, b, c

x, y, z, = a, b, c

x, = a, b, c

x, y, z = f(a, b, c)

s = xs.map(to-string).filter(it != "").reduce(`+`)