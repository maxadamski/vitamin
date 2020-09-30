import 'type.v'

Arch = [| x86-64, i386, arm64 |]
arch = Arch.x86-64

System = [| none, linux, macos, windows |]
system = System.linux

use if arch == Arch.i386 or arch == Arch.x86-64
	U8  = extern Type
	U16 = extern Type
	U32 = extern Type
	I8  = extern Type
	I16 = extern Type
	I32 = extern Type
	F32 = extern Type

use if arch == i386
	Int   = unique I32
	Float = unique F32
	Size  = unique U32

use if arch == x86-64
	U64   = extern Type
	I64   = extern Type
	F64   = extern Type
	Int   = I64
	Float = F64
	Size  = U64

#Arithmetic = (num: Type; with-modulo = true) => object
#	`+`   : (x y: num) -> num
#	`-`   : (x y: num) -> num
#	`*`   : (x y: num) -> num
#	pow   : (x y: num) -> num
#	`/`   : (x y: num) -> Float
#	`div` : (x y: num) -> Int
#	`>`   : (x y: num) -> Bool
#	`<`   : (x y: num) -> Bool
#	`<=`  : (x y: num) -> Bool
#	`>=`  : (x y: num) -> Bool
#
#	use if with-modulo
#		`mod` : (x y: num) -> num
#
#use if arch == i386 or arch == x86-64
#	use Arithmetic(U8)
#	use Arithmetic(U16)
#	use Arithmetic(U32)
#	use Arithmetic(I8)
#	use Arithmetic(I16)
#	use Arithmetic(I32)
#	use Arithmetic(F32, with-modulo=false)
#
#use if arch == x86-64
#	use Arithmetic(U64)
#	use Arithmetic(I64)
#	use Arithmetic(F64, with-modulo=false)

