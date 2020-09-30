for c in glob('**/*.c')
	o = c[:-1] + 'o'
	if not exists(o) or modify-time(o) < modify-time(c)
		print('compiling \(c) to \(o)')
		system("gcc -c -o '\(o)' '\(c)'")
