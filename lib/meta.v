
Cap : Type
mut, imm, rdo : Cap

Ptr = unique((a: Type) => Size)

allocate : (cap: Cap, a: Type; count: Size) -> Ptr(cap, a)

reallocate : (cap: Cap = _, a: Type = _, p: Ptr(cap, a); count: Size, copy: Size) -> Ptr(cap, a)

Mut-List(a: Type) = Record(buf: Mut(Mut(a)), len cap: Mut(Size))

Imm-List(a: Type) = Record(buf: Imm(a), len: Size)

List-View(a: Type) = Record(buf: Mut(a), len: Size)

Term = Record(nodes: List-View(a))
Atom = Record(value: Str)
Expr = Atom | Term

Term(nodes: Args(Expr)) = (nodes=nodes.to-list())

List(cap: Cap = mut, a: Type) =
    case cap
    of mut Mut-List(a)
    of imm Imm-List(a)
    of rdo List-View(a)
    of _ Never

append(a: Type = _, xs: Mut-List(a), x: a) -> Unit =
    if xs.len >= xs.cap
        xs.cap *= 2
        xs.buf := reallocate(xs.buf, count=xs.cap, copy=xs.len)
    xs.buf[xs.len] := x
    xs.len += 1

to-view(a: Type = _, xs: Mut-List(a)) -> List-View(a) =
    List-View(a)(buf=xs.buf, len=xs.len)

Record-Field = Record(name: Str, value: Expr)

Record-Type-Info = Record(fields: Record-Field)

Function-Parameter(
    name: Str, type: Expr, default: Expr|None = none,
    keyword = false, variadic = false, quoted = false, lazy = false
) -> Term =
    nodes = (buf=allocate(mut, Expr, count=7), len=3, cap=7)
    nodes[0] := Atom(name)
    nodes[1] := type
    nodes[2] := default ?? Term()
    if keyword
        nodes.append(Atom('kwd'))
    if variadic
        nodes.append(Atom('varargs'))
    if quoted
        nodes.append(Atom('quoted'))
    if lazy
        nodes.append(Atom('lazy'))
    Term(nodes.to-view())

Function-Type(params: Term, result: Expr) -> Term =
    Term(Atom('Lambda'), params, result)

Function-Value(params: Term, result body: Expr) -> Term =
    Term(Atom('lambda'), params, result, body)

Record-Value(field-values: Record(name: Str, value: Term)) -> Term =
    fvs = field-values.map(x => Term(Atom(name), value))
    Term(Atom('record'), fvs)

Block(statements: List(Expr)) -> Term =
    Term(Atom('block'), statements)

type-of-constructor(a: Type) -> Type =
    case type-info(a)
    of Record-Info(fields)
        params = fields.map(x => Function-Parameter(x.name, x.type, x.default, keyword=true))
        eval(Function-Type(Term(params), reify(a)))
    of _
        panic("blah blah")

constructor-of(a: Type) -> type-of-constructor(a) =
    case type-info(a)
    of Record-Type-Info(fields)
        #[
            constructor-of(Record(x1: a1 = e1, ..., xn: an = en))

            Returns a function
                (; x1: a1 = e1, ..., xn: an = en) =>
                    (x1=x1, ..., xn=xn)
        ]#
        params = fields.map(x => Function-Parameter(x.name, x.type, x.default, keyword=true))
        body = Record-Value(fields.map(x => (name=x.name, value=x.name)))
        eval(Function-Value(Term(params), reify(a), Block(body)))
    of _
        panic("blah blah")
