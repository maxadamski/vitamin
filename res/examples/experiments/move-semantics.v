
### Move protocol

Move(T: Type) = Struct(
	delete : (x: &mut T) -> Unit
	move : (x: &mut T, y: T) -> Unit
	copy : (x: &mut T, y: T) -> Unit
)

use Move

#delete(T: Type, ev: Move(T) = _, x: &mut T) = ev.delete(x)
#move(T: Type, ev: Move(T) = _, x: &mut T, y: T) = ev.move(x, y)
#copy(T: Type, ev: Move(T) = _, x: &mut T, y: T) = ev.copy(x, y)

Seq(cap: Cap = imm, T: Type) = Struct(
	data: &cap T | None
	len cap: Size
)

Move-Seq(T: Type) = Move(Seq(mut, T))(

	## Destructor
	delete(x: @move &mut Seq(mut, T)) -> Unit =
		if x.data
			for i in range(x.len)
				delete(x.data[i])
			free(x.data)

	## Copy assignment
	copy(x: &mut Seq(mut, T), y: Seq(mut, T)) -> Unit =
		if x.data == y.data return
		delete(x)
		x.len, x.cap := y.len, y.cap
		if y.data
			x.data := new(cap, t, x.cap)
			for i in range(x.len)
				x.data[i] := y.data[i]

	## Move assignment
	move(x: &mut Seq(mut, T), y: @move Seq(mut, T)) -> Unit =
		delete(x)
		x.len, x.cap, x.data := b.len, b.cap, b.data

)
