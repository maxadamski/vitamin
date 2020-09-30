Format-Params = (mut format: String) -> Type =>
	while head(format) != '%' do format := tail(format)
	if empty(format) return Unit
	if head(format) == 's'
		return String -> Format-Params(tail(format))

printf : (format: String) -> Format-Params(format)
