import options, tables, strutils
import common/[exp, error]

const open_comp = {")": "(", "]": "[", "}": "{", "|)": "(|", "|]": "[|", "|}": "{|"}.to_table
const name_head = {'a'..'z', 'A'..'Z', '_'}
const name_tail = name_head + {'0'..'9', '-'}
const numb_head = {'0'..'9'}
const numb_tail = numb_head + {'a'..'z', 'A'..'Z', '_'}
const symb_head = {'%','$','&','=','*','+','!','?','^','/','>','<',':','.','~','-'}
const symb_tail = symb_head + {'@','|'}

func tos(c: char): string =
    var s = ""
    s.add(c)
    s

type Scanner = object
    x_last, y_last, x, y: int
    i: int
    tmp: string
    text: string
    file: ref string

func new_scanner(str: string, file: ref string, start_line: int = 1): Scanner =
    Scanner(x_last: 1, y_last: 1, x: 1, y: start_line, i: 0, tmp: "", text: str, file: file)

proc save(self: var Scanner) =
    self.x_last = self.x
    self.y_last = self.y
    self.tmp = ""

proc eat(self: var Scanner): char =
    let c = self.text[self.i]
    if c == '\n':
        self.y += 1
        self.x = 1
    else:
        self.x += 1
    self.i += 1
    c

func eof(self: Scanner): bool =
    self.i >= self.text.len

func top(self: Scanner, offset: int = 0): char =
    let i = self.i + offset
    if i < self.text.len: self.text[i] else: '\0'

func top_unsafe(self: Scanner, offset: int = 0): char =
    self.text[self.i + offset]

func peek(self: Scanner, offset: int = 1): string =
    self.text[self.i .. self.i + offset]

func get_range(self: Scanner): Position =
    pos(self.y_last, self.x_last, self.y, self.x, self.file)

proc scan*(text: string, file: Option[string] = none(string), start_line: int = 1): seq[Exp] =
    var atoms: seq[Exp]
    var file_ref = new string
    if file.is_some:
        file_ref[].add(file.get)
    var s = new_scanner(text, file_ref, start_line)
    var buf = "" 
    var parens: seq[Exp]
    proc check_close_paren(paren: string) =
        if parens.len == 0:
            raise stray_closing_paren_error(atom(paren, aSym, s.get_range))
        if parens[^1].value != open_comp[paren]:
            raise mismatched_paren_error(atom(paren, aSym, s.get_range), parens[^1])

    while not s.eof:
        buf = ""
        s.save
        let curr = s.eat
        buf.add(curr)
        case curr
        of name_head:
            while s.top in name_tail or ord(s.top) > 127: buf.add(s.eat)
            atoms.add(atom(buf, aSym, s.get_range))
        of symb_head:
            while s.top in symb_tail:
                if s.top == '-' and s.top(1) in numb_head:
                    break
                buf.add(s.eat)
            atoms.add(atom(buf, aSym, s.get_range))
        of numb_head:
            while s.top in numb_tail: buf.add(s.eat)
            atoms.add(atom(buf, aNum, s.get_range))
        of {'\'', '"', '`'}:
            let tag = if curr == '`': aLit else: aStr
            buf = ""
            while not s.eof and s.top_unsafe != curr:
                if s.top == '\\':
                    buf.add(s.eat)
                    if s.eof:
                        raise unclosed_string_error(atom(buf, tag, s.get_range))
                buf.add(s.eat)
            if s.eof:
                raise unclosed_string_error(atom(buf, tag, s.get_range))
            discard s.eat
            atoms.add(atom(buf, tag, s.get_range))
        of {',',';'}:
            atoms.add(atom(buf, aSym, s.get_range))
        of {')',']','}'}:
            check_close_paren(buf)
            discard parens.pop()
            atoms.add(atom(buf, aPar, s.get_range))
        of {'(','[','{'}:
            if s.top == '|': buf.add(s.eat)
            let a = atom(buf, aPar, s.get_range)
            parens.add(a)
            atoms.add(a)
        of '#':
            if s.top == '[':
                # is multiline comment
                buf.add(s.eat)
                while not s.eof:
                    if s.top == '\\':
                        buf.add(s.eat)
                        if not s.eof:
                            buf.add(s.eat)
                    elif s.top == ']':
                        buf.add(s.eat)
                        if not s.eof and s.top == '#':
                            buf.add(s.eat)
                            break
                    else:
                        buf.add(s.eat)
            
            else:
                # is single line comment
                while not s.eof and s.top != '\n': buf.add(s.eat)
            # TODO: do not discard comments
            #atoms.add(atom(buf, aCom, s.get_range))
        of '|':
            if s.top in {')',']','}'}:
                buf.add(s.eat)
                check_close_paren(buf)
                discard parens.pop()
            else:
                while s.top in symb_tail: buf.add(s.eat)
            atoms.add(atom(buf, aPar, s.get_range))
        of '\\':
            buf.add(s.eat)
            discard
            #atoms.add(atom(buf, aEsc, s.get_range))
        of {'\t', ' '}:
            while s.top in {'\t', ' '}: buf.add(s.eat)
            atoms.add(atom(buf, aWs, s.get_range))
        of '\n':
            while s.top in {'\r', '\n'}: buf.add(s.eat)
            atoms.add(atom(buf, aNl, s.get_range))
        of '\r':
            discard curr
        else:
            discard curr

    if parens.len != 0:
        let delim = parens[^1]
        raise unclosed_delimiter_error(delim)

    atoms

proc indent*(tokens: seq[Exp]): seq[Exp] =
    var res: seq[Exp]
    var levels: seq[Exp]
    var i = 0

    proc pop_levels(n: int) =
        for _ in 0 ..< n:
            let tok = levels.pop()
            res.add(atom("$DED", aDed, tok.pos))
        if i < tokens.len:
            let tok = tokens[i]
            res.add(atom("$CNT", aCnt, tok.pos))

    proc find_level(match: string): int =
        for j in countdown(high(levels), 0):
            if levels[j].value == match:
                return j
        -1

    while i < tokens.len:
        var t = tokens[i]
        i += 1

        if t.tag notin {aWs, aNl}:
            res.add(t)

        elif t.tag == aNl and i < tokens.len:
            while i < tokens.len and tokens[i].tag == aNl:
                t = tokens[i]
                i += 1 
            if i >= tokens.len:
                break
            t = tokens[i]
            i += 1
            let next_level = t.value
            let last_level = if levels.len > 0: levels[^1].value else: ""
            if t.tag != aWs:
                pop_levels(levels.len)
                res.add(t)
            elif i < tokens.len and tokens[i].tag == aNl:
                continue
            elif next_level == last_level:
                res.add(atom("$CNT", aCnt, t.pos))
            elif next_level.starts_with(last_level):
                levels.add(t)
                res.add(atom("$IND", aInd, t.pos))
            elif last_level.starts_with(next_level):
                let level = find_level(next_level)
                if level == -1: raise bad_indent_error(levels, t)
                pop_levels(levels.len - level - 1)
            else:
                raise bad_indent_error(levels, t)

    pop_levels(levels.len)
    res