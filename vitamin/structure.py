from enum import Enum
from typing import *
from typing import Dict, Callable

from dataclasses import dataclass, field

CONSTANT = 'Constant'
SYMBOL = 'Symbol'
NAME = 'Name'
STRING = 'StringLiteral'
NUMBER = 'NumberLiteral'
INT = 'Int'

OP_KINDS = ['xfx', 'yfx', 'xfy', 'fx', 'fy', 'xf', 'yf']


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


@dataclass
class AST:
    span: Span


@dataclass
class Constant(AST):
    mem: str
    typ: str = ''

    def __str__(self):
        return self.mem


@dataclass
class Symbol(Constant):
    def __str__(self):
        return self.mem


@dataclass
class Name(Constant):
    def __str__(self):
        return self.mem


@dataclass
class KeywordArgument(AST):
    keyword: Name
    value: Constant

    def __str__(self):
        return ':'.join(map(str, [self.keyword, self.value]))


@dataclass
class Directive(AST):
    name: Name
    args: List[AST]

    def __str__(self):
        args = ' '.join(map(str, self.args))
        if args: args = ' ' + args
        return f"(#{self.name}{args})"


@dataclass
class Program(AST):
    nodes: List[AST]

    def __str__(self):
        return '\n'.join(map(str, self.nodes))


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
class ListExpr(AST):
    nodes: List[AST]

    def __repr__(self):
        return f"'({' '.join(map(str, self.nodes))})"


@dataclass
class ExprNode(AST):
    head: AST
    tail: List[AST]

    def __repr__(self):
        tail = ' '.join(map(str, self.tail))
        if tail: tail = ' ' + tail
        return f"({self.head}{tail})"


@dataclass
class ExprLeaf(AST):
    head: AST

    def __repr__(self):
        return f"{self.head}"


@dataclass
class operatorgroup:
    name: str
    kind: str
    gt: str = ''
    lt: str = ''


@dataclass
class operator:
    group: str
    names: List[str]


@dataclass
class DirectiveSpec:
    name: str
    call: Callable
    args: list
    kwargs: dict
    varargs: list


class Sym:
    name: str
    pass


@dataclass
class Function(Sym):
    # metadata
    name: str
    # file: str
    # span: Span
    # pure: bool

    pos_args: [str] = field(default_factory=list)
    key_args: Dict[str, str] = field(default_factory=dict)
    var_args: Optional[str] = None
    ret_type: [str] = field(default_factory=list)
    builtin: Optional[Callable] = None


@dataclass
class Variable(Sym):
    name: str
    type: str
    mem: Any


@dataclass
class Scope:
    symbols: Dict[str, Sym]
    parent: Optional = None  # optional scope


@dataclass
class Context:
    groups: dict = field(default_factory=dict)
    opdirs: list = field(default_factory=list)
    ops: list = field(default_factory=list)
    directives: Dict[str, DirectiveSpec] = field(default_factory=dict)
    scope: Scope = None
    LPATH: list = None
    ast: AST = None
