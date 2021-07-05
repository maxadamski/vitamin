Parametric-Module = (

	# parametric module
	Vector-Math = (a: Type) => (
		Vec3 = {x y z: a}
		add = (p q: a) -> Vec3 => (x=p.x+q.x, y=p.y+q.y, z=p.z+q.z}
		mul = (p q: a) -> Vec3 => (x=p.x*q.x, y=p.y*q.y, z=p.z*q.z}
	)

	# instantiate a module for a value
	Vector-Math-F64 = Vector-Math(F64)
	Vector-Math-F32 = Vector-Math(F32)

	# bring module members into scope  
	use Vector-Math-F64

	# alternatively: use Vector-Math(F64)

)

Selective-Export = (

	Public = (

		Internal = (
			foo = 42
			bar = 'secret'
		)

		use Internal.foo
	)

	use Public
	Public.foo # ok
	Public.bar # error: no bar in Public

)
