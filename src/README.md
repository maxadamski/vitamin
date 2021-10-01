# Internals

## Code Structure

```
src/
├─ common/
│  ├─ types.nim
│  ├─ error.nim
│  ├─ exp.nim
│  ├─ expstream.nim
│  ├─ syntaxrule.nim
│  ├─ utils.nim
├─ scan.nim
├─ syntax.nim
├─ parse.nim
├─ desugar.nim
├─ eval.nim
├─ format.nim
├─ vitamin.nim
```

## Overview

```
Text ---[scan]--> Atoms ---[parse]--> Terms ---[check]--> Core Terms ---[eval]--> Values
                                                              |
                                                              |---------[compile]--> Native Code
```