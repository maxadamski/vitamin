AtomTag = [| symbol, string, number |]

TermTag = [| prefix, suffix, infix, distfix |]

Expr = Atom | Term

Atom = { value: String, tag: AtomTag }

Term = { nodes: [Expr], tag: TermTag }

Row = { name: String, type: Type, value: Expr }

StringLiteral = Atom

NumberLiteral = Atom
