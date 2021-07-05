var i := 1
while i < len(args)
	if args[i] not in ['-i' '-F' '-h'] break
	i += 1
o = args[:i]
if '-h' in o
	panic('usage: grep [-F] [i] regexp [files...]')
r = args[i]
r = sub(r, '\W', '\\' + $0.group(0)) if '-F' in o else r
r = compile(r, ignore-case='-i' in o)
F = args[i:]
for f in F
	p = f + ':' if len(F) > 1 else ''
	for l in read-lines(f).filter(search)
		print(p + l)
