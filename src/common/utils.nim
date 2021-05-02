import options, tables, sequtils, strutils, strformat, algorithm
export options, tables, sequtils, strutils, strformat, algorithm

# Flatten seq of seqs into seq

func flatten*[A](x: seq[seq[A]]) =
    x.foldl(a & b)

# Iterate a seq backwards

iterator reverse_iter*[T](a: seq[T]): T {.inline.} =
    var i = a.high
    while i > -1:
        yield a[i]
        dec(i)

# maximum function with a default value

proc max_or*(x: seq[int], default=0): int =
    if x.len == 0: default else: max(x)

# format a hexadecimal number

func hex_str*(x: uint64): string =
    var res = x.to_hex
    if x < 0x100000000'u64:
        res = res[8 .. ^1]
    "0x" & res

# Result/Either type

type ResultTag = enum ErrorResult, OkResult

type Result*[E, R] = object
    case kind*: ResultTag
    of ErrorResult:
        error*: E
    of OkResult:
        value*: R

func is_err*[E, R](x: Result[E, R]): bool = x.kind == ErrorResult

func is_ok*[E, R](x: Result[E, R]): bool = x.kind == OkResult

func get_err*[E, R](x: Result[E, R]): E = x.error

func get*[E, R](x: Result[E, R]): R = x.value

func opt_err*[E, R](x: Result[E, R]): Option[E] =
    if x.is_error: some(x.error) else: none(E)

func opt*[E, R](x: Result[E, R]): Option[R] =
    if x.is_ok: some(x.value) else: none(R)

func err*[E, R](x: E): Result[E, R] =
    Result[E, R](kind: ErrorResult, error: x)

func ok*[E, R](x: R): Result[E, R] =
    Result[E, R](kind: OkResult, value: x)