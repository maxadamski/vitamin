Bitwise = import('bitwise')

Bit-Generator = Record(
	seed: &mut Size
)

Random-Generator = Class(

	bit-generator : Bit-Generator

	random : () -> Float

	integer : (low high: Int) -> Int

	uniform(low high: Float) -> Float =
		low + (high - low) * random()

	normal(mu: Float = 0.0, sigma: Float = 1.0) -> Float =
		box-muller(random(), mu, sigma)

)

PCG64 = Record(
	state : &mut U64 := 0x4d595df4d0f33173
	multiplier : U64 = 6364136223846793005
	increment : U64 = 1442695040888963407
)

rotr32(x: U32, r: Size) -> U32 =
	use-syntax Bitwise.Ops
	x >> r | x << (-r band 31)

pcg32-next(self: PCG64) -> U32 =
	use-syntax Bitwise.Ops
	x := self.state
	count = (x >> 59) as Size
	self.state := x * self.multiplier + self.increment
	x ^= x >> 18
	rotr32((x >> 27) as U32, count)

pcg32-seed(self: PCG64, seed: U64) -> Unit =
	self.state := seed + self.increment
	discard pcg32-next()

rng = PCG64()
