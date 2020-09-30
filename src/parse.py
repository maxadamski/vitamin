from .utils import *

O_NONE, O_LEFT, O_RIGHT = range(3)

# TODO: prefix rules, infix rules and groups should be encapsulated in Env 
# and resolved according to scope rules
prefix_rules = {}
infix_rules = {}
groups = {}
stream = None

def parse_expr(until_token=None):
    if not stream:
        #import pdb; pdb.set_trace()
        search = f'while looking for {until_token}' if until_token else ''
        raise Error(mkatom(stream.last), f'Unexpected end of file {search}')
    tok = stream.peek()
    curr_token = tok.value
    expr = None

    if tok.literal or curr_token not in prefix_rules:
        expr = literal(stream.next())

    else:
        curr = prefix_rules[curr_token]
        curr.group.stronger_than

        if until_token in prefix_rules:
            until = prefix_rules[until_token]
            if until.op == curr.op or until.op in curr.group.prefix:
                if until.assoc == O_NONE:
                    raise non_associative_ops(tok, curr_token, until_token)
            elif curr.group.name in until.group.stronger_than:
                #print(f'info: `{curr_token}` <.< `{until_token}`')
                pass
            elif until.group.name in curr.group.stronger_than:
                #print(f'info: `{curr_token}` >.> `{until_token}`')
                pass
            else:
                raise not_related_ops(tok, curr_token, until_token)

        expr = curr.parse(stream.next())

    while True:
        if not stream: break
        tok = stream.peek()
        curr_token = tok.value

        if curr_token in '([' and stream.expect('$CNT'):
            break

        if tok.literal or curr_token not in infix_rules:
            break
        
        curr = infix_rules[curr_token]
        until = None
        if until_token in infix_rules:
            until = infix_rules[until_token]
        elif until_token in prefix_rules:
            until = prefix_rules[until_token]
        elif until_token is None:
            expr = curr.parse(expr, stream.next())
            continue

        if until.op == curr.op or until.op in curr.group.infix:
            #print(f'info: `{until_token}` =.= `{curr_token}`')
            if until.assoc == O_LEFT:
                break
            if until.assoc == O_NONE:
                raise non_associative_ops(tok, curr_token, until_token)
        elif curr.group.name in until.group.stronger_than:
            #print(f'info: `{curr_token}` <.< `{until_token}`')
            break
        elif until.group.name in curr.group.stronger_than:
            #print(f'info: `{curr_token}` >.> `{until_token}`')
            pass
        else:
            raise not_related_ops(tok, curr_token, until_token)

        expr = curr.parse(expr, stream.next())

    return expr 


#
# Generic parselets
#

def infix(left, op):
    return mkterm(mkatom(op), left, parse_expr(op.value), tag=TermTag.infix)

def prefix(op):
    return mkterm(mkatom(op), parse_expr(op.value), tag=TermTag.prefix)

def suffix(left, op):
    return mkterm(mkatom(op), left, tag=TermTag.suffix)

def keyword(op):
    return mkatom(op)

def literal(token):
    return mkatom(token)

def infix_flat(left, op):
    tokens = [op]
    args = [left]
    while True:
        expr = parse_expr(op.value)
        args += [expr]
        tok = stream.consume(op.value)
        if not tok: break
        tokens += [tok]
    return mkterm(mkatom(op), *args, tokens=tokens, tag=TermTag.infix)


#
# Functional parselets
#

def parse__expr():
    yield parse_expr()

def parse__many(parse, until):
    if isinstance(until, str): until = [until]
    def do():
        while stream and not any(stream.expect(x) for x in until):
            for item in parse():
                yield item
    return do

def parse__list(parse, until, sep):
    if isinstance(until, str): until = [until]
    def do():
        leading = stream.consume(sep)
        while stream and not any(stream.expect(x) for x in until):
            if leading or stream.expect(sep):
                tok = stream.peek()
                raise Error(tok, f'Remove extraneous separator `{tok.value}`.')

            for item in parse():
                yield item

            if not stream.consume(sep) and not any(stream.expect(x) for x in until):
                tok = stream.peek()
                raise Error(tok, f'Add a separator `{sep}` between items, or close the list with `{until[0]}`.')

    return do

def parse__grouped(until):
    parse_flat = parse__many(parse__expr, until=[',', ';', until])
    def parse_flat_group():
        xs = full_parse(parse_flat)
        if len(xs) == 0: return
        elif len(xs) == 1: yield xs[0]
        else: yield Term(xs, tag=TermTag.group1)
    parse_inner = parse__list(parse_flat_group, until=[';', until], sep=',')
    def parse_inner_group():
        xs = full_parse(parse_inner)
        if len(xs) == 0: return
        elif len(xs) == 1: yield xs[0]
        else: yield Term(xs, tag=TermTag.group2)
    parse_outer = parse__list(parse_inner_group, until=[until], sep=';')
    xs = full_parse(parse_outer)
    if len(xs) == 0: return []
    elif len(xs) == 1: return [xs[0]]
    else: return [Term(xs, tag=TermTag.group3)]

def full_parse(parse):
    return list(parse())

def iter_parse(parse):
    for item in parse():
        yield item

def parse(token_stream):
    global stream
    stream = Stream(token_stream)
    for expr in parse_toplevel():
        yield expr


#
# Custom parselets
#

def parse_toplevel():
    while stream:
        yield parse_expr()
        while stream and stream.consume(';'):
            yield parse_expr()
        if stream and not (stream.expect('$CNT') or stream.expect('$IND') or stream.expect('$DED')):
            tok = stream.peek()
            raise Error(tok, f'Expected end of line or `;`, but found `{tok.value}`.')

def parse_block(op):
    exprs = []
    while not stream.consume('$DED'):
        exprs += [parse_expr()]
        while stream.consume(';'):
            exprs += [parse_expr()]
        if not (stream.consume('$CNT') or stream.expect('$DED')):
            tok = stream.peek()
            raise Error(tok, f'Expected end of line or `;`, found `{tok.value}`.', "Hint: Separate statements on the same line with a semicolon `;`.")
    return Term(exprs, tag=TermTag.group3)

def parse_bexpr(op=None):
    stream.consume('do')
    if stream.consume('$IND'):
        return parse_block(op)
    return parse_expr(op.value if op else None)

def parse_apply(left, beg):
    exprs = full_parse(parse__list(parse__expr, until=')', sep=','))
    end = stream.consume(')')
    if stream.consume('with'): exprs += [parse_bexpr()]
    return mkterm(left, *exprs, tag=TermTag.call, tokens=[beg, end])

def parse_index(head, beg):
    tail = full_parse(parse__list(parse__expr, until=']', sep=','))
    end = stream.consume(']')
    return mkterm(head, *tail, tag=TermTag.index, tokens=[beg, end])

def parse_cond(op):
    exprs = []
    cond = parse_expr(op.value)
    body = parse_bexpr(op)
    exprs += [mkterm(cond, body, tag=TermTag.branch)]
    while stream.consume('elif'):
        cond = parse_expr(op.value)
        body = parse_bexpr(op)
        exprs += [mkterm(cond, body, tag=TermTag.branch)]
    if stream.consume('else'):
        exprs += [parse_bexpr(op)]
    return mkterm(mkatom(op), *exprs, tag=TermTag.prefix)

def parse_when(op):
    exprs = []
    if not stream.expect('case'):
        exprs += [parse_expr(op.value)]
        stream.consume('do')
    else:
        exprs += [None]
    indented = stream.consume('$IND')
    while (tok := stream.consume('case')):
        match = parse_expr(op.value)
        guard = parse_expr(op.value) if stream.consume('if') else None
        block = parse_bexpr(op)
        exprs += [mkterm(match, guard, block, tag=TermTag.branch)]
    if indented: stream.consume('$DED')
    return mkterm(mkatom(op), *exprs, tag=TermTag.prefix)

def parse_loop(op):
    tokens = [op]
    cond = parse_expr()
    if (tok := stream.consume('do')):
        tokens += [tok]
    body = parse_bexpr(op)
    return mkterm(mkatom(op), cond, body, tag=TermTag.prefix, tokens=tokens)

def parse_object(op):
    body = parse_bexpr(op)
    return mkterm(mkatom(op), body, tag=TermTag.prefix)

def parse_group(until):
    def parse(beg):
        exprs = parse__grouped(until=until)
        end = stream.consume(until)
        return mkterm(mkatom(beg), *exprs, tag=TermTag.prefix, tokens=[beg, end])
    return parse

def parse_lambda(left, op):
    if stream.expect('$CNT') or stream.expect('$DED'):
        raise Error(op, "Expected indent or inline expression after `=>`, but found end of line")
    right = parse_bexpr(op)
    if stream.expect('$IND'):
        raise Error(op, "Illegal indent after lambda body")

    if has_head(left, '(') and len(left.nodes) > 1:
        left = left[1]

    if isinstance(left, Atom):
        left = mkterm(Atom('->'), mkterm(Atom(':'), left, Atom('_')), Atom('_'))

    return mkterm(mkatom(op), left, right, tag=TermTag.infix)

def parse_pi(left, op):
    right = parse_expr(op.value)
    if has_head(left, '(') and len(left.nodes) > 1:
        left = left[1]
    return mkterm(mkatom(op), left, right, tag=TermTag.infix)

#
# Operator definition convenience functions
#

def add_groups(names):
    for name in names:
        groups[name] = data(name=name, prefix=[], infix=[], stronger_than=[])

def stronger_than(group, *edges):
    groups[group].stronger_than += edges

def stronger_than_all(group):
    groups[group].stronger_than = list(groups.keys())

def set_group_assoc(op, group, assoc):
    g_assoc = groups[group].assoc
    if g_assoc is None:
        groups[group].assoc = assoc
    elif g_assoc != assoc:
        raise Exception(f'Attempting to add operator `{operator}` with associativity `{assoc}`, into group `{group}`, which already contains operators with associativity `{g_assoc}`. Operator groups cannot have operators of different associativity.')

def add_infix(op, group, assoc, parse):
    set_group_assoc(op, group, assoc)
    groups[group].infix += [op]
    infix_rules[op] = data(op=op, assoc=assoc, parse=parse, group=groups[group])

def add_prefix(op, group, assoc, parse):
    set_group_assoc(op, group, assoc)
    groups[group].prefix += [op]
    prefix_rules[op] = data(op=op, assoc=assoc, parse=parse, group=groups[group])


#
# Core operator definitions
#

add_groups('let,fun,cmd,inv,add,mul,pow,cmp,not,and,xor,or'.split(','))
add_groups('wrap,conv,qual,mod,use,blk,type,test,path,data,rest'.split(','))
add_groups('import,object,union,inter,slice,arrow,apply,index,group,array,magic'.split(','))

stronger_than_all('group')
stronger_than_all('array')
stronger_than_all('apply')
stronger_than_all('index')

stronger_than('object', 'fun', 'use')
stronger_than('blk'  , 'use')
stronger_than('mod'  , 'let')
stronger_than('cmd'  , 'blk')
stronger_than('let'  , 'blk')
stronger_than('type' , 'let', 'cmd', 'blk', 'rest')
stronger_than('fun'  , 'let', 'cmd', 'mod', 'type')
stronger_than('arrow', 'let', 'cmd', 'fun', 'type', 'union', 'inter', 'mod')
stronger_than('path' , 'let', 'cmd', 'fun', 'blk', 'type', 'cmp', 'apply', 'add', 'mul', 'test', 'arrow')
stronger_than('inv'  , 'let', 'cmd', 'fun', 'blk', 'type', 'cmp')
stronger_than('add'  , 'let', 'cmd', 'fun', 'blk', 'type', 'cmp')
stronger_than('mul'  , 'let', 'cmd', 'fun', 'blk', 'type', 'cmp', 'add')
stronger_than('cmp'  , 'let', 'cmd', 'fun', 'blk', 'not', 'and', 'xor', 'or')
stronger_than('or'   , 'let', 'cmd', 'fun', 'blk')
stronger_than('and'  , 'let', 'cmd', 'fun', 'blk', 'or')
stronger_than('xor'  , 'let', 'cmd', 'fun', 'blk')
stronger_than('not'  , 'let', 'cmd', 'fun', 'blk', 'and', 'or')
stronger_than('qual' , 'let', 'cmd', 'fun', 'blk', 'type')
stronger_than('magic', 'type')
stronger_than('union', 'let', 'type', 'fun')
stronger_than('inter', 'let', 'type', 'fun', 'union')
stronger_than('test' , 'blk', 'not')
stronger_than('conv' , 'let')
stronger_than('wrap' , 'let')

add_infix('='  , 'let'  , O_NONE , infix       )   
add_infix(':=' , 'let'  , O_NONE , infix       )   
add_infix('<-' , 'let'  , O_NONE , infix       )   
add_infix('+=' , 'let'  , O_NONE , infix       )   
add_infix('-=' , 'let'  , O_NONE , infix       )   
add_infix('*=' , 'let'  , O_NONE , infix       )   
add_infix('/=' , 'let'  , O_NONE , infix       )   
add_infix(':'  , 'type' , O_LEFT , infix       )   
add_infix('.'  , 'path' , O_LEFT , infix       )   
add_infix('?.' , 'path' , O_LEFT , infix       )   
add_infix('+'  , 'add'  , O_LEFT , infix       )   
add_infix('-'  , 'add'  , O_LEFT , infix       )   
add_infix('*'  , 'mul'  , O_LEFT , infix       )   
add_infix('/'  , 'mul'  , O_LEFT , infix       )   
add_infix('div', 'mul'  , O_LEFT , infix       )   
add_infix('mod', 'mul'  , O_LEFT , infix       )   
add_infix('**' , 'pow'  , O_RIGHT, infix       )   
add_infix('<'  , 'cmp'  , O_NONE , infix       )   
add_infix('>'  , 'cmp'  , O_NONE , infix       )   
add_infix('<=' , 'cmp'  , O_NONE , infix       )   
add_infix('>=' , 'cmp'  , O_NONE , infix       )   
add_infix('==' , 'cmp'  , O_NONE , infix       )   
add_infix('!=' , 'cmp'  , O_NONE , infix       )   
add_infix('===', 'cmp'  , O_NONE , infix       )   
add_infix('!==', 'cmp'  , O_NONE , infix       )   
add_infix('or' , 'or'   , O_LEFT , infix       )   
add_infix('and', 'and'  , O_LEFT , infix       )   
add_infix('xor', 'xor'  , O_LEFT , infix       )   
add_infix('in' , 'test' , O_NONE , infix       )   
add_infix('is' , 'test' , O_NONE , infix       )   
add_infix('as' , 'conv' , O_NONE , infix       )   
add_infix('|'  , 'union', O_LEFT , infix_flat  )   
add_infix('&'  , 'inter', O_LEFT , infix_flat  )   
add_infix('->' , 'arrow', O_RIGHT, parse_pi    )
add_infix('=>' , 'fun'  , O_RIGHT, parse_lambda)
add_infix('('  , 'apply', O_RIGHT, parse_apply )
add_infix('['  , 'index', O_NONE , parse_index )
add_infix('??' , 'wrap' , O_NONE , infix       )   

add_prefix(':'       , 'type'  , O_LEFT , prefix      )   
add_prefix('('       , 'group' , O_NONE, parse_group(')'))
add_prefix('['       , 'array' , O_NONE, parse_group(']'))
add_prefix('{'       , 'array' , O_NONE, parse_group('}'))
add_prefix('{|'      , 'array' , O_NONE, parse_group('|}'))
add_prefix('[|'      , 'array' , O_NONE, parse_group('|]'))
add_prefix('not'     , 'not'   , O_RIGHT, prefix      )
add_prefix('-'       , 'inv'   , O_NONE , prefix      )
add_prefix('$'       , 'magic' , O_NONE , prefix      )
add_prefix('?'       , 'qual'  , O_LEFT , prefix      )
add_prefix('&'       , 'qual'  , O_LEFT , prefix      )
add_prefix('mut'     , 'qual'  , O_LEFT , prefix      )
add_prefix('imm'     , 'qual'  , O_LEFT , prefix      )
add_prefix('..'      , 'rest'  , O_NONE , prefix      )
add_prefix('return'  , 'cmd'   , O_NONE , prefix      )
add_prefix('assert'  , 'cmd'   , O_NONE , prefix      )
add_prefix('using'   , 'cmd'   , O_NONE , prefix      )
add_prefix('continue', 'cmd'   , O_NONE , keyword     )
add_prefix('break'   , 'cmd'   , O_NONE , keyword     )
add_prefix('if'      , 'blk'   , O_NONE , parse_cond  )
add_prefix('while'   , 'blk'   , O_NONE , parse_loop  )
add_prefix('for'     , 'blk'   , O_NONE , parse_loop  )
add_prefix('when'    , 'blk'   , O_NONE , parse_when  )
add_prefix('enum'    , 'data'  , O_NONE , prefix      )
add_prefix('use'     , 'use'   , O_NONE , prefix      )
add_prefix('import'  , 'import', O_NONE , prefix      )
add_prefix('object'  , 'object', O_NONE , parse_object)
add_prefix('opaque' , 'mod',    O_NONE , prefix      )
add_prefix('unique' , 'mod',    O_NONE , prefix      )
add_prefix('extern' , 'mod',    O_NONE , prefix      )
add_prefix('macro'  , 'mod',    O_NONE , prefix      )
add_prefix('lazy'   , 'mod',    O_NONE , prefix      )

