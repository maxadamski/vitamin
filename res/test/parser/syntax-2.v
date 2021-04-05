
x : Int = 42

print(x, y, z)

x => y => z

x + y + z

if x
	a
	b
else
	c
	d

if a
	b
elif c
	d
	if x
		u
	elif y
		v
	else
		w
else
	e

if x == y and not y do foo else bar

while x one-liner

while x do print(2 + 2)

while true
	hello
	if a
		world
	else
		whatever

a = 1 * 2 + 3
b = (1 + 2) * 3
c = (1 * 2) + 3
d = 1 + 2 * 3
e = 1 + (2 * 3)
f = 1 * (2 + 3)

x = p and q or u and v
x = not y
x = a xor x == y
#x = a xor b or c
return 2
break
continue

g = (x: Int = 2, y: Float, z: Str = 'hello') -> Bool =>
	print('hello, world')
	exit(0)
	g = x =>
		y
		z

h = (A: Type, class: Additive(A), x, y: A) -> A => 
	class.add(x, y)

#x = [a, b, c]

#x = (a, b, c; d, e; f)

return (8 + 16)

print(hello, world, end='\n\n', hello='heoi', world='otin')

case a
of b
	c
	d
of d
	e
	f
of _
	d

case
of (i mod 2 == 0) print('even')
of _ print('odd')

if a do (if b c else d) else e

if true
	case q
	of x
		a
	of y
		b
		c
	return x

return x

case of a b of c d

if a do (if b do c else d)
if a do (if b do c) else d

x[]
x[1]
x[1,2,3]
x[1,2,3,]

f()
f(x)
f(x,y,z)
f(x,y,z,)

# TODO: implement trailing lambdas
#trailing-lambda() with x => x*2
#
#router.get() with req => 'hello, world'
#
#request('GET', 'someurl') with
#	on-success = res =>
#		2 + 2
#		print(res)
#	on-error = () =>
#		print('couldn\'t get someurl')
#		exit(1)
#
#router.get('/me/items/{id}') with
#	(id: Int, session = Depends(user_session)) =>
#		db.get_item(id=id, user_id=session.user_id)

f = (x, y : T) -> T

f = (u: U, v: V, x, y: T, z: T = a) -> T

f = T -> Int

#t = {x: Int = 42, y z: Int, p = q}
t = Record(A, B, C)

(a, b, c)

(x=a, y=b, z=c)

(x, y) => x

#[1 2 3 4 5, 6 7 8 9; 10 11 12 13, 14 15 16 17]
#[1;2;3]

#a[,,,]
#a[,2,]
#a[1,,3,]
a[1,2,3,]
#a[,2,3]

p()
p(1,2)
p(1,2,)

()
#(,)
(x=2, y=2)

#[1, 2, 3, 4]

foo : (x, y: A) -> B

x =>
	y
	z
