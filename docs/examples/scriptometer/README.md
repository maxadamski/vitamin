# Scriptometer 

> The Scriptometer tries to measure whether a programming language can be easily used for SOP (Script-Oriented Programming). A script is here a command line program, mostly used in a terminal.
> Source: http://rigaux.org/language-study/scripting-language

## Benchmarks

 `.v`|`.sh`|`.py`| file
-----|-----|-----|----------------------
   0 |   0 |   0 | smallest
  21 |  16 |  19 | hello-world
  18 |   7 |  29 | argv
  19 |  10 |  35 | env
  30 |  16 |  57 | file-exists
  32 |  16 |  54 | file-readable
  44 |  37 |  37 | formatting
  61 |  44 |  96 | system
 n/a |  22 |  88 | sed-in-place
 163 | 143 | 262 | compile-outdated
 389 | 248 | 513 | simple-grep

These benchmarks assume using the `scripting-prelude.v` instead of `prelude.v`.
