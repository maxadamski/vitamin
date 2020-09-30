import 'core'

Sized-Array = (len: Size, A: Type) => { items: &A }

`[` = (len: Size, A: Type) => Sized-Array(len, A)

get-item : (it: [N, A], index: Size) -> A

set-item : (it: [N, mut A], index: Size, item: A) -> Unit

for-each : (it: [N, A], operation: A -> Unit) -> Unit

concat : (left: [N, A], right: [M, A]) -> [N + M, A]

append : (it: [N, A], value: A) -> [N + 1, A]
