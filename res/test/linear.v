# test linear types

Handle = unique {fd: Size}

open = (path: String) -> Handle =>
	Handle(fd=Sys.open(path))

write = (handle: Handle, bytes: &U8) -> Size =>
	Sys.write(handle.fd, bytes)

close = (handle: move Handle) -> Unit =>
	Sys.close(handle.fd)
	drop handle

test-error 'unused resource at the end of the scope'
	f = open('foo.txt')
	# error: unused resource `f`, drop the resource to silence this error

test-error 'move after move'
	f = open('foo.txt')
	close(f)
	close(f)
	# error: attempting to move resource `f`, which is already moved.

test 'move after copy'
	f = open('foo.txt')
	write(f, 'hello, world!')
	close(f)
