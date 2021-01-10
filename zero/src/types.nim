import options, tables

type
    Fun* = object
        args: seq[string]
        body: Exp
        env: ref Env

    Mem* = object
        val: ptr Val
        count: int
        mutable: bool

    BuiltinFun* = proc(args: openArray[Val]): Val

    ExpTag* = enum
        expAtom, expTerm

    Exp* = object of RootObj

    Position* = object
        start_line*, start_char*, stop_line*, stop_char*: int
        file*: ref string

    AtomTag* = enum
        aInd, aDed, aCnt, aSym, aNum, aStr, aWs, aNl, aCom, aEsc

    Atom* = object of Exp
        value*: string
        tag*: AtomTag
        pos*: Option[Position]

    Term* = object of Exp
        nodes*: openArray[Exp]

    ValTag* = enum
        vNum, vExp, vMem, vFun, vBuiltinFun

    Val* = object
        case kind*: ValTag
        of vNum: num*: int
        of vExp: exp*: Exp
        of vMem: mem*: Mem
        of vFun: fun*: Fun
        of vBuiltinFun: builtin_fun*: BuiltinFun

    Var* = object
        val*, typ*: Val

    Env* = object
        parent*: ref Env
        vars*: Table[string, Var]

template mkval*(x: int): Val = Val(kind: vNum, num: x)
template mkval*(x: Exp): Val = Val(kind: vExp, exp: x)
template mkval*(x: Mem): Val = Val(kind: vMem, mem: x)
template mkval*(x: Fun): Val = Val(kind: vFun, fun: x)
template mkval*(x: BuiltinFun): Val = Val(kind: vBuiltinFun, builtin_fun: x)

proc atom*(x: string, tag: AtomTag = aSym, pos: Position): Atom =
    Atom(value: x, tag: tag, pos: some(pos))

proc atom*(x: string, tag: AtomTag = aSym): Atom =
    Atom(value: x, tag: tag, pos: none(Position))

template term*(x: openArray[Exp]): Term =
    Term(nodes: x)

proc pos*(y, x, yy, xx: int, file: ref string = nil): Position =
    Position(start_line: y, start_char: x, stop_line: yy, stop_char: xx, file: file)

proc extend*(env: ref Env): ref Env =
    var child = new Env
    child.parent = env
    child
