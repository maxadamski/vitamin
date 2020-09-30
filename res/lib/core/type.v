`not` = (x: Bool) -> Bool => if x == true do false else true

`and` = (x y: Bool) -> Bool => if x do y else false

`or`  = (x y: Bool) -> Bool => if x do true else y

`xor` = (x y: Bool) -> Bool => x != y

`?` = Optional

`mut` = Mutable

`imm` = Immutable

`??` : (it: ?A, default: A) -> A

use object
	value : (x: mut A) -> A

use object
	value : (x: imm A) -> A

`===` : (x y: A) -> Bool

`!==` = (x y: A) -> Bool => not x === y

