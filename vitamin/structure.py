"""
This file contains the definitions of internally used structures
and built-in constants, some of which should really be somewhere else

todo: implement a generic tuple/array
todo: refactor LambdaArg into tuple
"""

from enum import Enum, unique
from typing import *

from memoized_property import memoized_property
from dataclasses import dataclass, field

from .utils import class_name

OP_KINDS = ['xfx', 'yfx', 'xfy', 'fx', 'fy', 'xf', 'yf']

TypEnum = Union[List['TypEnum'], str]


class SemError(ValueError):
    pass


class ParserError(Exception):
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
T_NOTHING = Typ('Nothing')
T_VOID = Typ('()')
T_ATOM = Typ('Atom')
T_EXPR = Typ('Expr')
T_STRING = Typ('String')
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
        return self.stop.byte - self.start.byte

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
class ExprToken(str, Enum):
    ListExpr = 'ListExpr'
    Expr = 'Expr'
    Block = 'Block'
    Quote = 'Quote'
    Pragma = 'Pragma'
    Call = 'Call'

    def __str__(self):
        return self.value

    def __repr__(self):
        return '<ExprToken>'


class Obj:
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
        return sexpr(self)

    def __repr__(self):
        return f"<<{self.typ}>>"


C_TRUE = Obj(T_BOOL, 'true')
C_FALSE = Obj(T_BOOL, 'false')
C_NIL = Obj(T_NOTHING, None)


class Expr(Obj):
    def __init__(self, head, args, span):
        mem = {'head': head, 'args': args}
        super().__init__(T_EXPR, mem, span=span, leaf=False, literal=False)

    @property
    def head(self) -> ExprToken:
        return self.mem['head']

    @head.setter
    def head(self, value: ExprToken):
        self.mem['head'] = value

    @property
    def args(self) -> List[Obj]:
        return self.mem['args']

    @args.setter
    def args(self, value: List[Obj]):
        self.mem['args'] = value

    def tree(self, level=0, index=0):
        pad = '  ' * level
        typ = class_name(self)


@dataclass
class LambdaParam:
    index: int
    key: str
    typ: Typ
    val: Optional[Obj] = None
    var: bool = False

    @property
    def is_variadic(self):
        return self.var

    @property
    def is_keyword(self):
        return self.val is not None

    @property
    def is_positional(self):
        return self.val is None

    def __str__(self):
        return f"{self.key}: {self.typ}"


@dataclass
class LambdaArg(Obj):
    # TODO: LambdaArg is really a named tuple!
    val: Obj
    key: Optional[Obj]

    @property
    def is_keyword(self) -> bool:
        return self.key is not None

    def __init__(self, span, val, key=None):
        super().__init__(T_EXPR, None, span=span, leaf=False, literal=True)
        self.val, self.key = val, key


@dataclass
class Lambda(Obj):
    mem: Callable

    name: str
    param: List[LambdaParam]
    index: Dict[str, LambdaParam]
    return_type: Typ
    pragma: bool

    # convenience
    variadic: Optional[str]
    pos_count: int
    key_count: int
    arity: int

    @memoized_property
    def keywords(self):
        return list(self.index.keys())

    def __init__(
            self, name, mem, parameters: List[Union[Tuple[str, Typ], Tuple[str, Typ, Obj]]],
            returns: Typ = T_VOID, variadic=None):
        super().__init__(T_NOTHING, mem)

        self.name = name
        self.pos_count, self.key_count = 0, 0
        self.param, self.index = [], {}
        self.return_type = returns
        self.arity = len(parameters)
        self.variadic = variadic
        self.pragma = False

        for i, p in enumerate(parameters):
            key, typ, val = p[0], p[1], None
            if len(p) > 2: val = p[2]
            param = LambdaParam(i, key, typ, val)
            if key is not None and key == variadic:
                param.var = True
                param.val = Obj(T_ARRAY, [])
            elif param.is_keyword:
                self.key_count += 1
            else:
                self.pos_count += 1
            self.param.append(param)
            self.index[key] = param


@dataclass
class Scope:
    symbols: Dict[str, Obj]
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


def unpack_args(args: Dict[str, Obj], names: Iterator[str]) -> Iterator[Obj]:
    return map(lambda arg: args[arg], names)


def deref_mem(objects: Iterator[Obj]) -> Iterator[Any]:
    return map(lambda obj: obj.mem, objects)


def dump(obj: Obj, level=0, index=0):
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
        name = Obj(T_ATOM, obj.name, leaf=True, literal=True)
        args = [arg.val for arg in obj.args]
        e = Expr(ExprToken.Pragma, [name] + args, None)
        return dump(e, level=level, index=index)

    else:
        if obj.leaf:
            return f"{pad}{typ} {obj.mem} :: {obj.typ}"
        else:
            return f"{pad}{typ}\n{pad}  mem: {obj.mem}"


def paren(string: str):
    return '(' + string + ')'


def sexpr(obj: Obj):
    mem = obj.mem

    if isinstance(obj, Lambda):
        return obj.name + '(' + ', '.join(map(str, obj.param)) + ')'
    elif isinstance(obj, LambdaArg):
        key = str(obj.key.mem) if obj.key else None
        val = sexpr(obj.val)
        if key is None: return val
        return f"{key}: {val}"
    elif obj.typ == T_EXPR:
        head = str(obj.head).split('.')[-1]
        args = map(str, obj.args)
        return paren(', '.join([head, *args]))
    elif isinstance(mem, dict):
        return paren(', '.join(f"{k}: {v}" for k, v in mem.items()))
    elif isinstance(mem, list):
        return paren(', '.join(map(str, mem)))
    elif isinstance(mem, str):
        return f'"{mem}"'
    else:
        return str(mem)
