let b:current_syntax = "vitamin"

setlocal iskeyword+=-

hi Comment cterm=italic gui=italic
hi Keyword cterm=italic gui=italic
"hi PreProc cterm=bold gui=bold

"hi def link vName        Identifier
hi def link vType        Constant
hi def link vPolymorph   Constant
hi def link vApply       PreProc
hi def link vSpecial     Keyword
hi def link vKeyword     Special
hi def link vComment     Comment
hi def link vString      Constant
hi def link vNumber      Number
hi def link vConstant    Number
hi def link vEscaped     Identifier
hi def link vPragma      Statement

syn region vComment start=/#/ end=/$/
syn region vComment start=/#\[/ end=/\]#/

syn region vString start=/[A-Za-z]*"/ skip=/\\[\\"]/ end=/"/ contains=vEscaped
syn region vString start=/[A-Za-z]*'/ skip=/\\[\\']/ end=/'/ contains=vEscaped

syn match vEscaped /\\[tnr\"\'\\]/
syn region vEscaped start=/`/ end=/`/

syn match vNumber /\<[-]\?[0-9_]\+\(\.[0-9_]\+\)\?[A-Za-z]*\>/
syn match vNumber /\<[-]\?0[box][0-9A-Za-z_]\+\>/

syn match vName /[a-z_][A-Za-z0-9_-]*/

syn match vPragma /[@][A-Za-z0-9_-]*/
syn keyword vPragma macro pure import extern unique opaque
syn keyword vKeyword use use-syntax use-macro assert quote
syn keyword vPragma Lazy Quoted Args Eval undefined unreachable

syn match vPolymorph /\<[A-Z]\>/
"syn match vPolymorph /\<Type\(-[1-9][0-9]*\)\=\>/
"syn keyword vPolymorph I8 I16 I32 I64 U8 U16 U32 U64 F16 F32 F64 F128

syn match vSpecial /\<_\>/
syn match vSpecial /$[0-9]\>/

syn keyword vConstant true false none

syn keyword vKeyword is as in not and or xor div mod

syn keyword vKeyword var if elif else while for case of defer pass
syn keyword vKeyword label jump with where do return continue break quote shift reset

syn match vType /[A-Z_][A-Za-z0-9_-]*/
syn keyword vType Type Union Inter Record Variant Enum Module Array List Set Map Ptr
syn keyword vType I8 I16 I32 I64 U8 U16 U32 U64 F32 F64 Int Str Size Float 
syn keyword vPolymorph Unit None Bool Any Never

syn match vApply /[A-Za-z_][A-Za-z0-9_-]*\((\)\@=/
syn keyword vApply ptr imm mut ro wo
"syn keyword vKeyword opt imm mut ptr
