# Solving the expression problem with "type classes".
# This should have no runtime overhead.

# 1. initial data types and oprations

Lit = Record(val: Int)
Add = Record(lhs, rhs: Int)

use Eval = (a: Type) => Record(eval: a -> Int)
#eval = (self: Eval(a), x: a) -> Str => self.eval(x)

use Show = (a: Type) => Record(show: a -> Str)
#show = (self: Show(a), x: a) -> Str => self.show(x)

use Eval-Lit = (eval = (x: Lit) => x.val)
use Eval-Add = (eval = (x: Add) => x.lhs + x.rhs)
use Show-Lit = (show = (x: Lit) => '\(x.val)')
use Show-Add = (show = (x: Add) => '\(x.lhs) + \(x.rhs)')

# 2. adding a new operation

use Hash = (a: Type) => Record(hash: a -> Int)
#hash = (self: Hash(a), x: a) -> Int => self.hash(x)

use Hash-Lit = (hash = (x: Lit) => hash-int(x.val))
use Hash-Add = (hash = (x: Add) => hash-int(x.lhs + x.rhs))

# 3. Adding a new data type

Sub = {lhs rhs: Int}

use Eval-Sub = (eval = (x: Sub) => x.lhs - x.rhs)
use Show-Sub = (eval = (x: Sub) => '\(x.lhs) - \(x.rhs)')
use Hash-Sub = (eval = (x: Sub) => hash-int(x.lhs - x.rhs))

