
`while` = (cond body: Quoted(Expr)) -> Expand(Expr) =>
	quote
		it = () =>
			case $cond
			of true 
				$body
				it()
			of false
				()
		it()
