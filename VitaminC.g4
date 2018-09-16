grammar VitaminC;


/****************************
 *       Parser Rules       *
 ****************************/


/*
enumeration : 'enum' name parameters? '{' decl* '}' ;
autoParameter : name (':' type)? ;
autoParameters : '(' ( autoParameter (',' autoParameter)* )? ')' ;
closure : ( autoParameters ('->' type)? )? block ;
directive : Directive | Annotation ;

precedenceProperty : name '=' name term ;
precedence : 'operator_precedence' name '{' precedenceProperty+ '}' term ;
operator : 'operator' name name name term ;

function : 'fun' name parameters '->' name block ;
structure : 'struct' name parameters? '{' decl* '}' ;
label : name ':' ;

parameter : name (':' name ('=' expr)? | '=' expr) ;
parameters :  '(' ( parameter (',' parameter)* )? ')' ;

argument : (name ':')? expr ;
arguments : '(' ( argument (',' argument)* ','? )? ')f' ;

exprs : expr (',' expr)* ;
*/


//function : 'fun' name parameters '->' name block ;
//clause : '(' expr ')' ;
//ifStatement : 'if' clause block ('else' 'if' clause block)* ('else' block)? ;
//whileStatement : 'while' clause block ;

program : chunk EOF ;
chunk : NL* expr? ((SEMI NL* | NL+) expr)* NL* ;

expr
    : primary+
    | 'fun' fun
    ;

primary
    : call
    | constant
    | function
    | pragma
    | '(' expr ')'
    ;

function
    : '{' (atom? (',' atom)* PIPE)? chunk '}'
    ;

//typ : atom | atom LANGLE typ (',' typ)* RANGLE | '_' ;
typ : atom ;
fun : atom '(' funParam? (',' funParam)* ')' ('->' typ)? '{' chunk '}' ;
funParam : atom COLON typ (EQUAL expr)? ;

// combine callArg and pragmaArg after creating the first compiler
call : atom '(' callArg? (',' callArg)* ')' ;
callArg : (atom COLON)? expr ;
pragma : '#' atom pragmaFun? ;
pragmaFun : '(' pragmaArg (',' pragmaArg)* ')' ;
pragmaArg : (atom COLON)? constant ;


// boilerplate
constant : atom | intn | real | string ;
atom : Name | Symbol | PIPE | QUOTE | COLON | EQUAL | LANGLE | RANGLE | '`' atom '`' ;
intn : Int ;
real : Real ;
string : String ;


/****************************
 *       Lexer Rules        *
 ****************************/

ShebangLine : '#!' ~[\u000A\u000D]* -> channel(HIDDEN) ;

fragment Whitespace : [ \t]+ ;
fragment Newline : '\r'? '\n' '\r'? ;
WS : Whitespace -> skip ;
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

fragment FloatReal
    :      DecDigits (DecFraction DecExponent? | DecExponent)
    | '0x' HexDigits (HexFraction HexExponent? | HexExponent)
    ;

fragment IntReal
    :      DecDigits
    | '0x' HexDigits
    | '0o' OctDigits
    | '0b' BinDigits
    ;

Real : FloatReal [i]? ;
Int  : IntReal   [i]? ;

fragment EscapedString : '"' ( '\\' . | ~["\n\r] )* '"' ;
String : EscapedString ;

//Rune : '\'' '\\'? . '\'' ;

fragment LineComment : '//' ~[\r\n]* ;
fragment BlockComment : '/*' ( BlockComment | . )*? '*/' ;
Comment : (LineComment | BlockComment) -> channel(HIDDEN) ;

//fragment IdHead : [\p{L}\p{Pc}] ;
//fragment IdTail : IdHead | [\p{N}] ;
fragment NameHead : [_A-Za-z] ;
fragment NameTail : NameHead | [0-9] ;
Name : NameHead NameTail* ;

LANGLE : '<' ;
RANGLE : '>' ;
QUOTE : '\'' ;
EQUAL : '=' ;
COLON : ':' ;
SEMI : ';' ;
PIPE : '|' ;

//fragment OpHead : [\p{Sm}\p{Po}] ;
//fragment OpTail : OpHead ;
fragment SymbolHead : [-+=*/<>~^$&|!?%:] ;
fragment SymbolTail : SymbolHead ;
Symbol : SymbolHead SymbolTail* ;

