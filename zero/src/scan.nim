import types

proc scan*(text: string): seq[Atom] =
    @[]

proc indent*(tokens: seq[Atom]): seq[Atom] =
    tokens