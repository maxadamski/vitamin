import 'core'
import 'string.v'

Handle = unique Size

stdin  = Handle(0)
stdout = Handle(1)
stderr = Handle(2)

open : (path: String, mode: String = 'r') -> Handle

close : (file: Handle) -> Unit

read : (file: Handle = stdin, bytes: Size = -1) -> String

write : (file: Handle = stdout, string: String) -> Unit

print = (file = stdout, values: ..String; sep = ' ', end = '\n') =>
	if values.len > 0
		write(file, values[0])
		for x in values
			write(file, sep)
			write(file, x)
	write(file, end)

