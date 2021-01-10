import strformat, strutils
import tables

import types

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

func new_scanner(str: string, file: ref string): Scanner =
    Scanner(x_last: 1, y_last: 1, x: 1, y: 1, i: 0, tmp: "", text: str, file: file)

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

proc scan*(text: string): seq[Atom] =
    var atoms: seq[Atom]
    var s = new_scanner(text, nil)
    var buf = "" 
    var parens: seq[Atom]
    proc check_close_paren(paren: string) =
        if parens.len == 0:
            echo fmt"Found closing paren `{paren}` but there was no open paren."
            quit(1)
        if parens[^1].value != open_comp[paren]:
            echo fmt"Incompatible closing paren `{paren}`. Currently open paren is `{parens[^1]}`"
            quit(1)

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
            buf = ""
            while not s.eof and s.top_unsafe != curr:
                if s.top == '\\':
                    buf.add(s.eat)
                    if s.eof:
                        echo "Unexpected EOF"
                        quit(1)
                buf.add(s.eat)
            if s.eof:
                echo "Unclosed string"
                quit(1)
            discard s.eat
            atoms.add(atom(buf, aStr, s.get_range))
        of {',',';'}:
            atoms.add(atom(buf, aSym, s.get_range))
        of {')',']','}'}:
            check_close_paren(buf)
            discard parens.pop()
            atoms.add(atom(buf, aSym, s.get_range))
        of {'(','[','{'}:
            if s.top == '|': buf.add(s.eat)
            let a = atom(buf, aSym, s.get_range)
            parens.add(a)
            atoms.add(a)
        of '#':
            while s.top != '\n': buf.add(s.eat)
            # TODO: do not discard comments
            #atoms.add(atom(buf, aCom, s.get_range))
        of '|':
            if s.top in {')',']','}'}:
                buf.add(s.eat)
                check_close_paren(buf)
                discard parens.pop()
            else:
                while s.top in symb_tail: buf.add(s.eat)
            atoms.add(atom(buf, aSym, s.get_range))
        of '\\':
            buf.add(s.eat)
            atoms.add(atom(buf, aEsc, s.get_range))
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
        echo fmt"Unclosed delimiter `{parens[^1]}`"
        quit(1)

    atoms

proc indent_error(levels: seq[Atom], next: Atom) =
    echo "Indentation error"
    quit(1)

proc indent*(tokens: seq[Atom]): seq[Atom] =
    var res: seq[Atom]
    var levels: seq[Atom]
    var i = 0

    proc pop_levels(n: int) =
        var tok: Atom
        for _ in 0..<n:
            tok = levels.pop()
            res.add(Atom(value: "$DED", tag: aDed, pos: tok.pos))
        if i < tokens.len:
            tok = tokens[i]
            res.add(Atom(value: "$CNT", tag: aCnt, pos: tok.pos))

    proc find_level(match: string): int =
        for j in countdown(high(levels), 0):
            if levels[j].value == match:
                return j
        -1

    while i < tokens.len:
        let t = tokens[i]
        i += 1
        if t.tag notin {aWs, aNl}:
            res.add(t)

        elif t.tag == aNl and i < tokens.len:
            let next = tokens[i]
            let next_level = next.value
            let last_level = if levels.len > 0: levels[^1].value else: ""
            if next.tag != aWs:
                pop_levels(levels.len)
                res.add(next)
            elif i < tokens.len and tokens[i].tag == aNl:
                continue
            elif next_level == last_level:
                res.add(Atom(value: "$CNT", tag: aCnt, pos: next.pos))
            elif next_level.starts_with(last_level):
                levels.add(next)
                res.add(Atom(value: "$IND", tag: aInd, pos: next.pos))
            elif last_level.starts_with(next_level):
                let level = find_level(next_level)
                if level == -1: indent_error(levels, next)
                pop_levels(level)
            else:
                indent_error(levels, next)

    pop_levels(levels.len)
    res