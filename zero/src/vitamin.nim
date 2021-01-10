import os, strformat, strutils, sequtils
import options, tables
import noise

import types, scan, parse

const version = "Vitamin₀ v0.1.0"

const repl_greeting = "{version} (Type :h ENTER for help)".fmt

const repl_help = """
End expressions with a semicolon `;` or two newlines to evaluate.

Use CTRL-C or CTRL-D to exit.

Commands:
  :q, :quit, :exit    exit the interactive session
  :h, :help           show this message
  :env                show the current environment
  :run FILE           run a file in the current environment
  :del NAME           delete name from the current enviroment
  :cls, :clear        clear the screen
""".fmt

const cmd_help = """
Positional arguments:
  INPUT ...           input source files (if none given, start REPL)

Optional arguments:
  -h, --help          show this help message and exit
  -V, --version       show version information
  
  -L, --library PATH  add PATH to library search path list
  -p, --prelude FILE  overwrite the default prelude path with FILE
  -P, --no-prelude    disable implicit prelude import
  
  -s, --no-greeting   disable REPL greeting
  -d, --debug scan|indent|parse|run|stat
                      show debug output for a compilation phase""".fmt

var global_env = new Env

proc panic(msg: string, code: int = 1) {.noreturn.} =
    echo msg
    quit(code)

proc print_help =
    echo "Usage: {paramStr(0)} [INPUT ...]\n\n{cmd_help}".fmt
    quit(0)

proc print_version =
    echo version
    echo fmt"Compiled on {CompileDate} [Nim {NimVersion}]"
    echo fmt"Copyright (c) 2018-{CompileDate[0..3]} Max Adamski"
    quit(0)

proc print_env(env: ref Env) =
    echo to_seq(env.vars.keys).join(" ")

proc find_source(name: string, search: seq[string]): Option[string] =
    if file_exists(name): return some(name)
    elif is_absolute(name) or search.len == 0: return none(string)
    for path in search:
        let full = join_path(path, name)
        if file_exists(full): return some(full)
    return none(string)

proc eval_string(env: ref Env, str: string) =
    let tokens = indent(scan(str))
    let exprs = parse(tokens)
    # let result = eval(env, exprs)

proc eval_file(env: ref Env, path: string) =
    let data = read_file(path)
    eval_string(env, data)
    echo fmt"DEBUG: run {path}"

proc repl(env: ref Env, silent: bool = false) =
    const prompt_ok   = "λ "
    const prompt_cont = "  "
    var noise = Noise.init()
    noise.set_prompt(prompt_ok)
    var lines: seq[string]
    if not silent: echo repl_greeting
    while true:
        if not noise.read_line(): break
        let line = noise.get_line()

        if lines.len > 0:
            # TODO: preload buffer with the current indentation level
            #noise.preload_buffer(lines[^1].take_while())
            lines.add(line)
            let exp = lines.join("\n")
            # if not terminated
            let ind = line.starts_with(" ") or line.starts_with("\t")
            if ind or not exp.ends_with("\n"):
                continue

            eval_string(env, exp)
            noise.set_prompt(prompt_ok)
            lines = @[]

        elif line == ":h" or line == ":help":
            echo repl_help
        elif line == ":q" or line == ":quit" or line == ":exit":
            break
        elif line == ":env":
            print_env(env)
        elif line == ":cls" or line == ":clear":
            stdout.write "\x1b[2J\x1b[H"
        elif line.starts_with(":run"):
            let args = line.split(" ")
            if args.len != 2:
                echo "Usage:  :del FILE"
                continue
            let path = args[1]
            if not file_exists(path):
                echo fmt"File {path} doesn't exist!"
                continue
            eval_file(env, path)
        elif line.starts_with(":del"):
            let args = line.split(" ")
            if args.len != 2:
                echo "Usage:  :del NAME"
                continue
            let name = args[1]
            if name notin env.vars:
                echo fmt"Variable `{name}` is not in the environment!"
                continue
            env.vars.del(name)
            echo fmt"Deleted {name}"
        else:
            # TODO: check if expression is complete with parser
            var exp = line
            let exp_complete = false
            if not (line.ends_with(";") or exp_complete):
                lines.add(line)
                noise.set_prompt(prompt_cont)
                continue

            eval_string(env, exp)

proc main =
    var inputs, libs, debug: seq[string]
    let vpath = get_env("VPATH")
    if vpath != "": libs = vpath.split(":")
    var prelude = none(string)
    var no_greeting = false
    var no_prelude = false
    var i = 1
    while i <= param_count():
        case param_str(i)
        of "-h", "--help": print_help()
        of "-V", "--version": print_version()
        of "-L", "--library": i += 1; libs.add(param_str(i))
        of "-d", "--debug": i += 1; debug.add(param_str(i))
        of "-p", "--prelude": i += 1; prelude = some(param_str(i))
        of "-P", "--no-prelude": no_prelude = true
        of "-s", "--no-greeting": no_greeting = true
        else: inputs.add(param_str(i))
        i += 1

    echo fmt"DEBUG: library paths = {libs}"
    echo fmt"DEBUG: input paths   = {inputs}"

    if not no_prelude:
        var path: string
        if prelude.is_some:
            path = prelude.get
        else:
            let found = find_source("prelude.v", libs)
            if found.is_none: panic fmt"ERROR: couldn't find file {path}"
            path = found.get
            
        if not file_exists(path): panic fmt"ERROR: prelude file {path} doesn't exist!"
        eval_file(global_env, path)

    libs = libs.filterIt(dir_exists(it))

    if inputs.len == 0:
        repl(global_env, no_greeting)
        quit(0)

    for path in inputs:
        if not file_exists(path): panic fmt"ERROR: input file {path} doesn't exist!"
        var local = global_env.extend()
        eval_file(local, path)

when is_main_module:
    main()
