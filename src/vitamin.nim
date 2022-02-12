import os, strformat, strutils, sequtils
import options, tables
import noise

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
  FILE                  input source file (if none given, start REPL)
  ...                   program arguments

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
                        show debug output for a compilation phase""".fmt


var inputs, command_args: seq[string]

when defined(posix):
    let home = get_env("HOME")
    var libs = @[home & "/.local/lib/vita", "/usr/local/lib/vita", "/usr/lib/vita"]
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
    echo "Usage: {paramStr(0)} [FILE ...]\n\n{cmd_help}".fmt
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

proc eval_string(ctx: Ctx, str: string, file: Option[string] = none(string), start_line = 1, print = false, as_module = false): tuple[val, typ: Val] =
    try:
        let tokens = scan(str, file, start_line=start_line).filter_it(not it.is_comment).indent()
        if debug == "scan":
            for x in tokens: echo x.str
            quit(0)
        var exprs = to_seq(parse(parser, tokens))
        if debug == "parse":
            for x in exprs: echo x.str
            quit(0)
        if as_module:
            exprs = @[term("file".atom & exprs)]
        if debug == "desugar":
            for x in exprs: echo x.desugar.str
            quit(0)
        if debug == "core":
            for x in exprs:
                let core = ctx.check(x.desugar).exp
                if not core.is_nil: echo core
        if debug != "":
            return

        for x in exprs:
            let exp_surf = x.desugar
            let (exp_core, typ) = ctx.check(exp_surf)
            let val = ctx.eval(exp_core)
            result = (val, typ)
            if print and val != unit:
                echo val.str & " : " & typ.reify.str
    except VitaminError:
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error, force_trace=force_trace, trace_code=code_in_trace, trace_expr=expr_in_trace)

proc eval_file(ctx: Ctx, path: string): tuple[val, typ: Val] =
    let data = read_file(path)
    #echo fmt"DEBUG: run {path}"
    eval_string(ctx, data, some(path), as_module = true)

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
            discard eval_string(ctx, exp, print=true, start_line=stdin_history.count_lines-1)
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
                echo "Usage:  :run FILE"
                continue
            let path = args[1]
            if not file_exists(path):
                echo fmt"File {path} doesn't exist!"
                continue
            discard eval_file(ctx, path)
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
            discard eval_string(ctx, exp, print=true, start_line=stdin_history.count_lines-1)


proc main() =
    let vpath = get_env("VITAPATH")
    if vpath != "": libs = vpath.split(":") & libs
    var prelude : string
    var no_greeting = false
    var no_prelude = false
    var force_interactive = false
    var force_batch = false
    var only_format = false
    var input : string
    var args : seq[string]

    # TODO: All compilation options should be settable directly in .v files
    var arg = 1
    while arg <= param_count():
        case param_str(arg)
        of "-h", "--help": print_help()
        of "-V", "--version": print_version()
        of "-L", "--library": arg += 1; libs &= param_str(arg)
        of "-p", "--prelude": arg += 1; prelude = param_str(arg)
        of "-P", "--no-prelude": no_prelude = true
        of "-S", "--no-greeting": no_greeting = true
        of "-i", "--interative": force_interactive = true
        of "-I", "--no-interactive": force_batch = true
        of "-d", "--debug": arg += 1; debug = param_str(arg)
        of "--format": only_format = true
        else:
            if input == "":
                input = param_str(arg)
            else:
                args &= param_str(arg)
        arg += 1

    #echo fmt"DEBUG: library paths = {libs}"
    #echo fmt"DEBUG: input paths   = {inputs}"

    if input != "" and not file_exists(input):
        panic fmt"ERROR: input file {input} doesn't exist!"

    if only_format:
        stdout.write format_file(input)
        return

    libs = libs.filter(dir_exists)

    let root_ctx = Ctx(env: Env(parent: nil))
    var file_ctx = root_ctx.extend()

    if not no_prelude:
        if prelude == "":
            let found = find_source("prelude.v", libs)
            if found.is_none: panic fmt"ERROR: couldn't find prelude.v"
            prelude = found.get
            
        if not file_exists(prelude): panic fmt"ERROR: prelude file {prelude} doesn't exist!"
        let module = root_ctx.eval_file(prelude)
        file_ctx.env.define("Prelude", module.val, module.typ)
        for label, field in module.typ.rec_typ.fields:
            file_ctx.env.use(label, module.val.rec.ctx.eval(field.typ), term("Core/member".atom, "Prelude".atom, label.atom), module.val.rec.ctx)

    if input != "":
        discard file_ctx.eval_file(input)

    if (input == "" or force_interactive) and not force_batch:
        file_ctx.repl(no_greeting)

when is_main_module:
    main()
