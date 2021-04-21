
iterator reverse_iter*[T](a: seq[T]): T {.inline.} =
    var i = a.high
    while i > -1:
        yield a[i]
        dec(i)
