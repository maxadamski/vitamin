fizzbuzz = (x: Int) =>
	if   i mod 15 == 0 'FizzBuzz'
	elif i mod  3 == 0 'Fizz'
	elif i mod  5 == 0 'Buzz'
	else to-string(i)

main = (args: [String]) =>
	count = to-int(args[1])
	for i in 1..count
		print(fizzbuzz(i))
