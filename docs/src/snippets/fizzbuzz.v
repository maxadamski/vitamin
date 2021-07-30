main() =
	for i in range(0, 100)
        var x := ''
        case
        of i mod 3 == 0 x += 'Fizz'
        of i mod 5 == 0 x += 'Buzz'
        of x == '' x := Str(i)
        print(x)