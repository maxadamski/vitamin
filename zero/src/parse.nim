import types

proc parse*(tokens: seq[Atom]): seq[Exp] =
    @[]