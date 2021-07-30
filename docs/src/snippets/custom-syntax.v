cmp(class: Comparable(a) = _, x y: a) -> Int =
  if x < y return +1
  if x > y return -1
  return 0

cmp-syntax = Syntax(
  # Grammar of this syntax rule
  grammar  = 'x "<=>" y'
  # Each syntax rule belongs to a precedence group
  group    = 'cmp'
  # Specify priority relations to existing syntax precedence groups
  priority = 'cmp > definition'
  # argument names of this function must match the names in the grammar string
  function = cmp
)

# To use custom syntax you must call the `use-syntax` macro
use-syntax cmp-syntax

a = 0 <=> 1
b = 1 <=> 1
assert a == 1 and b == 0