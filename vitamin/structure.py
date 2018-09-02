
from .utils import topological_sort

from memoized_property import memoized_property
from dataclasses import dataclass, field
from enum import Enum
from typing import *


@dataclass
class AST:
    pass

@dataclass
class Constant(AST):
    value: str

    def __repr__(self):
        return self.value

@dataclass
class Symbol(Constant):
    pass

    def __repr__(self):
        return self.value

@dataclass
class Name(Constant):
    pass

    def __repr__(self):
        return self.value

@dataclass
class KeywordArgument(AST):
    keyword: Name
    value: Constant

@dataclass
class Directive(AST):
    name: Name
    args: List[AST]

@dataclass
class Program(AST):
    nodes: List[AST]


#
# Operator
#

KINDS = ['xfx', 'yfx', 'xfy', 'fx', 'fy', 'xf', 'yf']

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


#
# Expression
#

@dataclass
class ListExpr(AST):
    nodes: List[AST]

@dataclass
class ExprNode(AST):
    head: AST
    tail: List[AST]

    def __init__(self, head, *tail):
        self.head, self.tail = head, tail

    def __repr__(self):
        tail = ' '.join(map(str, self.tail))
        if tail: tail = ' ' + tail
        return f"({self.head}{tail})"

@dataclass
class ExprLeaf(AST):
    value: AST

    def __repr__(self):
        return f"{self.value}"

#
# Directives
#

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


# TODO: Maybe check precedence relations without explicitly assigning precedence number
def operatorgroup_order(groups: Dict[str, operatorgroup]) -> int:
    '''
    Assigns a precedence to each group based on their relations.
    The precedence is an integer from range [1, inf).

    returns: The highest precedence assigned
    '''
    graph = {name: [] for name in groups.keys()}
    for group in groups.values():
        if group.gt: graph[group.gt].append(group.name)
        if group.lt: graph[group.name].append(group.lt)
    order = topological_sort(graph)
    for i, group in enumerate(order):
        groups[group].prec = i + 1
    return len(order)

def operator_parse(groups: Dict[str, operatorgroup], ops: List[operator]) -> List[Op]:
    '''
    Combines operatorgroup and operator directives into Op ojects.
    '''
    operators = []
    for directive in ops:
        group = groups[directive.group]
        for name in directive.names:
            op = Op(name, group.kind, group.prec)
            operators.append(op)
    return operators

