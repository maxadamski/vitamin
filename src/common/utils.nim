import options, tables, sequtils, strutils, strformat, os
import patty

# "Optional unwrapping" for strings

func `??`*(s: string, default: string): string =
    if s.len > 0: s else: default

# Pretty printing

func bold*(x: string): string = "\e[1m" & x & "\e[0m"

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

func max_or*(x: seq[int], default=0): int =
    if x.len == 0: default else: max(x)

# Pretty path

proc pretty_path*(path: string): string = 
    let a = path.replace(get_env("HOME"), "~")
    let b = path.replace(get_env("PWD") & "/", "")
    if a.len < b.len: a else: b

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

# Safe Either type

variantp Either[T, U]:
    Left(left: T)
    Right(right: U)

func map_right*[T, U, V](val: Either[T, U], f: proc (x: U): V): Either[T, V] =
    if opt.kind == EitherKind.Right: Right(f(val.right)) else: val

func map_left*[T, U, V](val: Either[T, U], f: proc (x: T): V): Either[V, U] =
    if opt.kind == EitherKind.Left: Left(f(val.left)) else: val

func is_left*[T, U](val: Either[T, U]): bool =
    val.kind == EitherKind.Left

func is_right*[T, U](val: Either[T, U]): bool =
    val.kind == EitherKind.Right

func unsafe_left*[T, U](val: Either[T, U]): T =
    val.left

func unsafe_right*[T, U](val: Either[T, U]): T =
    val.right


# Safe Option type

variantp Opt[T]:
  None
  Some(value: T)

template None*(t: untyped): untyped =
    None[t]()

func is_some*[T](opt: Opt[T]): bool =
  opt.kind == OptKind.Some

func is_none*[T](opt: Opt[T]): bool =
  opt.kind == OptKind.None

func `??`*[T](opt: Opt[T], default: T): T =
    if opt.kind == OptKind.Some: opt.value else: default

func map*[T, U](opt: Opt[T], f: proc (x: T): U): Opt[U] =
    if opt.kind == OptKind.Some: Some(f(opt.value)) else: None(U)

func unsafe_get*[T](opt: Opt[T]): T =
    opt.value

template or_else*[T](opt: Opt[T], default: untyped): untyped =
    if opt.kind == OptKind.Some:
        opt.value
    else:
        default

template if_some*[T](opt: Opt[T], name: untyped, op: untyped) =
    if opt.kind == OptKind.Some:
        let `name` {.inject.} = opt.value
        op