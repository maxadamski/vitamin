import options, tables, strutils
import scan
import common/exp

const special_tokens = [
    "$", "$$", "_", "it", "Varargs", "Quoted", "Expand", "Lazy", "unique", "undefined", "unreachable"
]

const keyword_tokens = [
    "let", "var",
    "case", "of",
    "if", "elif", "else",
    "return", "break", "continue", "shift", "reset",
    "while", "for",
    "try", "defer", "do", "with",
    "import", "use", "use-macro", "use-syntax",
    "quote", "gensym",
    "test", "xtest", "assert",
    "as", "in",
    "not", "and", "or", "xor",
    "mod", "div",
]

const operator_tokens = [
    "mut", "imm", "rdo", "wro", "tag", 
]

const builtins = [
    "type-of", "level-of"
]

const constants = [
    "true", "false", "none",
]

func compute_span_class_table(): Table[string, string] =
    for x in constants: result[x] = "co"
    for x in builtins: result[x] = "bu"
    for x in special_tokens: result[x] = "sp"
    for x in keyword_tokens: result[x] = "kw"
    for x in operator_tokens: result[x] = "op"

const span_class = compute_span_class_table()

proc format_file*(path: string, small=true): string =
    let data = read_file(path)
    let tokens = scan(data, file=some(path), start_line=0)

    result = new_string_of_cap(if small: 10 * data.len else: data.len)
    for token in tokens:
        var token = token
        let class = case token.tag
            of aStr: "str"
            of aNum: "num"
            of aCom: "com"
            of aLit:
                token.value = "`" & token.value & "`"
                "sp"
            of aSym:
                let class = span_class.get_or_default(token.value)
                if class.len > 0: class
                elif token.value[0] in symb_head: "op"
                elif token.value[0].is_upper_ascii: "ty"
                else: ""
            else: ""

        if class.len > 0:
            let value = token.value.replace("<", "&lt;")
            result &= "<span class=\"" & class & "\">" & value & "</span>"
        else:
            result &= token.value
