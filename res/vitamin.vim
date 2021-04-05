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
hi def link vNumber      Constant
hi def link vConstant    Constant
hi def link vEscaped     Special
hi def link vPragma      Statement

syn region vComment start=/#/ end=/$/
syn region vComment start=/#=/ end=/=#/

syn region vString start=/[A-Za-z]*"/ skip=/\\[\\"]/ end=/"/ contains=vEscaped
syn region vString start=/[A-Za-z]*'/ skip=/\\[\\']/ end=/'/ contains=vEscaped

syn match vEscaped /\\[tnr\"\'\\]/
syn region vString start=/`/ end=/`/

syn match vNumber /\<[-]\?[0-9_]\+\(\.[0-9_]\+\)\?[A-Za-z]*\>/
syn match vNumber /\<[-]\?0[box][0-9A-Za-z_]\+\>/

syn match vName /[a-z_][A-Za-z0-9_-]*/

"syn match vType /[A-Z_][A-Za-z0-9_-]*/
syn keyword vType Type

syn match vPragma /[@][A-Za-z0-9_-]*/
syn keyword vPragma pure lazy import extern unique opaque macro

syn match vPolymorph /\<[A-Z]\>/
"syn match vPolymorph /\<Type\(-[1-9][0-9]*\)\=\>/
"syn keyword vPolymorph I8 I16 I32 I64 U8 U16 U32 U64 F16 F32 F64 F128
"syn keyword vPolymorph Unit None Bool String Never

syn match vSpecial /\<_\>/
syn match vSpecial /$[0-9]\>/
"syn keyword vSpecial 

syn keyword vConstant true false none

syn keyword vKeyword enum module object
syn keyword vKeyword is as in not and or xor div mod

syn keyword vKeyword var use if elif else while for switch match case pass
syn keyword vKeyword with where when do return continue break shift reset
syn keyword vKeyword assert lazy pure guard

syn match vApply /[A-Za-z_][A-Za-z0-9_-]*\((\)\@=/
syn keyword vApply opt imm mut ptr
"syn keyword vKeyword opt imm mut ptr

