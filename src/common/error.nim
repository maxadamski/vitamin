import exp
import os, math, options, terminal, strutils, strformat
import types, utils

var stdin_history* = ""

func error*(node: Exp, msg: string): ref VitaminError =
    var error = new_exception(VitaminError, msg)
    error.node = node
    error

func error*(env: Env, msg: string, trace=false, exp=term()): ref VitaminError =
    var error = new_exception(VitaminError, msg)
    error.node = exp
    error.env = env.deepcopy
    error.with_trace = trace
    error

func error*(msg: string): ref VitaminError =
    error(term(), msg)

proc err_header*(node: Exp, name: string, endl = "\n"): string =
    let prefix = "-- " & name.to_upper() & " "
    var suffix = ""
    let pos = node.calculate_position
    if pos.is_some and pos.get.file != nil:
        let path = pos.get.file[].replace(get_env("HOME"), "~")
        suffix = " " & path
    let padding = '-'.repeat(terminal_width() - prefix.len - suffix.len)
    prefix & padding & suffix & endl

proc text_lines(text: string, start: int, stop = start): string =
    text.split('\n')[start-1 ..< stop].join("\n")

proc file_lines(file: string, start: int, stop = start): string =
    if file == "": return text_lines(stdin_history, start, stop)
    let text = read_file(file)
    text_lines(text, start, stop)

proc line_numbered(text: string, start: int): string =
    var lines = text.split('\n')
    let width = (start + lines.len).to_float.log10.ceil.to_int
    for i, line in lines:
        lines[i] = align($(start + i), width) & "| " & line
    lines.join("\n")

proc line_colored(text: string, color: int, start_line, stop_line, start_char, stop_char: int): string =
    var lines = text.split('\n')
    let start_color = "\e[{color}m".fmt
    let stop_color = "\e[0m"
    if start_line == stop_line:
        var line = lines[start_line]
        line = line[0 ..< start_char] & start_color & line[start_char ..< stop_char] & stop_color & line[stop_char .. ^1]
        lines[start_line] = line
    else:
        lines[start_line] = lines[start_line][0 ..< start_char] & start_color & lines[start_line][start_char .. ^1] & stop_color
        for i in 1 ..< stop_line:
            lines[i] = start_color & lines[i] & stop_color
        let i = min(stop_char, lines[stop_line].len)
        lines[stop_line] = start_color & lines[stop_line][0 ..< i] & stop_color & lines[stop_line][i .. ^1]
    lines.join("\n")

proc in_source_lines(node: Exp): string =
    let pos = node.calculate_position
    if pos.is_some:
        file_lines(pos.get.file[], pos.get.start_line, pos.get.stop_line)
    else:
        ""

proc in_source*(node: Exp, lookbehind = 0, color: int = 91, show_ws: bool = false): string =
    let pos_opt = node.calculate_position
    if pos_opt.is_none: return ""
    let pos = pos_opt.get
    let lines = node.in_source_lines()
    if lines == "": return ""
    var source = line_colored(lines, color, 0, pos.stop_line - pos.start_line, pos.start_char - 1, pos.stop_char - 1)
    if lookbehind > 0:
        source = file_lines(pos.file[], pos.start_line - lookbehind, pos.start_line - 1) & "\n" & source
    if show_ws:
        source = source.replace(" ", "∙").replace("\t", "→    ")
    source = line_numbered(source, max(1, pos.start_line - lookbehind))
    source

proc src*(exp: Exp, hi = true): string =
    let source = exp.in_source(color=if hi: 91 else: 0)
    if source == "": "" else: "\n\n" & source

proc stray_closing_paren_error*(node: Exp): auto =
    error(node, "Found closing paren `{node.value}`, but there was no opening paren.\n\n{node.in_source}".fmt)

proc mismatched_paren_error*(this_paren: Exp, last_paren: Exp): auto =
    let node = term(@[last_paren, this_paren])
    error(node, "Opening paren `{last_paren.value}` does not match closing paren `{this_paren.value}`.\n\n{node.in_source}".fmt)

proc unclosed_error(node: Exp, msg: string): auto =
    let source = "\e[91m" & node.in_source_lines.split('\n')[0] & "\e[39m"
    let pretty = line_numbered(source, node.pos.get.start_line)
    error(node, "{msg}\n\n{pretty}".fmt)

proc unclosed_string_error*(node: Exp): auto =
    unclosed_error(node, "Unclosed string.")

proc unclosed_delimiter_error*(node: Exp): auto =
    unclosed_error(node, "Unclosed paren `{node.value}`.".fmt)

proc bad_indent_error*(levels: seq[Exp], next: Exp): auto =
    # TODO: more specific message
    let pos_opt = term(levels).calculate_position
    var source = ""
    if pos_opt.is_some:
        let pos = pos_opt.get
        source = next.in_source(lookbehind=next.pos.get.stop_line - pos.start_line + 1, color=41, show_ws=true)
    error(next, "Indentation error.\n\n{source}".fmt)

proc parser_eos_error*(node: Exp, end_token: string): auto =
    error(node, "Unexpected end of file while looking for `{end_token}`\n\n{node.in_source}".fmt)

proc top_site*(env: Env, require_source=false): Exp =
    var env = env
    while env != nil:
        for call in env.call_stack.reverse_iter:
            if not require_source or call.site.src != "":
                return call.site
        env = env.parent
    return term()

proc src*(env: Env): string =
    return env.top_site(require_source=true).src

proc trace*(env: Env, max_source_lines = 3, max_expr_width = 50, show_source=false, show_expr=true): string =
    var trace: seq[string]
    var env = env
    while env != nil:
        for call in env.call_stack.reverse_iter:
            var mode = "eval"
            if call.infer: mode = "type"
            if env.in_macro: mode = "macr "
            mode = "\e[1m" & mode & "\e[0m"

            var head = mode & " in "
            let pos_opt = call.site.calculate_position
            var source: string

            if pos_opt.is_some:
                let pos = pos_opt.get
                var file = if pos.file != nil:
                    pos.file[].pretty_path
                else:
                    "<builtin>"
                if not show_source:
                    file &= ", line " & $pos.start_line
                head &= "\e[4m{file}\e[0m".fmt
                if show_source:
                    source = call.site.in_source
                    let line_count = source.count('\n')
                    if line_count > max_source_lines:
                        source = source.split('\n', 1)[0] & " \e[2m({line_count-1} more lines)\e[0m".fmt
            else:
                head &= "\e[4m<builtin>\e[0m"

            var repr = call.site.str
            if repr.len > max_expr_width:
                repr = repr[0 .. max_expr_width] & " \e[2m({repr.len - max_expr_width} more chars)\e[0m".fmt

            if show_expr or source.len == 0:
                if source.len == 0:
                    source = repr
                else:
                    source &= "\n" & repr

            trace &= head & "\n" & source.indent(2)
        env = env.parent
    trace.reversed.join("\n")

proc print_error*(error: ref VitaminError, file: Option[string] = none(string), prefix="ERROR", force_trace=false, trace_code=true, trace_expr=true) =
    let prefix = "-- {prefix} ".fmt
    var suffix = ""
    if file.is_some:
        suffix = " " & file.get
    else:
        var pos = error.node.calculate_position
        var env = error.env
        while env != nil and pos.is_none:
            for call in env.call_stack.reverse_iter:
                let site_pos = call.site.calculate_position
                if site_pos.is_some and site_pos.get.file != nil:
                    pos = site_pos
                    break
            env = env.parent

        if pos.is_some and pos.get.file != nil:
            if pos.get.file[] == "":
                suffix = " [input history]"
            else:
                let path = pos.get.file[].pretty_path
                suffix = " " & path


    let padding = '-'.repeat(terminal_width() - prefix.len - suffix.len)
    echo prefix, padding, suffix
    echo ""
    echo error.msg
    echo ""
    if error.env != nil and (error.with_trace or force_trace):
        echo error.env.trace(show_source=trace_code, show_expr=trace_expr)
        echo ""
