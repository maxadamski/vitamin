# Solving the expression problem with "type classes".
# This should have no runtime overhead.

# 1. initial data types and oprations

Lit = {val: Int}
Add = {lhs rhs: Int}

Eval = (a: Type) => { eval: a -> Int }
use-protocol Eval
#eval = (ev: Eval(A) = _, x: A) -> Int => ev.eval(x)

Show = (a: Type) => { show: a -> Str }
use-protocol Show
#show = (ev: Show(A) = _, x: A) -> Str => ev.show(x)

Eval-Lit = (eval = (x: Lit) => x.val)
Eval-Add = (eval = (x: Add) => x.lhs + x.rhs)
Show-Lit = (show = (x: Lit) => '\(x.val)')
Show-Add = (show = (x: Add) => '\(x.lhs) + \(x.rhs)')

# 2. adding a new operation

Hash = (a: Type) => { hash: a -> Int }
use-protocol Hash
#hash = (ev: Hash(A) = _, x: A) -> Int => ev.hash(x)

Hash-Lit = (hash = (x: Lit) => hash-int(x.val))
Hash-Add = (hash = (x: Add) => hash-int(x.lhs + x.rhs))

# 3. Adding a new data type

Sub = {lhs rhs: Int}

Eval-Sub = (eval = (x: Sub) => x.lhs - x.rhs)
Show-Sub = (eval = (x: Sub) => '\(x.lhs) - \(x.rhs)')
Hash-Sub = (eval = (x: Sub) => hash-int(x.lhs - x.rhs))

