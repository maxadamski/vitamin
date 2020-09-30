import re
from termcolor import colored
from collections.abc import Iterable
from dataclasses import dataclass, field
from enum import Enum
from typing import Union, List, Optional
from collections import namedtuple

inf = float('inf')

file_stack = [None]

def trace():
    import pdb
    pdb.set_trace()

def show_trace(err):
    import traceback
    return ''.join(traceback.TracebackException.from_exception(err).format())

class TokenTag(Enum):
    ind, ded, cnt, sym, num, str, ws, nl, com, esc = range(10)

class data(dict):
    __getattr__ = dict.get

@dataclass
class Token:
    tag: TokenTag
    value: str
    start: tuple
    stop: tuple
    literal: bool = False

    def __repr__(self):
        return f'<Token.{self.tag.name} {self.value}>'

class AtomTag(Enum):
    symbol, number, string = range(3)

class TermTag(Enum):
    prefix, infix, suffix, group1, group2, group3, call, branch = range(8)

@dataclass
class Expr:
    parent: Optional['Expr'] = field(default=None, init=False, repr=False)
    file_path: Optional[str] = field(default=None, init=False, repr=False)

@dataclass
class Atom(Expr):
    value: str
    tag: AtomTag = field(default=AtomTag.symbol, repr=False)
    token: Optional[Token] = field(default=None, repr=False)

    def __len__(self):
        return 0

@dataclass
class Term(Expr):
    nodes: List[Expr]
    tag: TermTag = field(default=TermTag.call, repr=False)
    tokens: List[Token] = field(default_factory=list, init=False, repr=False)

    def __getitem__(self, key):
        return self.nodes[key]

    def __setitem__(self, key, value):
        self.nodes[key] = value
    
    def __len__(self):
        return len(self.nodes)

def mkterm(*nodes, tokens=None, tag=TermTag.call):
    term = Term(nodes=list(nodes), tag=tag)
    term.tokens = tokens or []
    term.file_path = file_stack[-1]
    return term

def mkgroup(nodes):
    return mkterm(*nodes, tag=TermTag.group)

def mkatom(token):
    atom = Atom(value=token.value, token=token, tag=AtomTag.symbol)
    if token.tag == TokenTag.num: atom.tag = AtomTag.number
    if token.tag == TokenTag.str: atom.tag = AtomTag.string
    atom.file_path = file_stack[-1]
    return atom

def is_atom(atom, value=None):
    return isinstance(atom, Atom) and (value is None or atom.value == value)

def mktoken(tag, value, start, stop, literal=False):
    token = Token(tag=tag, value=value, start=start, stop=stop, literal=literal)
    token.file_path = file_stack[-1]
    return token

class Error(Exception):
    def __init__(self, node, message=None, hints=None, title=None):
        self.node = node
        self.message = message
        self.title = title
        self.hints = hints

class Peekable:
    def __init__(self, stream):
        self.stream = iter(stream)
        self.buffer = []
        self.eos = False

    def next(self):
        if self.eos: return None
        if self.buffer:
            return self.buffer.pop(0)
        try:
            return next(self.stream)
        except:
            self.eos = True
            return None

    def peek(self, i: int = 0):
        if self.eos: return None
        if i >= len(self.buffer):
            for _ in range(i + 1 - len(self.buffer)):
                try:
                    self.buffer.append(next(self.stream))
                except StopIteration:
                    if not self.buffer:
                        self.eos = True
                    return None

        return self.buffer[i]

    def __getitem__(self, index):
        return self.peek(index)

    def __bool__(self):
        return self.peek() is not None

    def __next__(self):
        return self.next()

class Stream:
    def __init__(self, iterator):
        self.stream = Peekable(iterator)
        self.last = None

    def __bool__(self):
        return self.peek() is not None

    def next(self, ind=False):
        if ind:
            self.last = next(self.stream)
            return self.last

        while self.stream:
            token = next(self.stream)
            if not is_whitespace(token):
                self.last = token
                return token
        return None

    def peek(self, i=0, ind=False):
        if ind: return self.stream[i]
        j, n = 0, 0
        while n < i or is_whitespace(self.stream[j]):
            if self.stream[j] is None:
                return None
            elif is_whitespace(self.stream[j]):
                j += 1
            else:
                n += 1
                j += 1
        return self.stream[j]

    def expect(self, *args, consume=False):
        ind = any(x.startswith('$') for x in args)
        tok = None
        for i, arg in enumerate(args):
            tok = self.peek(i, ind)
            if tok is None or arg != tok.value:
                return None
        if consume:
            for _ in args:
                self.next(ind=ind)
        return tok

    def consume(self, *args):
        return self.expect(*args, consume=True)

#
# Utility funcitions
#

def join(strings: list, sep='') -> str:
    return sep.join(strings)

def index(predicate, items):
    for i, x in enumerate(items):
        if predicate(x):
            return i
    return None

def term_size():
    import subprocess
    rows, columns = subprocess.check_output(['stty', 'size']).split()
    return int(rows), int(columns)

def str_insert(string, substring, index):
    return string[:index] + substring + string[index:]

def with_line_numbers(lines, nums):
    nums = list(nums)
    maxlen = len(str(nums[-1] + 1))
    padded = lambda num: str(num).rjust(maxlen, ' ')
    return [f'{padded(i)}| {x}' for i, x in zip(nums, lines)]

def with_highlight(lines, source_range, beg, end):
    (y0, x0), (y1, x1) = source_range
    offset = len(beg) if y0 == y1 else 0
    lines[y0-1] = str_insert(lines[y0-1], beg, x0-1)
    if y0 != y1: lines[y0-1] += end
    for y in range(y0, y1-1): lines[y] = beg + lines[y] + beg
    lines[y1-1] = str_insert(lines[y1-1], end, x1-1+offset)
    if y0 != y1: lines[y1-1] = beg + lines[y1-1]
    return lines

def source_segment(text, source_range, error_range=None):
    (y0, x0), (y1, x1) = source_range
    beg, end = '\033[31m\033[4m', '\033[0m'
    lines = text.split('\n')
    lines = with_highlight(lines, source_range, beg=beg, end=end)
    lines = lines[y0-1:y1]
    lines = with_line_numbers(lines, range(y0, y1+1))
    return '\n'.join(lines)

#
# Syntax tree helpers
#

def has_head(term, *head):
    return isinstance(term, Term) and isinstance(term[0], Atom) \
            and term[0].value in head

def is_whitespace(token):
    if token is None: return False
    return token.tag in {TokenTag.nl, TokenTag.ws, TokenTag.ind, TokenTag.ded, TokenTag.cnt}

def max_range(tokens):
    start_line, start_char = inf, inf
    stop_line, stop_char = 0, 0
    for token in tokens:
        if not isinstance(token, Token): continue
        start_line = min(token.start[0], start_line)
        start_char = min(token.start[1], start_char)
        stop_line = max(token.stop[0], stop_line)
        stop_char = max(token.stop[1], stop_char)
    if start_line > stop_line or start_char > stop_char: return None
    return (start_line, start_char), (stop_line, stop_char)

def all_tokens(expr):
    if isinstance(expr, Term):
        tokens = expr.tokens
        for subexpr in expr.nodes:
            tokens += all_tokens(subexpr)
        return tokens

    if isinstance(expr, Atom) and expr.token is not None:
        return [expr.token]

    return []

def expr_range(expr):
    tokens = all_tokens(expr)
    while not tokens and expr.parent:
        expr = expr.parent
        if isinsance(expr, Atom): break
        tokens = all_tokens(expr)
    if not tokens:
        return None
    return max_range(tokens)

def show_token(x):
    val = x.value.replace('\t', '\\t').replace('\n', '\\n').replace(' ', '\\s')
    return f'{x.tag.name}: {val}'

def escape_str(x):
    return x.replace('\n', '\\n').replace('\t', '\\t').replace('\r', '\\r')

def show_expr(self, in_term=True, indent=0):
    if isinstance(self, Term):
        items = [show_expr(x, indent=indent) for x in self.nodes]
        tab = '  '
        pad = tab*(indent+1)
        res = '(' + ' '.join(items) + ')'
        if len(res) > 80 or '\n' in res:
            n, i = 0, 0
            for item in items:
                n += len(item)
                if n > 50: break
                i += 1

            items = [show_expr(x, indent=indent+1) for x in self.nodes]
            res = '(' + ' '.join(items[:i]) + '\n'+pad + ('\n'+pad).join(items[i:]) + ')'
        return res

    if isinstance(self, Atom):
        value = self.value
        if self.token:
            if self.token.tag == TokenTag.str:
                return f"'{escape_str(value)}'"
            if self.token.tag == TokenTag.num:
                return value
        if value in '()[]{}':
            return f'`{value}`'
        if not in_term and not re.match(f'[A-Za-z_@][A-Za-z0-9_-]*', value):
            return f'`{value}`'
        return value

    return repr(self)


#
# Errors and their handling
#

def print_header(before, after=None):
    before = f'-- {before.upper()} '
    after = f' {after}' if after else ''
    padding = '-'*(term_size()[1] - len(before) - len(after))
    print(before+padding+after)

def print_error(err: Error, header=True):
    node = err.node
    if hasattr(node, 'expr'): node = node.expr
    title = err.title or 'syntax error'
    file = err.node.file_path if hasattr(err.node, 'file_path') else None

    try:
        with open(file) as f:
            source = f.read()
    except:
        source = file
        file = None
    start, stop = None, None

    range = None
    if isinstance(node, Token):
        range = node.start, node.stop
    elif isinstance(node, Expr):
        range = expr_range(node)

    if header:
        print_header(title, file)
        print()
    if err.message:
        print(err.message)

    if range and source:
        print()
        seg = source_segment(source, range)
        print(seg)

    if err.hints:
        print('\n'+err.hints)

def indent_error(levels, peek):
    # unindent does not match any outer indentation level
    exp = join([x.diff for x in levels[::-1]], '|')
    new = peek.value
    got = ''

    i = 0
    for x in exp:
        if x == '|':
            got += x
        elif i >= len(new):
            break
        elif x == new[i]:
            got += new[i]
            i += 1
        else:
            got += new[i:]
            break

    show_whitespace = lambda x: x.replace('\t', '>').replace(' ', '.')
    exp = show_whitespace(exp)
    got = show_whitespace(got)
    return Error(peek, f'Bad indentation.', f'Current indentation stack: {exp}\nIndentation on this line:  {got}\n\nHint: Spaces are represented as dots `.`, and tabs as right angle brackets `>`.')

def non_associative_ops(token, left, right):
    hint = 'Hint: Some operators are non-associative, because of their confusing interations, or no obvious precedence convention.'
    if '=' in [left, right]:
        hint = 'Hint: Unlike C and similar languages, assignment does not return a value.'
    elif 'if' in [left, right]:
        hint = "Hint: Nested `if` expressions on a single line are not allowed. Add parentheses to disambiguate or, better yet, indent the conditional body."

    title = f'Non-associative operators `{right}` and `{left}`.'
    if right == left: title = f'Non-associative operator `{right}`.'
    return Error(token, title, f'Non-associative operators cannot appear in the same expression without parentheses.\n\nHint: Disambiguate the expression by adding parentheses.\n\n{hint}')

def not_related_ops(token, left, right):
    hint = "Hint: Some operators are not related, because they don't have an obvious or established precedence relation."
    if 'xor' in [left, right]:
        hint = "Note: In mathematics, `xor` doesn't have an established precedence relation to `or` and `and`."
    return Error(token, f'Operators `{right}` and `{left}` are not related, so they cannot appear in the same expression without additional parentheses, to make the order of operations clear.', f'Hint: Surround the subexpression, which will be evaluated first, with parentheses.\n\n{hint}')

def no_separator(token, op):
    return Error(token, f'Expected separator between elements.')

def extra_comma(op):
    return Error(op, f'Extraneous comma.')
