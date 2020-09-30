from termcolor import colored
from prompt_toolkit import PromptSession
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.keys import Keys
from prompt_toolkit.shortcuts import clear
from prompt_toolkit import ANSI

from src.run import run_input, run_file, vrepr
from src.utils import Error, print_error

keys = KeyBindings()
commands = {':q', ':exit', ':h', ':help', ':clear', ':run', ':env'}
prompt_cont = '| '
prompt_ok  = 'λ '
prompt_err = ANSI(colored('λ ', 'red'))
prompt_init = prompt_ok

@keys.add('enter')
def nl(event):
    text = event.current_buffer.text
    if text and text[-1] in ';\n':
        event.current_buffer.text = text[:-1]
        event.current_buffer.validate_and_handle()
    else:
        for command in commands:
            if text.startswith(command):
                event.current_buffer.validate_and_handle()
                return
        event.current_buffer.insert_text('\n')

@keys.add('tab')
def tab(event):
    if hasattr(event, 'current_buffer'):
        event.current_buffer.insert_text('  ')

def prompt(width, line_number, soft_wrap):
    return prompt_cont

def print_greeting():
    print("Vitamin C v0.0.1 (type :h ENTER for help)")

def print_help():
    from inspect import cleandoc
    print(cleandoc("""
    End expresions with a semicolon `;` or two newlines to evaluate.

    Commands
        :q, :exit \tExit the interactive session
        :h, :help \tShow this message
        :clear    \tClear the screen
        :run FILE \tRun file in the current environment
        :env local\tShow names of local variables
        :env using\tShow names of variables imported from other scopes
    """))

def run_repl(env, silent=False, debug=False, vi_mode=True):
    global prompt_init
    session = PromptSession(multiline=True, vi_mode=vi_mode,
            key_bindings=keys, prompt_continuation=prompt)

    if not silent:
        print_greeting()

    while True:
        try:
            text = session.prompt(prompt_init).rstrip(';\n')
            if text in [':q', ':exit']:
                return
            elif text in [':h', ':help']:
                print_help()
            elif text == ':clear':
                clear()
            elif text.startswith(':env'):
                info = text[4:].lstrip(' ')
                if info == 'local':
                    for name, (_, typ) in env.vars.items():
                        print(name, ':', vrepr(typ))
                if info == 'using':
                    for name, (_, typ) in env.uses.items():
                        print(name, ':', vrepr(typ))
            elif text.startswith(':run'):
                path = text[4:].lstrip(' ')
                run_file(env, path, search=False)
            else:
                for val, typ in run_input(env, text):
                    if val is not None:
                        print(vrepr(val, top=True))

        except Error as err:
            print_error(err, header=False)
            prompt_init = prompt_err

        except KeyboardInterrupt:
            #return
            pass

        except EOFError:
            return

        else:
            prompt_init = prompt_ok

