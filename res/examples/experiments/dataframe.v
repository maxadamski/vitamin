
make-record-type : (types: Ordered-Map(Str, Type)) -> Type

opaque Frame(types: Ordered-Map(Str, Type)) = Struct(
	length: Size
	columns: make-record-type(types.map-value(t => Array(&mut t, length)))
)

with (types: Ordered-Map(Str, Type) = _, frame: Frame(types))

	get-col(name: Str) -> Array(types[name], frame.length) =
		frame.columns[name]

	get-row(index: Size) -> make-record-type(types) =
		row : make-record-type(types)
		for name, type in types:
			row[name] := frame.columns[name][index]
		row

	get-cell : (col-name: Str, row-index: Size) -> types[name] =
		frame.columns[col-name][row-index]
