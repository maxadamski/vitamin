fizzbuzz = (x: Int) =>
	case
	of i mod 15 == 0 'FizzBuzz'
	of i mod  3 == 0 'Fizz'
	of i mod  5 == 0 'Buzz'
	of to-string(i)

count = to-int(args[1])
for i in irange(1, count)
	print(fizzbuzz(i))
