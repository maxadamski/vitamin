import os, strformat, strutils, sequtils
import options, tables
import noise

when defined(profile):
    import nimprof

when defined(profile):
    import nimprof

import scan, parse, eval, format, desugar
import common/[exp, error, types]
from syntax import parser

const (major_ver, minor_ver, patch_ver) = (0, 1, 0)
const night_ver = CompileDate[2 .. 3] & CompileDate[5 .. 6] & CompileDate[8 .. 9]
const ver_meta = if defined(release): "" else: fmt"+dev.{night_ver}"

const version = "Vitamin₀ v{major_ver}.{minor_ver}.{patch_ver}{ver_meta}".fmt

const repl_greeting = "{version} (Type :h ENTER for help)".fmt

const repl_help = """
End expressions with a semicolon `;` or two newlines to evaluate.

Use CTRL-C or CTRL-D to exit.

Commands:
  :q, :quit, :exit    exit the interactive session
  :h, :help           show this message
  :ctx                show the current environment
  :run FILE           run a file in the current environment
  :del NAME           delete name from the current enviroment
  :cls, :clear        clear the screen
""".fmt

const cmd_help = """
Positional arguments:
  INPUT ...             input source files (if none given, start REPL)

Optional arguments:
  -h, --help            show this help message and exit
  -V, --version         show version information
  -L, --library PATH    add PATH to library search path list
  -p, --prelude FILE    overwrite the default prelude path with FILE
  -P, --no-prelude      disable implicit prelude import
  -c, --command STRING  run program passed in STRING
                        the remaining arguments will be passed as program arguments
  -i, --interactive     enter REPL even if input files were provided
  -I, --no-interactive  do not enter REPL even if no input files were provided
  -S, --no-greeting     disable REPL greeting
  -d, --debug scan|indent|parse|run|stat
                        show debug output for a compilation phase
  --trace               force show stack trace on error
  --trace-mode=MODE     MODE := expr | code | code+expr (default=expr)""".fmt


var inputs, command_args: seq[string]

when defined(posix):
    let home = get_env("HOME")
    var libs = @[home & "/.local/lib/vita", "/usr/lib/vita"]
else:
    var libs: seq[string]

var debug: string
var force_trace = false
var code_in_trace = false
var expr_in_trace = true

proc panic(msg: string, code: int = 1) {.noreturn.} =
    echo msg
    quit(code)

proc print_help =
    echo "Usage: {paramStr(0)} [INPUT ...]\n\n{cmd_help}".fmt
    quit(0)

proc print_version =
    echo version
    echo fmt"Compiled on {CompileDate} {CompileTime} UTC [Nim {NimVersion}] [{hostOS}] [{hostCPU}]"
    echo fmt"Copyright (c) 2018-{CompileDate[0..3]} Max Adamski"
    echo "More at: https://maxadamski.com/vitamin"
    quit(0)

proc print_env(ctx: Ctx) =
    echo to_seq(ctx.env.vars.keys).join(" ")

proc find_source(name: string, search: seq[string]): Option[string] =
    if file_exists(name): return some(name)
    elif is_absolute(name) or search.len == 0: return none(string)
    for path in search:
        let full = join_path(path, name)
        if file_exists(full): return some(full)
    return none(string)

proc eval_string(ctx: Ctx, str: string, file: Option[string] = none(string), start_line = 1, print = false) =
    try:
        let tokens = scan(str, file, start_line=start_line).filter_it(not it.is_comment).indent()
        if debug == "scan":
            for x in tokens: echo x.str
            quit(0)
        let exprs = to_seq(parse(parser, tokens))
        if debug == "parse":
            for x in exprs: echo x.str
            quit(0)
        if debug == "desugar":
            for x in exprs: echo x.desugar.str
            quit(0)
        if debug == "core":
            for x in exprs:
                let core = ctx.check(x.desugar).exp
                if not core.is_nil: echo core
            quit(0)
        for x in exprs:
            let exp_surf = x.desugar
            let (exp_core, _) = ctx.check(exp_surf)
            let val = ctx.eval(exp_core)
            if print and val != unit:
                echo val.str
    except VitaminError:
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error, force_trace=force_trace, trace_code=code_in_trace, trace_expr=expr_in_trace)

proc eval_file(ctx: Ctx, path: string) =
    let data = read_file(path)
    #echo fmt"DEBUG: run {path}"
    eval_string(ctx, data, some(path))

proc repl(ctx: Ctx, silent: bool = false) =
    const prompt_ok   = "λ "
    const prompt_len  = prompt_ok.len
    const prompt_cont = "  "
    var noise = Noise.init()
    noise.set_prompt(prompt_ok)
    var lines: seq[string]
    if not silent: echo repl_greeting
    while true:
        if not noise.read_line(): break
        let line = noise.get_line()
        let cmd = line.strip()

        if lines.len > 0:
            # TODO: preload buffer with the current indentation level
            #noise.preload_buffer(lines[^1].take_while())
            lines.add(line)
            let exp = lines.join("\n")
            # if not terminated
            let ind = line.starts_with(" ") or line.starts_with("\t")
            if ind or not exp.ends_with("\n"):
                continue

            # remove last empty line from terminal
            stdout.write "\e[1A\e[K"

            stdin_history &= exp
            eval_string(ctx, exp, print=true, start_line=stdin_history.count_lines-1)
            noise.set_prompt(prompt_ok)
            lines = @[]

        elif cmd == ":h" or cmd == ":help":
            echo repl_help
        elif cmd == ":q" or cmd == ":quit" or cmd == ":exit":
            break
        elif cmd == ":history":
            echo stdin_history
        elif cmd == ":ctx":
            print_env(ctx)
        elif cmd == ":cls" or cmd == ":clear":
            stdout.write "\x1b[2J\x1b[H"
        elif cmd.starts_with(":run"):
            let args = cmd.split(" ")
            if args.len != 2:
                echo "Usage:  :del FILE"
                continue
            let path = args[1]
            if not file_exists(path):
                echo fmt"File {path} doesn't exist!"
                continue
            eval_file(ctx, path)
        elif cmd.starts_with(":del"):
            let args = cmd.split(" ")
            if args.len != 2:
                echo "Usage:  :del NAME"
                continue
            let name = args[1]
            if name notin ctx.env.vars:
                echo fmt"Variable `{name}` is not in the environment!"
                continue
            ctx.env.vars.del(name)
            echo fmt"Deleted {name}"
        elif cmd == "":
            continue
        else:
            # TODO: check if expression is complete with parser
            var exp = line
            let exp_complete = false
            if not (exp.ends_with(";") or exp_complete):
                lines.add(line)
                noise.set_prompt(prompt_cont)
                continue
            if exp.ends_with(";"):
                # remove last semicolon from expression
                exp = exp[0 .. ^2]
                # remove last semicolon from terminal 
                let last_col = exp.len + prompt_len - 1
                # save pos, move up, move right to last_col, restore pos
                stdout.write "\e[s\e[F\e[{last_col}C \e[u".fmt

            stdin_history &= exp & "\n"
            eval_string(ctx, exp, print=true, start_line=stdin_history.count_lines-1)


proc main() =
    let vpath = get_env("VITAPATH")
    if vpath != "": libs = vpath.split(":") & libs
    var prelude = none(string)
    var command = none(string)
    var no_greeting = false
    var no_prelude = false
    var force_interactive = false
    var force_batch = false
    var only_format = false

    var arg = 1
    while arg <= param_count():
        case param_str(arg)
        of "-h", "--help": print_help()
        of "-V", "--version": print_version()
        of "-L", "--library": arg += 1; libs.add(param_str(arg))
        of "-p", "--prelude": arg += 1; prelude = some(param_str(arg)); no_prelude = false
        of "-P", "--no-prelude": no_prelude = true
        of "-S", "--no-greeting": no_greeting = true
        of "-i", "--interative": force_interactive = true
        of "-I", "--no-interactive": force_batch = true
        of "--format": only_format = true
        of "--trace": force_trace = true
        of "-d", "--debug": arg += 1; debug = param_str(arg)
        of "--trace-mode=code":
            code_in_trace = true; expr_in_trace = false
        of "--trace-mode=expr":
            code_in_trace = false; expr_in_trace = true
        of "--trace-mode=code+expr", "--trace-mode=expr+code":
            code_in_trace = true; expr_in_trace = true
        of "-c", "--command":
            arg += 1; command = some(param_str(arg)); arg += 1
            while arg <= param_count():
                command_args.add(param_str(arg)); arg += 1
        else: inputs.add(param_str(arg))
        arg += 1

    #echo fmt"DEBUG: library paths = {libs}"
    #echo fmt"DEBUG: input paths   = {inputs}"

    for path in inputs:
        if not file_exists(path): panic fmt"ERROR: input file {path} doesn't exist!"

    if only_format:
        for path in inputs:
            stdout.write format_file(path)
        return

    libs = libs.filter_it(dir_exists(it))

    if not no_prelude:
        var path: string
        if prelude.is_some:
            path = prelude.get
        else:
            let found = find_source("prelude.v", libs)
            if found.is_none: panic fmt"ERROR: couldn't find file {path}"
            path = found.get
            
        if not file_exists(path): panic fmt"ERROR: prelude file {path} doesn't exist!"
        root_ctx.eval_file(path)

    for path in inputs:
        var file_ctx = root_ctx.extend()
        file_ctx.eval_file(path)

    if command.is_some:
        # TODO: pass command_args
        for i, arg in command_args:
            echo fmt"args[{i}] = {arg}"
        #echo command.get
        root_ctx.eval_string(command.get)

    if ((inputs.len == 0 and command.is_none) or force_interactive) and not force_batch:
        root_ctx.repl(no_greeting)

when is_main_module:
    main()
