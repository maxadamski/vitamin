from more_itertools import peekable
from .utils import *

#
# Indentation preprocessor 
#

def without_comments(token_stream):
    for token in token_stream:
        if token.tag != TokenTag.com:
            yield token

def indent(token_stream):
    stream = peekable(without_comments(token_stream))
    levels = []

    def pop_levels(count=None):
        for _ in range(count or len(levels)):
            tok = levels.pop()
            yield mktoken(tag=TokenTag.ded, value='$DED', start=tok.start, stop=tok.stop)
        if stream:
            tok = stream[0]
            yield mktoken(tag=TokenTag.cnt, value='$CNT', start=tok.start, stop=tok.stop)

    for t in stream:
        if not is_whitespace(t):
            yield t

        elif t.tag == TokenTag.nl and stream:
            peek = next(stream)
            next_level = peek.value
            last_level = levels[-1].value if levels else ''

            if peek.tag != TokenTag.ws:
                for tok in pop_levels(): yield tok
                yield peek

            elif stream and stream[0].tag == TokenTag.nl: 
                continue

            elif next_level == last_level:
                yield mktoken(tag=TokenTag.cnt, value='$CNT', start=peek.start, stop=peek.stop)

            elif next_level.startswith(last_level):
                peek.diff = next_level[len(last_level):]
                levels.append(peek)
                yield mktoken(tag=TokenTag.ind, value='$IND', start=peek.start, stop=peek.stop)

            elif last_level.startswith(next_level):
                level = index(lambda x: x.value == next_level, reversed(levels))
                if level is None: raise indent_error(levels, peek)
                for tok in pop_levels(level): yield tok

            else:
                raise indent_error(levels, peek)

    for tok in pop_levels(): yield tok

#
# Basic table scanner
#

line, char = 1, 1
stream = None
delims = None
parens = {')': '(', ']': '[', '}': '{', '|]': '[|', '|}': '{|'}
state = {}

def scan(text_stream):
    global stream, line, char, delims
    line, char = 1, 1
    stream = peekable(text_stream)
    delims = []
    while stream:
        c = stream[0]
        if ord(c) in state:
            scanner = state[ord(c)]
            if scanner is None: continue
            token = scanner(c)
            if token is None: continue
            yield token
        else:
            yield eatwhile(is_name_tail, tag=TokenTag.sym)
    if delims:
        raise Error(delims[-1], f'Unclosed delimiter.')

def add_state(matcher, scanner):
    for match in matcher:
        if len(match) == 1:
            state[ord(match)] = scanner
        elif len(match) == 2:
            for i in range(ord(match[0]), ord(match[1])+1):
                state[i] = scanner

def get():
    global line, char
    x = next(stream)
    if x == '\n':
        line += 1
        char = 1
    else:
        char += 1
    return x

def eatone(tag=-1):
    start = line, char
    if not stream:
        raise Exception('parser error: unexpected EOF') 
    value = get()
    return mktoken(value=value, start=start, stop=(line, char), tag=tag)

def eatwhile(predicate, tag=-1):
    start = line, char
    value = get()
    while stream and predicate(stream[0]):
        value += get()
    return mktoken(value=value, start=start, stop=(line, char), tag=tag)

def eatrange(until, tag=-1, escape=None, literal=False):
    start = line, char
    value = ''
    get()
    while True:
        if not stream:
            tok = mktoken(tag=TokenTag.sym, value='`', start=start, stop=(start[0], start[1] + 1))
            raise Error(tok, f'Unclosed symbol: expected `{chr}`, but found EOF.')
        next = stream[0]
        if next == until: break
        if next == escape:
            get()
            c = get()
            if c == 'n': value += '\n'
            elif c == 't': value += '\t'
            else: value += c
        else:
            value += get()
    get()
    return mktoken(tag=tag, value=value, start=start, stop=(line, char), literal=literal)

def scan_group_open(c):
    start = line, char
    value = get()
    if stream[0] == '|':
        value += get()
    tok = mktoken(value=value, start=start, stop=(line, char), tag=TokenTag.sym)
    delims.append(tok)
    return tok

def check_close_paren(paren: str):
    if not delims:
        raise Error(tok, f'Found closing paren `{paren}`, but there was no open paren.')
    if delims[-1].value != parens[paren]:
        raise Error(tok, f'Incompatible closing paren `{paren}`. Currently open paren is `{delims[-1].value}`.')

def scan_group_close(c):
    tok = eatone(tag=TokenTag.sym)
    check_close_paren(c)
    delims.pop()
    return tok

def scan_group_close_or_symbol(c):
    start = line, char
    value = get()
    if stream[0] in ')]}':
        value += get()
        check_close_paren(value)
        delims.pop()
    else:
        while stream and is_symb_tail(stream[0]):
            value += get()
    return mktoken(value=value, start=start, stop=(line, char), tag=TokenTag.sym)

def scan_newline(c):
    start = line, char
    value = get()
    while stream and stream[0] in '\r\n':
        value += get()
    return mktoken(tag=TokenTag.nl, value=value, start=start, stop=(line, char))

def is_numb_tail(x):
    return '0' <= x <= '9' or x == '_'

def is_name_tail(x):
    return 'a' <= x <= 'z' or 'A' <= x <= 'Z' or '0' <= x <= '9' or x == '_' or x == '-' or ord(x) > 127

def is_symb_tail(x):
    return x in '@%$&=*+!?^/|><:.~-'

add_state('\r'  , None)
add_state('\n'  , scan_newline)
add_state('\t ' , lambda c: eatwhile(lambda x: x in '\t ', tag=TokenTag.ws))
add_state('\\'  , lambda c: eatone(tag=TokenTag.esc))
add_state('#'   , lambda c: eatwhile(lambda x: x != '\n', tag=TokenTag.com))
add_state(',;'  , lambda c: eatone(tag=TokenTag.sym))
add_state('\'\"', lambda c: eatrange(c, tag=TokenTag.str, escape='\\'))
add_state('([{' , scan_group_open)
add_state(')]}' , scan_group_close)
add_state('|'   , scan_group_close_or_symbol)
add_state('`'   , lambda c: eatrange('`', tag=TokenTag.sym, literal=True))
add_state(['09'], lambda c: eatwhile(is_numb_tail, tag=TokenTag.num))
add_state('%$&=*+!?^/:><.~-', lambda c: eatwhile(is_symb_tail, tag=TokenTag.sym))

