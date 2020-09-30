`&` = Pointer

allocate : (A: Type; count: Size = 1, fill: ?A = none, stack = false) -> &A

free : (pointer: & mut A) -> Unit

copy : (dst: & mut A, src: &A; count: Size = 1) -> Unit

move : (dst: & mut A, src: & mut A) -> Unit

copy : (dst: & mut A, src: A) -> Unit

offset : (it: &A, bytes: Size) -> &A

value : (src: &A) -> A

use object
	address : (it: mut A) -> & mut A
	`&` = address

use object
	address : (mem: imm A) -> & imm A
	`&` = address

