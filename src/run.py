import os, sys

from time import process_time as ptime

from . import utils 
from .scan import scan, indent
from .parse import parse
from .utils import *

rxpath = os.environ.get('RXPATH', '').split(':')
times = dict(scan=0, indent=0, parse=0, run=0)
file_cache = dict()
pytype = type

def duplicate_arg(arg):
    return Error(arg, f"Attempting to pass keyword argument `{arg.name}` multiple times")

def unknown_par(arg):
    return Error(arg, f"No parameter named `{arg.name}`")

def extraneous_arg(arg):
    kind = 'keyword' if arg.name is not None else 'positional'
    return Error(arg, f"Extraneous {kind} argument {arg}")

def missing_arg(expr, par):
    kind = 'keyword' if par.keyword else 'positional'
    return Error(expr, f"Missing argument for required {kind} parameter ({vrepr(par)}).")

def forbidden_wildcard(par, arg):
    return Error(arg, f"Parameter ({vrepr(par)}) does not have a default value, so cannot use `_` to explicitly use default value.")

def type_error(par, arg):
    kind = 'Variadic parameter' if par.variadic else 'Parameter'
    return Error(arg, f"{kind} {par.name} expected argument of type {vrepr(par.type)}, but got {vrepr(arg.value)} of type {vrepr(arg.type)}")

class UnificationError(Exception):
    pass

class Neutral:
    pass

@dataclass
class Val:
    value: object
    type: object

@dataclass
class Variable:
    value: Val
    type: Val

@dataclass
class BuiltinFunc:
    func: callable
    macro: bool = False

@dataclass
class BuiltinType:
    type: callable

@dataclass
class Arg:
    value: object
    name: Optional[str] = None
    type: Optional[object] = None

@dataclass
class Universe:
    level: int = 0

@dataclass
class Assumed(Neutral):
    name: str
    type: object
    expr: Optional[Expr] = field(default=None, repr=False)

@dataclass
class Apply(Neutral):
    func: Neutral
    args: List[object]
    expr: Optional[Expr] = field(default=None, repr=False)

@dataclass
class Memory:
    value: object

@dataclass
class BoolValue:
    value: bool

@dataclass
class NoneValue:
    pass


def vrepr(it, top=False):
    # TODO: move into standard library
    if it is None: return '<native None>'
    if callable(it): return 'Function(...)'
    if isinstance(it, Val): return vrepr(it.value)
    if isinstance(it, DataValue):
        slots = [k+'='+vrepr(v) for k, v in it.slots.items()]
        return '(' + ', '.join(slots) + ')'
    if isinstance(it, FuncValue):
        params = ', '.join(map(vrepr, it.type.params))
        result = vrepr(it.type.result)
        return f'({params}) -> {result} => ...'
    if isinstance(it, int): return it
    if isinstance(it, str): return "'" + it + "'"
    if isinstance(it, BoolValue): return 'true' if it.value else 'false'
    if isinstance(it, NoneValue): return 'none'
    if isinstance(it, Unique): return f'unique {vrepr(it.value)}'
    if isinstance(it, Assumed): return it.name
    if isinstance(it, Apply):
        args = ', '.join(map(vrepr, it.args))
        return f'{vrepr(it.func)}({args})'
    if isinstance(it, Atom): return it.value
    if isinstance(it, Term):
        if not it.nodes: return 'nil'
        if it.tag in {TermTag.call, TermTag.prefix}:
            args = ', '.join(map(vrepr, it[1:]))
            return f'{vrepr(it[0])}({args})'
        if it.tag in {TermTag.infix}:
            if it[0].value == '.': return '.'.join(map(vrepr, it[1:]))
            return '(' + (' '+vrepr(it[0])+' ').join(map(vrepr, it[1:])) + ')'
        if it.tag in {TermTag.group1, TermTag.group2, TermTag.group3}:
            sep = {TermTag.group1: ' ', TermTag.group2: ', ', TermTag.group3: '; '}
            return sep[it.tag].join(map(vrepr, it.nodes))
        return 'term(' + ', '.join(map(vrepr, it.nodes)) + ')'
    if isinstance(it, Universe):
        if it.level == 0: return 'Type'
        return f'Universe({it.level})'
    if isinstance(it, FuncType):
        params = ', '.join(map(vrepr, it.params))
        result = vrepr(it.result)
        return f'({params}) -> {result}'
    if isinstance(it, UnionType):
        if not it.types: return 'Never'
        return ' | '.join(map(vrepr, it.types))
    if isinstance(it, InterType):
        if not it.types: return 'Any'
        return ' & '.join(map(vrepr, it.types))
    if isinstance(it, EnumType):
        return '[| ' + ', '.join(map(vrepr, it.rows)) + ' |]'
    if isinstance(it, DataType):
        if not it.rows: return 'Unit'
        return '{ ' + ', '.join(map(vrepr, it.rows)) + ' }'
    if isinstance(it, FuncRow):
        res = it.name
        if it.type is not None: res += f' : {vrepr(it.type)}'
        if it.default is not None: res += f' = {vrepr(it.default)}'
        if it.implicit: res += ' = _'
        return res
    return f'<unknown {str(it)}>'

def vtype(env, arg):
    if isinstance(arg, BoolValue): return BOOL_TYPE
    if isinstance(arg, NoneValue): return NONE_TYPE
    if isinstance(arg, int): return INT_TYPE
    if isinstance(arg, str): return STR_TYPE
    if isinstance(arg, Universe): return Universe(level=arg.level + 1)
    if isinstance(arg, Assumed): return arg.type
    if isinstance(arg, Unique): return vtype(env, arg.value)
    if isinstance(arg, FuncType): return max_level(env, arg.params + [arg.result])
    if isinstance(arg, FuncValue): return arg.type
    if isinstance(arg, DataValue):
        rows = []
        for name, (value, type) in arg.slots.items():
            rows.append(DataRow(name=name, type=type))
        return DataType(rows)
    if isinstance(arg, (EnumType, DataType)):
        types = [row.type for row in arg.rows]
        return max_level(env, types)
    if isinstance(arg, (UnionType, InterType)):
        return max_level(env, arg.types)

    if isinstance(arg, Atom):
        name = arg.value
        if arg.tag == AtomTag.string: return STR_TYPE
        if arg.tag == AtomTag.number: return INT_TYPE
        if name in env:
            var = env[name]
            return var.type

    if isinstance(arg, (Apply, Term)):
        func, args = None, None
        if isinstance(arg, Apply): func, args = arg.func, arg.args
        if isinstance(arg, Term): func, args = arg[0], arg[1:]

        func_type = vtype(env, func)
        if isinstance(func_type, FuncType):
            args = make_args(env, args)
            local = env.extend()
            run_args(local, args, func_type.rows, expr)
            return veval(local, func_type.result)

        if isinstance(func_type, BuiltinType):
            return func_type.type(env, *args)

    trace()
    raise Error(arg, f"I don't know the type of {vrepr(arg)}")

def veval(env, arg, as_type=None):
    if not isinstance(arg, (Atom, Term)):
        return arg
        trace()
        raise Error(arg, f'`eval` expects an argument of type Expr, but got {vrepr(arg)} of type {vrepr(vtype(env, arg))}')

    if isinstance(arg, Term) and not arg.nodes:
        return NoneValue()

    if isinstance(arg, Atom):
        name = arg.value
        if arg.tag == AtomTag.number: return int(name)
        if arg.tag == AtomTag.string: return str(name)
        if name in env:
            var = env[name]
            if isinstance(var, BuiltinFunc):
                return var
            if var.value is None:
                return Assumed(name=name, type=var.type, expr=arg)
            return var.value
        if name in env.used:
            return env.used[name][0].value

    if isinstance(arg, Term):
        func = veval(env, arg[0])
        args = arg[1:]
        if isinstance(func, Unique): return arg
        if isinstance(func, Assumed): return Apply(func=func, args=args, expr=arg)
        if isinstance(func, FuncValue):
            args = make_args(env, args)
            local = env.extend()
            run_args(local, args, func.type.params, arg)
            return veval(local, func.body)
        if isinstance(func, BuiltinFunc):
            if not func.macro: args = [veval(env, x) for x in args]
            res = func.func(env, *args)
            #if func.macro and isinstance(res, (Atom, Term)):
            #    res = veval(env, res)
            return res
        raise Error(arg, f"Can't apply `{vrepr(func)}`, because it's not a function")

    trace()
    raise Error(arg, f"I don't know the value of `{vrepr(arg)}`")

def reify(env, arg):
    if isinstance(arg, Assumed):
        return arg.expr
    if isinstance(arg, Apply):
        return arg.expr

def eval_type(env, expr):
    return veval(env, expr), vtype(env, expr)

def find_file(env, path, search=True):
    if os.path.exists(path):
        return path
    if search:
        for dir in rxpath:
            full = os.path.join(dir, path)
            if os.path.exists(full):
                return full
    return None

def run_input(env, text):
    t0 = ptime()
    tokens = list(scan(text))
    times['scan'] += ptime() - t0
    #for x in tokens: print(show_token(x))

    t0 = ptime()
    tokens = list(indent(tokens))
    times['indent'] += ptime() - t0
    #for x in tokens: print(show_token(x))

    t0 = ptime()
    exprs = list(parse(tokens))
    times['parse'] += ptime() - t0
    #for x in expr: print(show_expr(x))

    t0 = ptime()
    values = [eval_type(env, x) for x in exprs]
    times['run'] += ptime() - t0
    #for x in values: print(vrepr(x))
    return values

def run_file(env, path, search=True):
    orig = path
    path = find_file(env, path, search)
    if path is None:
        print('rxpath = ', rxpath)
        raise Error(None, f'error: failed to load module - file `{orig}` does not exist')

    path = os.path.realpath(path)
    with open(path, 'r') as f:
        text = f.read()

    file_stack.append(path)
    rxpath.insert(0, os.path.dirname(path))
    env.file_path = path
    run_input(env, text)
    rxpath.pop(0)
    file_stack.pop()


###############################################################################
# Utilities 
###############################################################################

def max_level(env, values):
    types = [vtype(env, veval(env, x)) for x in values]
    for x in types:
        if not isinstance(x, Universe):
            raise Error(x, f'Expected a type, but found {vrepr(x)}.')
    level = max((x.level for x in types), default=0)
    return Universe(level)

def is_subtype(env, x, y):
    if isinstance(x, Universe) and isinstance(y, Universe):
        return x.level <= y.level
    if isinstance(y, InterType):
        if not y.types: return True  # x is Any
        if any(is_subtype(env, x, it) for it in y.types): return True
    if isinstance(y, UnionType):
        if not y.types: return False # x is Never
        if all(is_subtype(env, x, it) for it in y.types): return True
    if isinstance(x, Term) and isinstance(y, Term):
        return unify_term(env, x, y) == []
    return values_equal(x, y)

def values_equal(lhs, rhs):
    # `_ == _` : (x y : Type) -> bool
    if isinstance(lhs, Assumed) and isinstance(rhs, Assumed):
        return lhs.name == rhs.name and values_equal(lhs.type, rhs.type)
    if isinstance(lhs, Atom) and isinstance(rhs, Atom):
        return lhs.value == rhs.value
    if isinstance(lhs, EnumType) and isinstance(rhs, EnumType):
        return lhs == rhs
    if isinstance(lhs, DataType) and isinstance(rhs, DataType):
        lhs_names = {row.name: row for row in lhs.rows}
        rhs_names = {row.name: row for row in rhs.rows}
        if set(lhs_names.keys()) != set(rhs_names.keys()): return False
        for lhs, lhs_row in lhs_names.items():
            rhs_row = rhs_names[lhs]
            if not values_equal(lhs_row.type, rhs_row.type):
                return False
        return True
    if isinstance(lhs, Term) and isinstance(rhs, Term):
        return len(lhs.nodes) == len(rhs.nodes) \
                and all(values_equal(x, y) for x, y in zip(lhs.nodes, rhs.nodes))
    if isinstance(lhs, Universe) and isinstance(rhs, Universe):
        return lhs.level == rhs.level
    return lhs == rhs

def unify_term(env, left, right):
    def unify_term_inner(left, right):
        # TODO: support function call on the left
        if isinstance(left, Atom) and left.value not in env:
            return [(left.value, veval(env, right))]
        if isinstance(left, Atom) and isinstance(right, Atom) \
                and left.value == right.value:
            return []
        if isinstance(left, Term) and isinstance(right, Term) \
                and len(left.nodes) == len(right.nodes):
            sub = []
            for a, b in zip(left.nodes, right.nodes):
                sub += unify_term_inner(a, b)
            return sub
        raise UnificationError(f'unification for {vrepr(left)} and {vrepr(right)} is not implemented')

    try:
        return unify_term_inner(left, right)
    except UnificationError as e:
        return []

def type_inter(x, y):
    if values_equal(x, y): return InterType([x])
    if isinstance(x, UnionType) and isinstance(y, UnionType):
        types = []
        for xx in x.types:
            if any(values_equal(xx, yy) for yy in y.types):
                types.append(xx)
        return UnionType(types)
    if isinstance(x, InterType) and isinstance(y, InterType):
        return InterType(x.types + y.type)
    return InterType([x, y])

def type_union(x, y):
    if values_equal(x, y): return x
    return UnionType(types=[x, y])

def flatten_union(union):
    if not isinstance(union, UnionType):
        return union
    if len(union.types) == 1:
        return flatten_union(union)
    types = []
    for x in union.types:
        if isinstance(x, UnionType):
            types += flatten_union(x)
        else:
            types += [x]
    return UnionType(types)

def simplify_union(union):
    union = flatten_union(union)
    unique = []
    for x in union.types:
        if any(values_equal(x, y) for y in unique):
            continue
        unique += [x]
    return UnionType(unique)

def make_args(env, terms):
    args = []
    for term in terms:
        args += [Arg(value=term)]
    return args

@dataclass
class Row:
    name: str
    type: Expr
    default: Optional[Expr] = None
    expr: Optional[Expr] = field(default=None, repr=False)
    group: int = 0

def make_row(expr, **kwargs):
    if isinstance(expr, Atom):
        return Row(name=expr.value, type=None, expr=expr)
    func, args = expr[0], expr[1:]
    assert args and is_atom(args[0])
    name = args[0].value
    if len(args) == 2 and is_atom(func, ':'):
        _, typ = args
        return Row(name=name, type=typ, expr=expr)
    if len(args) == 2 and is_atom(func, '='):
        _, val = args
        return Row(name=name, type=None, default=val, expr=expr)
    if len(args) == 3 and is_atom(func, '='):
        _, val, typ = args
        return Row(name=name, type=typ, default=val, expr=expr)
    raise Error(expr, f"Couldn't construct row ~~ {show_expr(expr)}")

def make_rows(expr):
    if isinstance(expr, Atom):
        return [make_row(expr)]

    if expr.tag == TermTag.group1:
        rows = []
        for i, node in enumerate(expr.nodes):
            group = make_rows(node)
            for row in group: row.group = i
            rows += group
        return rows

    if is_atom(expr[0], ':') or is_atom(expr[0], '='):
        return [make_row(expr)]

    rows = [make_row(x) for x in expr.nodes]
    return rows

def infer_unbound(env, term):
    # TODO: account for more cases
    #if isinstance(term, Atom) and term.value not in env:
    if isinstance(term, Atom) and len(term.value) == 1 and term.value.isupper():
        return [(term.value, Universe(0))]
    if isinstance(term, Term):
        unbound = []
        for node in term[1:]:
            unbound += infer_unbound(env, node)
        return unbound
    return []

def prepend_unbound(env, rows):
    assumed = set()
    extra = []
    for i, row in enumerate(rows):
        if row.type and row.default:
            assert values_equal(row.type, vtype(env, row.default))
        if row.default:
            row.type = vtype(env, row.default)
        for name, typ in infer_unbound(env, row.type):
            if name not in assumed:
                assumed.add(name)
                env.assume(name, typ)
                extra.append(FuncRow(name=name, type=typ, default=None, implicit=True))
        env.assume(row.name, row.type)
    return extra + rows

def backprop_types(rows):
    last = None
    for i, row in reversed(list(enumerate(rows))):
        if row.type is None:
            if last is None:
                raise Error(row, f"Please specify the type of parameter {row.name}")
            rows[i].type = last.type
        else:
            last = row
    return rows

def make_func_rows(env, term):
    if term.tag == TermTag.group3:
        assert len(term) == 2
        regular = make_rows(term[0], **kwargs)
        keyword = make_rows(term[1], keyword=True, **kwargs)
        return regular + keyword
    return make_rows(term)


###############################################################################
# Builtins 
###############################################################################

# TODO: reimplement everything expressible in Vitamin in the language

#
# Unique Type
#

@dataclass
class Unique:
    value: object
    name: Optional[str] = None

def make_unique(env, x):
    # `unique _` : (x : Type) -> x
    return Unique(x)

def typeof_unique(env, x):
    return vtype(env, x)

#
# Intersection Type
#

@dataclass
class InterType:
    types: List[Val]

def make_inter_type(env, *args) -> InterType:
    # `_ & _ ...` : (args : ..Expr) -> Inter-Type
    if not args: return InterType([])
    types = [veval(env, x) for x in args]
    return InterType(types)

def typeof_inter_type(env, *args) -> Universe:
    # typeof-inter-type : (args : [Type]) -> Type
    return max_level(env, args)

#
# Union Type
#

@dataclass
class UnionType:
    types: List[Val]

def make_union_type(env, *args) -> UnionType:
    # `_ | _ ...` : (args : ..Expr) -> Union-Type
    if not args: return UnionType([])
    types = [veval(env, x) for x in args]
    return UnionType(types)

def typeof_union_type(env, *args) -> Universe:
    # typeof-union-type : (args : [Type]) -> Type
    return max_level(env, args)

#
# Function Type
#

@dataclass
class FuncRow:
    # Func-Row : Type = { name: String, type: Type }
    name: str
    type: Expr
    default: Optional[Expr] = None
    implicit: bool = False
    variadic: bool = False
    keyword: bool = False
    using: bool = False
    group: int = 0
    expr: Optional[Expr] = field(default=None, repr=False)

@dataclass
class FuncType:
    # Func-Type : Type = { rows: [Func-Row], result: Type }
    params: List[FuncRow]
    result: Val

def make_func_type(env, params, result) -> FuncType:
    # `_ -> _` : (lhs rhs: Expr) -> type-of(lhs -> rhs)
    params, expected_res, _ = prep_func_type(env, params, result, None)
    return FuncType(params, expected_res)

def typeof_func_type(env, params, result) -> Universe:
    # type-of(`_ -> _`) : (lhs rhs: Expr) -> Type
    params, expected_res, _ = prep_func_type(env, params, result, None)
    types = [x.type for x in params] + [expected_res]
    return Universe(max_level(env, types))

def prep_func_type(env, params: List[Expr], result: Optional[Expr], body: Optional[Expr]):
    local = env.extend()
    params = backprop_types(params)
    params = prepend_unbound(local, params)
    local = env.extend()
    for param in params:
        local.assume(param.name, param.type)
    expected_res = veval(local, result) if result is not None else None
    apparent_res = vtype(local, body) if body is not None else None
    return params, expected_res, apparent_res

#
# Function Value
#

@dataclass
class FuncValue:
    type: FuncType
    body: Expr
    pure: bool = False
    macro: bool = False

def make_func_value(env, lhs, rhs) -> FuncValue:
    # `_ => _` : (lhs rhs: Expr) -> type-of(lhs => rhs)
    params, result, body = desugar_macro_func(env, lhs, rhs)
    type = typeof_macro_func(env, params, result, body)
    return FuncValue(type, body)

def typeof_func_value(env, lhs, rhs) -> FuncType:
    # type-of(`_ => _`) : (lhs rhs: Expr) -> Type
    params, result, body = desugar_macro_func(env, lhs, rhs)
    return typeof_macro_func(env, params, result, body)

def desugar_macro_func(env, lhs, rhs):
    params, result, body = lhs, None, rhs
    if is_atom(lhs[0], '->'):
        params, result = lhs[1], lhs[2]
    params = [FuncRow(name=x.name, type=x.type, default=x.default) \
            for x in make_rows(params)]
    return params, result, body

def typeof_macro_func(env, params, result, body):
    params, expected_res, apparent_res = prep_func_type(env, params, result, body)
    if expected_res and not is_subtype(env, apparent_res, expected_res):
        raise Error(body, f'Expected function to return `{vrepr(expected_res)}`, but it returns `{vrepr(apparent_res)}`')
    return FuncType(params, expected_res or apparent_res)

#
# Data Type
#

@dataclass
class DataRow:
    # Data-Row : Type = { name: String, type: Type }
    name: str
    type: Optional[Expr]
    default: Optional[Expr] = None
    group: int = 0
    expr: Optional[Expr] = field(default=None, repr=False)

@dataclass
class DataType:
    # Data-Type : Type = { rows: [Data-Row] }
    rows: List[DataRow]

def make_data_type(env, *args):
    # `{ _? }` : (arg : Expr) -> Expr
    rows = []
    if args:
        for row in make_rows(args[0]):
            type = veval(env, row.type)
            rows.append(DataRow(name=row.name, type=type))
    backprop_types(rows)
    return DataType(rows=rows)

def typeof_data_type(env, *args):
    # typeof-data-type : (rows: [Data-Row]) -> Type
    #raise NotImplementedError()
    return Universe(0)

#
# Data Value
#

@dataclass
class DataValue:
    # Data : Type = { slots: Map[String, Val] }
    slots: dict
    type: Optional[DataType] = None

def make_data_value(env, *args):
    # `( _ )` : (args : Expr) -> Expr
    if not args: return DataValue({})
    arg = args[0]
    rows = make_rows(arg)
    slots = {}
    for row in rows:
        slots[row.name] = eval_type(env, row.default)
    return DataValue(slots)

def typeof_data_value(env, *args) -> DataType:
    # type-of(`( _ )`) : (arg : [Arg]) -> Type
    if not args: return UNIT_TYPE
    rows = make_rows(args[0])
    for row in rows:
        row.default = None
    return DataType(rows=rows)

#
# Enum Type
#

@dataclass
class EnumRow:
    name: str
    type: Optional[Val]
    expr: Optional[Expr] = field(default=None, repr=False)

@dataclass
class EnumType:
    rows: List[EnumRow]

def make_enum_type(env, *args) -> EnumType:
    raise NotImplementedError()

def typeof_enum_type(env, *args) -> Universe:
    raise NotImplementedError()

def macro_enum_type(env, *args):
    # `[| _ |]` : (arg : Expr) -> typeof-enum-type(arg)
    if not args: return EnumType([])
    arg = args[0]
    rows = None
    if is_atom(arg):
        rows = [make_enum_row(env, arg)]
    else:
        rows = [make_enum_row(env, x) for x in arg.nodes]
    return EnumType(rows=rows)

def make_enum_row(env, term):
    if isinstance(term, Atom):
        return EnumRow(name=term.value, type=None, expr=term)
    if len(term) == 3 and is_atom(term[0], ':'):
        name, typ = term[1:]
        assert is_atom(name)
        if len(typ) == 3 and is_atom(typ[0], '->'):
            typ = make_func_type(env, typ[1], typ[2])
        return EnumRow(name=name.value, type=typ, expr=term)
    raise Error(term, f"Couldn't construct enum row ~~ {show_expr(term)}")

#
# Enum Value
#

@dataclass
class EnumValue:
    tag: str
    slots: dict
    type: Optional[EnumType] = None

def make_enum_value(env, *args) -> EnumValue:
    raise NotImplementedError()

def typeof_enum_value(env, *args) -> EnumType:
    raise NotImplementedError()

#
# List Type
#

def make_list_type(env, *args):
    raise NotImplementedError()

def typeof_list_type(env, *args):
    raise NotImplementedError()

def macro_list_type(env, *args):
    raise NotImplementedError()

#
# List Value
#

def make_list_value(env, *args):
    raise NotImplementedError()

def typeof_list_value(env, *args):
    raise NotImplementedError()

def macro_list_value(env, *args):
    # `[ _ ]` : (arg : Expr) -> Expr
    raise NotImplementedError()

#
# Function Call
#

def run_args(env, args, params, expr):
    # TODO: refactor this monster O_o
    binds = [None] * len(params)
    key2pos = {x.name: i for i, x in enumerate(params)}
    errors = []
    regular = []

    for arg in args:
        name = arg.name
        if name is None:
            regular += [arg]
        elif name not in key2pos:
            errors += [unknown_par(arg)]
        else:
            idx = key2pos[name]
            if idx in binds:
                errors += [duplicate_arg(arg)]
            else:
                binds[idx] = (name, arg.value)

    variadic = None
    variadic_idx = None
    varargs = []
    deferred = []
    wildcards = {}

    for idx, (bind, param) in enumerate(zip(binds, params)):
        if param.variadic:
            variadic = param
            variadic_idx = idx
        if bind is not None:
            name, val = binds[idx]
            val, typ = eval_type(env, val)
            binds[idx] = (name, val)
            env.define(name, Variable(val, typ))
            continue

        name = param.name
        if not regular:
            if param.default is not None:
                val, typ = eval_type(env, param.default)
                binds[idx] = (name, val)
                env.define(name, Variable(val, typ))
                continue
            else:
                errors += [missing_arg(expr, param)]
                break

        arg = regular[0]
        arg.value, arg.type = eval_type(env, arg.value)
        param_type = param.type.args[0].value if param.variadic else param.type

        # try to unify assumed implicit arguments
        # example:
        # id(A:Type=_, x:A=true:Bool)
        # unify((A,Bool), (A, _)) --> A=Bool
        bindings = unify_term(env, param_type, arg.type)
        for bind_name, bind_value in bindings:
            if bind_name in wildcards:
                bind_idx, bind_type = wildcards[bind_name]
                env.define(bind_name, Variable(bind_value, bind_type))
                binds[bind_idx] = (bind_name, bind_value)

        # normalize the parameter type by evaluation, before checking subtyping rules
        param_type = veval(env, param_type)

        if param.implicit:
            # Act as if argument was provided.
            # Later, when an argument uses this parameter,
            # we can infer it's value
            wildcards[name] = idx, param_type
        elif is_subtype(env, arg.type, param_type) and (arg.name or not param.keyword):
            # variadics can only occur here
            if param.variadic:
                varargs += [val]
            else:
                val, typ = arg.value, arg.type
                binds[idx] = (name, val)
                env.define(name, Variable(val, typ))
            regular.pop(0)
        elif param.default is not None:
            val, typ = eval_type(env, param.default)
            binds[idx] = (name, val)
            env.define(name, Variable(val, typ))
        else:
            errors += [type_error(param, arg)]
            regular.pop(0)

    extra = []
    for arg in regular:
        if variadic:
            val, typ = eval_type(env, arg.value)
            if is_subtype(env, typ, variadic.type.args[0].value):
                varargs += [val]
            else:
                extra.append(arg)
        else:
            extra.append(arg)

    for arg in extra:
        errors += [extraneous_arg(arg)]

    if variadic:
        binds[variadic_idx] = varargs
        name, type = variadic.name, variadic.type
        env.define(name, Variable(varargs, type))

    empty = [(bind, param) for bind, param in zip(binds, params) if bind == None]

    for bind, param in empty:
        errors += [missing_arg(expr, param)]

    if errors:
        raise errors[0]

#
# Dot Expression
#

def macro_dot(env, lhs, rhs):
    # `_ . _` : macro (lhs rhs : Expr) -> typeof-dot(lhs, rhs)
    assert isinstance(rhs, Atom)
    lhs = veval(env, lhs)
    rhs = rhs.value

    if isinstance(lhs, EnumType):
        for row in lhs.rows:
            if row.name == rhs:
                # get case object or constructor 
                if not isinstance(row.type, FuncType):
                    return DataValue({})
                else:
                    return row

    if isinstance(lhs, DataValue):
        if rhs not in lhs.slots:
            raise Error(expr, f"Object does not have member `{rhs}`")
        val, typ = lhs.slots[rhs]
        return val

    # TODO: try universal function call syntax (UFCS)

    # couldn't acces member or do UFCS
    raise Error(lhs, f"Value `{vrepr(lhs)}` doesn't support accessing its members.")

def typeof_dot(env, lhs, rhs):
    # typeof-dot : (lhs rhs : Expr) -> Type
    assert isinstance(rhs, Atom)
    lhs_type = vtype(env, lhs)
    rhs = rhs.value

    if isinstance(lhs_type, EnumType):
        for row in lhs_type.rows:
            if row.name == rhs:
                # get case object or constructor 
                return row.type

    if isinstance(lhs_type, DataValue):
        if rhs not in lhs_type.slots:
            raise Error(expr, f"Object does not have member `{rhs}`")
        _, typ = lhs_type.slots[rhs]
        return typ

    # TODO: try universal function call syntax

    # couldn't acces member or do UFCS
    raise Error(expr, f"Value `{show_expr(lhs)}` doesn't support accessing its members.")

#
# Use Expression
#

def macro_use(env, arg):
    # `use _` : macro (arg : Expr) -> Expr
    value = veval(env, arg)
    if isinstance(value, EnumType):
        for row in value.rows:
            # value should be the companion
            typ = value if row.type is None else row.type
            env.use(row.name, row, typ)
        return None

    if isinstance(value, DataType):
        for row in value.rows:
            #print(row)
            env.use(row.name, row, row.type)
        return None

    if isinstance(value, DataValue):
        for name, (val, typ) in value.slots.items():
            env.use(name, val, typ)
        return None

    raise Error(arg, f"I don't know how to use this.")

#
# Import Expression
#

def macro_import(env, arg):
    # `import _` : macro (arg : Expr) -> Expr
    path = veval(env, arg)
    local = Env()
    init_env(local)
    run_file(local, path, search=True)
    for name, (val, typ) in local.var.items():
        env.use(name, val, typ)
    for name, used in local.used.items():
        for (val, typ) in used:
            env.use(name, val, typ)
    return None

#
# As Expression
#

def macro_as(env, x, y):
    # `_ as _` : macro (x: A, y: Type) -> y
    lhs, lhs_type_orig = eval_type(env, x)
    rhs_orig = veval(env, y)
    lhs_type = lhs_type_orig
    rhs = rhs_orig
    if isinstance(lhs_type, Unique):
        lhs_type = lhs_type.value
    if isinstance(rhs, Unique):
        rhs = rhs.value
    if not is_subtype(env, lhs_type_orig, rhs_orig):
        raise Error(x, f"I can't cast value {vrepr(lhs)} with type {vrepr(lhs_type_orig)} to type {vrepr(rhs_orig)}.")
    return lhs

def typeof_as(env, x, y):
    return veval(env, y)

#
# Is Expression
#

def macro_is(env, x, y):
    # `_ is _` : (x : Any, y : Type) -> Bool
    x = veval(env, x)
    y = veval(env, y)
    return is_subtype(env, x, y)

def typeof_is(env, *args):
    # `_ is _` : (x : Any, y : Type) -> Bool
    return BOOL_TYPE

#
# If Expression
#

def macro_if(env, *args):
    exit(0)

def typeof_if(env, *args):
    types = []
    for branch in args:
        if isinstance(branch, Term) and len(branch) == 2:
            # if/elif
            cond, body = branch.nodes
            #assert vtype(env, cond) == bool
            types += [infer(env, body)]
        else:
            # else
            types += [infer(env, branch)]
    return simplify_union(UnionType(types))

#
# Assert Expression
#

def assertion_error(arg, text):
    return Error(arg, text, title='assertion error')

def macro_assert(env, *args):
    arg = args[0]
    if arg.tag == TermTag.infix:
        lhs, rhs = veval(env, arg[1]), veval(env, arg[2])
        func = arg[0].value
        if func == '==':
            if values_equal(lhs, rhs): return mkterm()
            raise assertion_error(arg, f"Assertion failed: {vrepr(lhs)} does not equal {vrepr(rhs)}")

        if func == '!=':
            if not values_equal(lhs, rhs): return mkterm()
            raise assertion_error(arg, f"Assertion failed: {vrepr(lhs)} should not equal {vrepr(rhs)}")

    if arg.tag == TermTag.call and arg[0].value == 'error':
        error = False
        try: veval(env, arg[1])
        except Error: return mkterm()
        raise assertion_error(arg, f"Assertion failed: no compilation errors occured")

    raise assertion_error(arg, f"An assertion may only use `==`, `!=` and `error(_)` operators")

def typeof_assert(env, *args):
    return UNIT_T


#
# Definiton
#

def typeof_define(env, name, value):
    return vtype(env, value)

def macro_define(env, lhs, rhs):
    # `_ = _` : (lhs rhs : Expr) -> Unit
    name, expected_type = lhs, None
    if isinstance(lhs, Term) and is_atom(lhs[0], ':'):
        name, expected_type = lhs[1], lhs[2]
    if isinstance(name, Atom):
        name = name.value

    value = veval(env, rhs)
    apparent_type = vtype(env, rhs)
    #print(f'{name} : {vrepr(apparent_type)} = {vrepr(value)}')
    if expected_type is not None and not is_subtype(apparent_type, expected_type):
        raise Error(rhs, f'Type of {show_expr(rhs)} is {vrepr(apparent_type)} and does not match {vrepr(expected_type)}')

    if name in env.vars:
        old_val, old_typ = env[name]
        if old_val is not None:
            raise Error(lhs, f'{name} is already defined in this scope')
        if not values_equal(old_typ, apparent_type):
            raise Error(lhs, f'{name} is assumed to have type {vrepr(old_typ)}, so cannot define it as {vrepr(apparent_type)}')

    if isinstance(value, Unique):
        value.name = name

    #print(f'{name}\n\tval: {vrepr(value)}\n\tapp: {vrepr(apparent_type)}\n\texp: {vrepr(expected_type)}')
    env.define(name, Variable(value, apparent_type))
    return mkterm()

#
# Assumption
#

def do_assume(env, name, type):
    # `_ : _` : macro (lhs rhs : Expr) -> Unit
    assert isinstance(name, Atom)
    name = name.value
    if name in env.vars:
        raise Error(lhs, f"Can't reassume `{name}`, because it's already assumed in this scope")
    type = veval(env, type)
    env.assume(name, type)
    return mkterm()

def typeof_assume(env, *args):
    return UNIT_TYPE

def core_print(env, *args):
    args = [x if isinstance(x, str) else vrepr(x) for x in args]
    print(' '.join(args))

def typeof_print(env, *args):
    return UNIT_TYPE

def core_quote(env, arg):
    return arg

def typeof_quote(env, arg):
    return EXPR_TYPE

###############################################################################
# Globals
###############################################################################

TYPE_0 = Universe(level=0)
UNIT_TYPE = DataType([])
BOOL_TYPE = Assumed(name='Bool', type=TYPE_0)
INT_TYPE = Assumed(name='I64', type=TYPE_0)
STR_TYPE = Assumed(name='String', type=TYPE_0)
NONE_TYPE = Assumed(name='None', type=TYPE_0)
STRING_LITERAL_TYPE = Assumed(name='String-Literal', type=TYPE_0)
NUMBER_LITERAL_TYPE = Assumed(name='Number-Literal', type=TYPE_0)
EXPR_TYPE = Assumed(name='Expr', type=TYPE_0)
FUNC_ROW_TYPE = Assumed(name='Func-Row', type=TYPE_0)

def MACRO_TYPE(env, *args):
    return EXPR_TYPE

class Env:
    def __init__(self, parent=None, file_path=None):
        self.parent = parent
        self.file_path = file_path
        self.vars = {}
        self.used = {}

    def find(self, key):
        # TODO: cache this
        if key in self.vars: return self
        if self.parent: return self.parent.find(key)
        return None

    def define(self, name, value):
        self.vars[name] = value

    def assume(self, name, type):
        value = self.vars[name].value if name in self.vars else None
        self.vars[name] = Variable(value, type)

    def use(self, name, value, type=None):
        if name not in self.used:
            self.used[name] = []
        self.used[name] += [Variable(value, type)]

    def extend(self, file_path=None):
        return Env(parent=self, file_path=file_path or self.file_path)

    def __getitem__(self, index):
        that = self.find(index)
        if that is None: return None
        return that.vars[index]

    def __setitem__(self, index, value):
        that = self.find(index)
        if that is None: that = self
        that.vars[index] = value

    def __contains__(self, index):
        return self.find(index) is not None

    def define_var(self, name, value, type):
        self.vars[name] = Variable(value, type)

    def define_builtin(self, key, func, type, macro=False):
        name, tag = (key, None) if isinstance(key, str) else key
        self.vars[name] = Variable(BuiltinFunc(func, macro), BuiltinType(type))

    def define_macro(self, key, func, type=None):
        self.define_builtin(key, func, type=type or MACRO_TYPE, macro=True)

def init_env(env):
    env.define_var('Type', Universe(0), Universe(1))
    env.define_var('true', BoolValue(True), BOOL_TYPE)
    env.define_var('false', BoolValue(False), BOOL_TYPE)
    env.define_var('none', NoneValue(), NONE_TYPE)

    env.define_builtin('inter-type', make_inter_type, typeof_inter_type)
    env.define_builtin('union-type', make_union_type, typeof_union_type)
    env.define_macro('enum-type', make_enum_type, typeof_enum_type)
    env.define_macro('list-type', make_list_type, typeof_list_type)
    env.define_macro('list-value', make_list_value, typeof_list_value)
    env.define_macro('enum-value', make_enum_value, typeof_enum_value)
    env.define_builtin(('|', TermTag.infix), make_union_type, typeof_union_type)
    env.define_builtin(('&', TermTag.infix), make_inter_type, typeof_inter_type)
    env.define_macro(('(', TermTag.prefix), make_data_value, typeof_data_value)
    env.define_macro(('{', TermTag.prefix), make_data_type, typeof_data_type)
    env.define_macro(('=>', TermTag.infix), make_func_value, typeof_func_value)
    env.define_macro(('->', TermTag.infix), make_func_type, typeof_func_type)

    #env.define_builtin('#assume', do_assume, typeof_assume)
    env.define_builtin('if', macro_if, typeof_if)
    #env.define_builtin('while', macro_while, typeof_while)
    env.define_builtin('as', macro_as, typeof_as)
    env.define_builtin('unique', make_unique, typeof_unique)
    env.define_builtin('print', core_print, typeof_print)
    env.define_macro('quote', core_quote, typeof_quote)

    env.define_macro(('=', TermTag.infix), macro_define, typeof_define)
    env.define_macro((':', TermTag.infix), do_assume, typeof_assume)
    env.define_macro(('[|', TermTag.prefix), macro_enum_type)
    env.define_macro(('[', TermTag.prefix), macro_list_value)
    env.define_macro(('.', TermTag.infix), macro_dot)
    env.define_macro(('assert', TermTag.prefix), macro_assert)
    env.define_macro(('import', TermTag.prefix), macro_import)
    env.define_macro(('use', TermTag.prefix), macro_use)

