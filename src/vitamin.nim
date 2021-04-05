import os, strformat, strutils, sequtils
import options, tables
import noise

import types, error, scan, parse, eval

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
                        show debug output for a compilation phase""".fmt

var inputs, libs, command_args: seq[string]
var debug: string

proc panic(msg: string, code: int = 1) {.noreturn.} =
    echo msg
    quit(code)

proc print_help =
    echo "Usage: {paramStr(0)} [INPUT ...]\n\n{cmd_help}".fmt
    quit(0)

proc print_version =
    echo version
    echo fmt"Compiled on {CompileDate} {CompileTime} [Nim {NimVersion}]"
    echo fmt"Copyright (c) 2018-{CompileDate[0..3]} Max Adamski"
    echo "More at: https://maxadamski.com/vitamin"
    quit(0)

proc print_env(env: Env) =
    echo to_seq(env.vars.keys).join(" ")

proc find_source(name: string, search: seq[string]): Option[string] =
    if file_exists(name): return some(name)
    elif is_absolute(name) or search.len == 0: return none(string)
    for path in search:
        let full = join_path(path, name)
        if file_exists(full): return some(full)
    return none(string)

proc eval_string(env: Env, str: string, file: Option[string] = none(string)) =
    try:
        let tokens = scan(str, file).indent()
        if debug == "scan":
            for x in tokens: echo x
            quit(0)
        let exprs = to_seq(parse(global_parser, tokens))
        if debug == "parse":
            for x in exprs: echo x
            quit(0)
        for x in exprs:
            let val = eval(env, x)
            let typ = v_type(env, val)
            if val != unit:
                echo $val, " : ", $typ
        #echo tokens.filter_it(it.tag in {aSym, aNum, aStr}).map_it(it.value).join(" ")
        # let result = eval(env, exprs)
    except VitaminError:
        let error = cast[ref VitaminError](get_current_exception())
        print_error(error)

proc eval_file(env: Env, path: string) =
    let data = read_file(path)
    echo fmt"DEBUG: run {path}"
    eval_string(env, data, some(path))

proc repl(env: Env, silent: bool = false) =
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

            eval_string(env, exp)
            noise.set_prompt(prompt_ok)
            lines = @[]

        elif cmd == ":h" or cmd == ":help":
            echo repl_help
        elif cmd == ":q" or cmd == ":quit" or cmd == ":exit":
            break
        elif cmd == ":env":
            print_env(env)
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
            eval_file(env, path)
        elif cmd.starts_with(":del"):
            let args = cmd.split(" ")
            if args.len != 2:
                echo "Usage:  :del NAME"
                continue
            let name = args[1]
            if name notin env.vars:
                echo fmt"Variable `{name}` is not in the environment!"
                continue
            env.vars.del(name)
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

            eval_string(env, exp)

proc main =
    let vpath = get_env("VITAPATH")
    if vpath != "": libs = vpath.split(":")
    var prelude = none(string)
    var command = none(string)
    var no_greeting = false
    var no_prelude = false
    var force_interactive = false
    var force_batch = false
    var i = 1
    while i <= param_count():
        case param_str(i)
        of "-h", "--help": print_help()
        of "-V", "--version": print_version()
        of "-L", "--library": i += 1; libs.add(param_str(i))
        of "-p", "--prelude": i += 1; prelude = some(param_str(i)); no_prelude = false
        of "-P", "--no-prelude": no_prelude = true
        of "-S", "--no-greeting": no_greeting = true
        of "-i", "--interative": force_interactive = true
        of "-I", "--no-interactive": force_batch = true
        of "-d", "--debug": i += 1; debug = param_str(i)
        of "-c", "--command":
            i += 1; command = some(param_str(i)); i += 1
            while i <= param_count():
                command_args.add(param_str(i)); i += 1
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

    for path in inputs:
        if not file_exists(path): panic fmt"ERROR: input file {path} doesn't exist!"
        var local = global_env.extend()
        eval_file(local, path)

    if command.is_some:
        # TODO: pass command_args
        for i, arg in command_args:
            echo fmt"args[{i}] = {arg}"
        echo command.get
        eval_string(global_env, command.get)

    if ((inputs.len == 0 and command.is_none) or force_interactive) and not force_batch:
        repl(global_env, no_greeting)

when is_main_module:
    main()
