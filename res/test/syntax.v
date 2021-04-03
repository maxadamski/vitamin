# This file contains basic syntax tests

not x

p and q or u and v

p or q and u or v

2 + 3

2 * 3

2 + 3 + 4

2 * 3 * 4

2 + 3 * 4

2 * 3 + 4

2 * 3 ^ 4

2 ^ 3 * 4

2 ^ 3 ^ 4

-x ^ y

x ^ -y + z

x := y := z

x.y := z

x.y() := z

a.b().c().d := e.f()

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

while x y

while x do y

while x
    y

while x do
    y

while x
    y
    z

while x do
    y
    z

for x in y a

for x in y do a

for x in y
    a

for x in y do
    a

for x in y
    a
    b

for x in y do
    a
    b
    
case of c1 e1

case of c1 do e1

case of c1 e1 of c2 e2

case of c1 do e1 of c2 do e2

case
of c1 e1

case
of c1 do e1

case
of c1 e1
of c2 e2

case
of c1 do e1
of c2 do e2

case
of c1
    e1
    f1

case
of c1 do
    e1
    f1

case
of c1
    e1
    f1
of c2
    e2
    f2

case
of c1 do
    e1
    f1
of c2 do
    e2
    f2

    
case x of c1 e1

case x of c1 do e1

case x of c1 e1 of c2 e2
    
case x of c1 e1

case x of c1 do e1

case x of c1 e1 of c2 e2

case x of c1 do e1 of c2 do e2

case x
of c1 e1

case x
of c1 do e1

case x
of c1 e1
of c2 e2

case x
of c1 do e1
of c2 do e2

case x
of c1
    e1
    f1

case x
of c1 do
    e1
    f1

case x
of c1
    e1
    f1
of c2
    e2
    f2

case x
of c1 do
    e1
    f1
of c2 do
    e2
    f2

if c1 e1

if c1 do e1

if c1 e1 else e2

if c1 do e1 else e2

if c1 e1 elif c2 e2

if c1 do e1 elif c2 do e2

if c1 e1 elif c2 e2 elif e3 e3

if c1 do e1 elif c2 do e2 elif e3 e3

if c1 e1 elif c2 e2 elif c3 e3 else e4

if c1 do e1 elif c2 do e2 elif c3 do e3 else e4

if c1 if c2 e1 else e2

if c1
    e1
    e2

if c1
    e1
    e2
else
    e3
    e4

if c1
    e1
    e2
elif c2
    e3
    e4

if c1
    e1
    e2
elif c2
    e3
    e4
elif c3
    e5
    e6

if c1
    e1
    e2
elif c2
    e3
    e4
elif c3
    e5
    e6
else
    e7
    e8

if a
    e1
    if b
        e2
        e3
    else
        e4
        e5
else
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

(a,

    b,
    c,)

hello = (x: String) =>
    print(x)
    exit(0)
    if x
        e2
        e3
    else
        e4
        e5

use (x=2, y=3)

use if x y else z

if x
    use z
    y
else
    a
    b