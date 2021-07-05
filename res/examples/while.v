
`while`(cond body: Quoted(Expr)) -> Expand(Expr) =
	loop = gensym()
	quote
		$loop() =
			case $cond
			of true 
				$body
				$loop()
			of false
				()
		$loop()

i = ref(mut, Int, 0)
j = ref(mut, Int, 0)
while *i < 10
	j := 0
	while *j < 10
		print(*i, *j)
		j := *j + 1
	i := *i + 1