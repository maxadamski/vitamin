fib1 = (n: Int) =>
	if n > 1 fib1(n - 2) + fib1(n - 1) else n
	
fib2 = (n: Int) =>
	loop = (a, b, n: Int) =>
		if n > 0 loop(b, a + b, n - 1) else a
	loop(0, 1, n)

