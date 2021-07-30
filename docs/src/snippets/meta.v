dump(expr: Quoted(Expr)) -> Expand(Expr) =
	quote print(quote $expr, ' = ', $expr)
    
dump(1 + 2) # will print `1 + 2 = 3`