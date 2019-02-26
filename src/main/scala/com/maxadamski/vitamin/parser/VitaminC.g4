grammar VitaminC;

// -- Parser Rules ----------

// blocks and primaries are fundametal ast building blocks,
// from which every sweet expression can be created

// TODO: make the TDOP handle primCall and expr*

program : chunk EOF ;
chunk : (expr ';')* expr ';'? | ;

expr
    : 'if' '(' expr ')' expr ('else' expr)?                 # exprIf
    | 'while' '(' expr ')' expr                             # exprWhile
    | 'for' '(' expr 'in' expr ')' expr                     # exprFor
    | 'use' expr (('select' | 'except') expr)? 'qualified'? # exprUse
    | prim+                                                 # exprFlat
    ;

prim
    : primCall
    | primLambda
    | primList
    | primBlock
    | atom
    | symbol
    | num
    | str
    ;

callee
    : primLambda
    | primBlock
    | atom
    ;

primCall : callee primList+ primLambda? ;
primList : '(' (expr (',' expr)*)? ','? ')' ;
primBlock : '{' chunk '}' ;
primLambda : '[' (expr 'in')? chunk ']' ;

// -- Boilerplate rules ------

num : Num ;
str : Str ;
atom : '`' (atom | symbol) '`' | Name ;

symbol
    : Symbol | EQUAL | MINUS | QUOTE
    | 'let' | 'var' | 'def' | 'fun' | 'type' | 'data' | 'enum' | 'protocol' | 'instance'
    | 'not' | 'and' | 'or' | 'div' | 'mod' | 'rem' | 'where' | 'as' | 'in'
    ;

// -- Lexer rules ------------

ShebangLine : '#!' ~[\u000A\u000D]* -> channel(HIDDEN) ;

fragment Whitespace : [ \t]+ ;
fragment Newline : '\r'? '\n' '\r'? ;
WS : Whitespace -> channel(HIDDEN) ;
NL : Newline -> channel(HIDDEN) ;

fragment NumberSign : [-+] ;
//fragment HexDigits : [0-9A-Fa-f][0-9A-Fa-f_]* ;
fragment DecDigits : [0-9][0-9_]* ;
//fragment OctDigits : [0-7][0-7_]* ;
//fragment BinDigits : [01][01_]* ;
fragment DecFraction : '.' DecDigits ;
//fragment HexFraction : '.' HexFraction ;
fragment DecExponent : [eE] NumberSign? DecDigits ;
//fragment HexExponent : [pP] NumberSign? HexDigits ;

Num : NumberSign? DecDigits DecFraction? ;

fragment EscapedString : '"' ( '\\' . | ~["\n\r] )* '"' ;
Str : EscapedString ;

fragment LineComment : '//' ~[\r\n]* ;
fragment BlockComment : '/*' ( BlockComment | . )*? '*/' ;
Comment : (LineComment | BlockComment) -> channel(HIDDEN) ;

//fragment IdHead : [\p{L}\p{Pc}] ;
//fragment IdTail : IdHead | [\p{N}] ;
fragment NameHead : [@#A-Za-z_] ;
fragment NameTail : [A-Za-z0-9_!?'] ;
fragment Reserved
    : 'def' | 'let' | 'fun' | 'for' | 'while' | 'if' | 'else'
    | 'in' | 'use' | 'select' | 'except' | 'qualified' ;
Name : NameHead NameTail* | '`' Reserved '`' ;

QUOTE : '\'' ;
BACKS : '\\' ;

MINUS : '-' ;
EQUAL : '=' ;
SEMI : ';' ;
LPAREN : '(' ;
RPAREN : ')' ;
COMMA : ',' ;

//fragment OpHead : [\p{Sm}\p{Po}] ;
//fragment OpTail : OpHead ;
fragment SymbolUsed : [:<>=|_.] ;
fragment SymbolHead : [*/~^$&|!?%+-] | SymbolUsed ;
fragment SymbolTail : SymbolHead ;
Symbol : SymbolHead SymbolTail* ;
