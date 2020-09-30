var i := 1
while i < len(args)
	if args[i] not in ['-i' '-F' '-h'] do break
	i += 1
o = args[:i]
if '-h' in o do panic('usage: grep [-F] [i] regexp [files...]')
r = args[i]
r = if '-F' in o do sub(r, '\W', '\\' + $0.group(0)) else r
r = compile(r, ignore-case='-i' in o)
F = args[i:]
for f in F
	p = if len(F) > 1 do f + ':' else ''
	for l in read-lines(f).filter(search)
		print(p + l)
