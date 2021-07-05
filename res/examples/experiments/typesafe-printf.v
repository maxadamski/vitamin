Format-Params(format: String) -> Type =
	format = format.strip-left-except("%")
	if format.empty
		return Unit

	type = case format.head
	of 's' Str
	of 'd' Int
	of other fatal('unsupported string format %\(other)')

	return (type -> Format-Params(format.tail))

# method 0: nothing special (verbose)
printf-0 : (format: String) -> Format-Params(format)
printf-0("Name: %s, Age: %d")("Joe")(22)

# method 1: autoapply
printf-1 : autoapply (format: String) -> Format-Params(format)
printf-1("Name: %s, Age: %d", "Joe", 22)

# method 2: function type splice (harder to implement?)
printf-2 : (format: String, ..Format-Params(format)) -> Unit
printf-1("Name: %s, Age: %d", "Joe", 22)

