import 'core'
import 'dynamic-array.v'

String = { bytes: [Byte] }

concat : (left right: String) -> String

join : (items: ..String; start sep end: String) -> String

split : (it: String, separator: String; count: ?Int = none) -> [String]

has-prefix : (it prefix: String) -> Bool

has-suffix : (it suffix: String) -> Bool

to-upper : (it: String) -> String

to-lower : (it: String) -> String

to-title : (it: String) -> String

contains : (it substring: String) -> Bool

index : (it substring: String) -> ?U64

left-pad : (it: String, width: U64, fill: String = ' ') -> String

replace : (it old new: String; count: ?Int = none) -> String
