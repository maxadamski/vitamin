grammar VitaminC;

/****************************
 *       Parser Rules       *
 ****************************/

program : chunk EOF ;
chunk : NL* ( NL* (expr | ';') (';' NL* | NL+) )* (expr | ';')? NL* ;

expr
    : letExpr
    | funExpr
    | ifExpr
    | whileExpr
    | prim+
    ;

prim
    : prim argList
    | '#'? atom
    | '@' atom NL?
    | lambda
    | literal
    | '(' NL* expr NL* ')'
    ;

type
    : atom ( '(' type (',' type)* ')' )?
    | type '->' type
    | '()'
    ;

patt
    : pattPrim (',' pattPrim)*
    ;

pattPrim
    : '_'
    | atom
    | '(' patt ')'
    ;

// basic expressions
// convert to mixfix macros?
letExpr : 'let' atom (':' type)? '=' expr ;
ifExpr : 'if' '(' NL* expr NL* ')' NL* expr NL* ('else' NL* expr)? ;
whileExpr : 'while' '(' NL* expr NL* ')' NL* expr ;

// generic clause
genItem : atom ;
genList : '(' genItem (',' genItem)* ')'  ;

// function
parType : type '...'? ;
parItem : atom ':' parType ('=' expr)? ;
parList : '(' ( parItem (',' parItem)* )? ')' ;
funExpr : 'fun' atom parList ('->' type)? ('with' genList)? '{' chunk '}' ;

// function calls
// qualified operators should allow being called like functions without quoting?
argItem : (atom ':')? expr ;
argList : '()' | '(' argItem (',' argItem)* ')' ;

// values
lambda : '{' (patt 'in')? chunk '}' ;
array : '[' NL* expr? (NL* ',' NL* expr)* NL* ']' ;
literal : vInt | vFlt | vStr | array ;

// boilerplate
vInt : Int ;
vStr : Str ;
vFlt : Flt ;
atom
    : '`' atom '`'
    | Name | Symbol
    | LANGLE | RANGLE | EQUAL | MINUS | QUOTE
    ;

/****************************
 *       Lexer Rules        *
 ****************************/

ShebangLine : '#!' ~[\u000A\u000D]* -> channel(HIDDEN) ;

fragment Whitespace : [ \t]+ ;
fragment Newline : '\r'? '\n' '\r'? ;
WS : Whitespace -> channel(HIDDEN) ;
NL : Newline ;

fragment NumberSign : [-+] ;
fragment HexDigits : [0-9A-Fa-f][0-9A-Fa-f_]* ;
fragment DecDigits : [0-9][0-9_]* ;
fragment OctDigits : [0-7][0-7_]* ;
fragment BinDigits : [01][01_]* ;
fragment DecFraction : '.' DecDigits ;
fragment HexFraction : '.' HexFraction ;
fragment DecExponent : [eE] NumberSign? DecDigits ;
fragment HexExponent : [pP] NumberSign? HexDigits ;

fragment FltReal : DecDigits DecFraction ;
fragment IntReal : DecDigits ;

Flt : FltReal ;
Int : IntReal ;

fragment EscapedString : '"' ( '\\' . | ~["\n\r] )* '"' ;
Str : EscapedString ;

//Rune : '\'' '\\'? . '\'' ;

fragment LineComment : '//' ~[\r\n]* ;
fragment BlockComment : '/*' ( BlockComment | . )*? '*/' ;
Comment : (LineComment | BlockComment) -> channel(HIDDEN) ;

//fragment IdHead : [\p{L}\p{Pc}] ;
//fragment IdTail : IdHead | [\p{N}] ;
fragment NameHead : [_A-Za-z] ;
fragment NameTail : NameHead | [0-9] ;
Name : NameHead NameTail* ;

MINUS : '-' ;
LANGLE : '<' ;
RANGLE : '>' ;
QUOTE : '\'' ;
EQUAL : '=' ;
COLON : ':' ;
SEMI : ';' ;
PIPE : '|' ;

//fragment OpHead : [\p{Sm}\p{Po}] ;
//fragment OpTail : OpHead ;
fragment SymbolUsed : [-<>=:|] ;
fragment SymbolHead : [+*/~^$&|!?%] | SymbolUsed ;
fragment SymbolTail : SymbolHead ;
Symbol : SymbolHead SymbolTail* ;
