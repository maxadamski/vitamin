# core syntax definitions

round-parens = Syntax("`(` (Any `,`)++ `)`", group="Round-Parens", function="group")

pow-expr = Syntax("Pow-Base `^` Pow", group="Pow-Base", function="pow")

apply-expr = Syntax("_ `(` (Any `,`)** `)`", group="Apply", function="apply")

lambda-expr = Syntax("_ `=>` _", group="Lambda", function="lambda")

case-expr = Syntax("`case` _? (`of` _ `do`? _%)+", group="Case", function="case")

for-expr = Syntax("`for` _ `in` _ `do`? _%", group="For", function="for")

while-expr = Syntax("`while` _ `do`? _%", group="While", function="while")

if-expr = Syntax("`if` _ `do`? _% (`elif` _ `do`? _%)* (`else` _%)?", group="If", function="if")
