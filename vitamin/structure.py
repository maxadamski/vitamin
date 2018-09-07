"""
Definitions of internally used structures and built-in constants
"""

from .utils import class_name

from typing import *
from dataclasses import dataclass, field
from enum import Enum, unique
from decimal import Decimal

OP_KINDS = ['xfx', 'yfx', 'xfy', 'fx', 'fy', 'xf', 'yf']

TypEnum = Union[List['TypEnum'], str]


class SemError(ValueError):
    pass


@dataclass
class Typ:
    typ: TypEnum
    # generic type names
    gen: List[TypEnum] = field(default_factory=list)

    # generic type constraints
    # con: List[TypBound]

    def __str__(self):
        if isinstance(self.typ, str): return self.typ
        return ' -> '.join(map(str, self.typ))


T_ANY = Typ('Any')
T_VOID = Typ('()')
T_ATOM = Typ('Atom')
T_EXPR = Typ('Expr')
T_STRING_LITERAL = Typ('StringLiteral')
T_INT_LITERAL = Typ('IntLiteral')
T_REAL_LITERAL = Typ('RealLiteral')
T_INT = Typ('Int')
T_BOOL = Typ('Bool')
T_ARRAY = Typ(['Array', 'T'], gen=['T'])


@dataclass
class Loc:
    line: int
    char: int
    byte: int

    def __repr__(self):
        return f"{self.line}:{self.char}:{self.byte}"


@dataclass
class Span:
    start: Loc
    stop: Loc

    def __len__(self):
        return self.stop.byte - self.start.byte + 1

    def __repr__(self):
        return f"{self.start}-{self.stop}"


class Associativity(str, Enum):
    RIGHT = 'Right'
    LEFT = 'Left'
    NONE = 'None'

    @staticmethod
    def from_kind(kind):
        if kind in ['xfx', 'fx', 'xf']: return Associativity.NONE
        if kind in ['xfy', 'fy']: return Associativity.RIGHT
        if kind in ['yfx', 'yf']: return Associativity.LEFT


class Fixity(str, Enum):
    PREFIX = 'Prefix'
    SUFFIX = 'Suffix'
    INFIX = 'Infix'

    @staticmethod
    def from_kind(kind):
        if kind in ['xfx', 'yfx', 'xfy']: return Fixity.INFIX
        if kind in ['fx', 'fy']: return Fixity.PREFIX
        if kind in ['xf', 'yf']: return Fixity.SUFFIX


@dataclass
class Op:
    name: str
    kind: str
    prec: int
    ass: str = field(init=False)
    fix: str = field(init=False)

    def __post_init__(self):
        self.ass = Associativity.from_kind(self.kind)
        self.fix = Fixity.from_kind(self.kind)


@dataclass
class OpGroupDir:
    name: str
    kind: str
    gt: str = ''
    lt: str = ''
    prec: int = None


@dataclass
class OpDir:
    group: str
    names: List[str]


@unique
class Token(str, Enum):
    ListExpr = 'ListExpr'
    Expr = 'Expr'
    Block = 'Block'
    Quote = 'Quote'
    Pragma = 'Pragma'


class Object:
    typ: Typ
    mem: Any
    span: Span
    leaf: bool
    literal: bool

    def __init__(self, typ, mem, span=None, leaf=True, literal=False):
        self.typ, self.mem = typ, mem
        self.span = span
        self.leaf = leaf
        self.literal = literal

    def __str__(self):
        return dump(self)


LambdaArg = Union[Tuple[str, TypEnum], Tuple[str, TypEnum, Object]]

C_TRUE = Object(T_BOOL, 1)
C_FALSE = Object(T_BOOL, 0)
C_NIL = Object(T_ANY, None)


class Expr(Object):
    def __init__(self, head, args, span):
        mem = {'head': head, 'args': args}
        super().__init__(T_EXPR, mem, span=span, leaf=False, literal=False)

    @property
    def head(self) -> Token:
        return self.mem['head']

    @head.setter
    def head(self, value: Token):
        self.mem['head'] = value

    @property
    def args(self) -> List[Object]:
        return self.mem['args']

    @args.setter
    def args(self, value: List[Object]):
        self.mem['tail'] = value

    def tree(self, level=0, index=0):
        pad = '  ' * level
        typ = class_name(self)


def spec_to_typ(spec: List[LambdaArg], ret: TypEnum):
    typ, keywords, default = [], {}, {}
    for arg in spec:
        keywords[arg[0]] = arg[1]
        typ.append(arg[1])
        if len(arg) == 3:
            default[arg[0]] = arg[2]
    typ.append(ret)
    return typ, keywords, default


@dataclass
class Lambda(Object):
    mem: Callable

    keywords: Dict[str, Typ]
    keys: List[str]
    default: Dict[str, Object]
    returns: Typ
    varargs: bool
    arity: int
    varkey: Optional[str] = None
    vartyp: Optional[Typ] = None

    def __init__(
            self, mem, spec: List[LambdaArg],
            returns: TypEnum = T_VOID,
            varargs=False):
        typ, keywords, default = spec_to_typ(spec, returns)
        super().__init__(Typ(typ), mem)
        if varargs:
            self.varkey, self.vartyp = spec[-1][0], spec[-1][1]
        self.keys = [tup[0] for tup in spec]
        self.keywords = keywords
        self.default = default
        self.varargs = varargs
        self.returns = returns
        self.fullarity = len(keywords)
        self.arity = len(keywords) - len(default)


@dataclass
class PragmaArg:
    span: Span
    key: Optional[Object]
    val: Object


@dataclass
class PragmaExpr:
    span: Span
    name: str
    args: List[PragmaArg]

    @property
    def argc(self):
        return len(self.args)


@dataclass
class Scope:
    symbols: Dict[str, Object]
    parent: Optional = None  # optional scope


@dataclass
class Context:
    groups: Dict[str, OpGroupDir] = field(default_factory=dict)
    opdirs: List[OpDir] = field(default_factory=list)
    ops: List[Op] = field(default_factory=list)
    pragmas: Dict[str, Lambda] = field(default_factory=dict)
    scope: Scope = None
    path: List[str] = None
    file: Any = None
    node: Expr = None
    expr: Expr = None
    ast: Expr = None
    node_index: int = 0


def unpack_args(args: Dict[str, Object], names: Iterator[str]) -> Iterator[Object]:
    return map(lambda arg: args[arg], names)


def deref_mem(objects: Iterator[Object]) -> Iterator[Any]:
    return map(lambda obj: obj.mem, objects)


def dump(obj: Object, level=0, index=0):
    typ = class_name(obj)
    pad = "  " * level
    res = ""

    if isinstance(obj, Expr):
        head = obj.head
        args = ""
        for i, arg in enumerate(obj.args):
            args += f"\n"
            if isinstance(arg, Expr) or isinstance(arg, PragmaExpr):
                args += dump(arg, level=level + 2, index=i)
            else:
                args += f"{pad}    [{i}] {dump(arg)}"

        res += f"{pad}{typ} [{index}]\n"
        res += f"{pad}  head: {head}\n"
        res += f"{pad}  args: {args}\n"
        return res

    elif isinstance(obj, PragmaExpr):
        name = Object(T_ATOM, obj.name, leaf=True, literal=True)
        args = [arg.val for arg in obj.args]
        e = Expr(Token.Pragma, [name] + args, None)
        return dump(e, level=level, index=index)

    else:
        if obj.leaf:
            return f"{pad}{typ} {obj.mem} :: {obj.typ}"
        else:
            return f"{pad}{typ}\n{pad}  mem: {obj.mem}"
