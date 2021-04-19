import types
import options, sets, strutils

type
    ExpStream* = object
        checkpoints: seq[int]
        items: seq[Exp]
        index*: int

func checkpoint*(x: var ExpStream) =
    x.checkpoints.add(x.index)


func backtrack*(x: var ExpStream) =
    x.index = x.checkpoints[^1]
    x.checkpoints = x.checkpoints[0 ..< ^1]

proc mkstream*(items: seq[Exp]): ExpStream =
    ExpStream(items: items, index: 0)

proc eos*(self: ExpStream): bool =
    self.index >= self.items.len

proc peek_opt*(self: ExpStream, ind: bool = false): Option[Exp] =
    var i = self.index
    while not ind and i < self.items.len and  self.items[i].is_whitespace:
        i += 1
    if i < self.items.len:
        some(self.items[i])
    else:
        none(Exp)

proc next_opt*(self: var ExpStream, ind: bool = false): Option[Exp] =
    var i = self.index
    while not ind and i < self.items.len and self.items[i].is_whitespace:
        i += 1
    if i >= self.items.len: return none(Exp)
    let item = self.items[i]
    self.index = i + 1
    some(item)

proc peek*(self: ExpStream, ind: bool = false): Exp = 
    self.peek_opt(ind=ind).get

proc next*(self: var ExpStream, ind: bool = false): Exp =
    self.next_opt(ind=ind).get

#proc expect_raw*(self: ExpStream, token: string): bool =
#    if self.index >= self.items.len: return false
#    let e = self.items[self.index]
#    return e.kind == expAtom and e.value == token

proc expect*(self: ExpStream, token: string, raw: bool = false): bool =
    if self.index >= self.items.len: return token == "$EOS"
    let e = if raw:
        self.items[self.index]
    else:
        let x = self.peek_opt(ind=raw or token.starts_with("$"))
        if x.is_none: return false
        x.get
    return e.kind == expAtom and e.value == token

proc expect_in*(self: ExpStream, tokens: HashSet[string], raw: bool = false): bool =
    for token in tokens:
        if self.expect(token, raw=raw):
            return true
    return false

#proc expect_notin*(self: ExpStream, tokens: HashSet[string], ind: bool = false): bool =
#    if self.eos: return false
#    let e = self.peek(ind=ind or tokens.any_it(it.starts_with("$")))
#    return e.kind == expAtom and e.value notin tokens

proc eat_atom*(self: var ExpStream, token: string): Option[Exp] =
    let raw = token.starts_with("$")
    if not self.expect(token, raw=raw):
        return none(Exp)
    self.next_opt(ind=raw)