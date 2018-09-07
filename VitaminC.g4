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
arguments : '(' ( argument (',' argument)* ','? )? ')' ;

exprs : expr (',' expr)* ;
*/


//function : 'fun' name parameters '->' name block ;
//clause : '(' expr ')' ;
//ifStatement : 'if' clause block ('else' 'if' clause block)* ('else' block)? ;
//whileStatement : 'while' clause block ;

program : chunk EOF ;
chunk : NL* expr? (NL+ expr)* NL* ;
block : '{' chunk '}' ;
quote : 'quote' block ;

expr : primary+ ;

primary
    : constant
    | quote
    | pragma
    | '(' expr ')'
    ;

pragma : '#' atom pragmaFun? ;
pragmaFun : '(' pragmaArg (',' pragmaArg)* ')' ;
pragmaArg : (atom COLON)? constant ;

constant : atom | intn | real | string ;

// boilerplate
atom : Name | Symbol | COLON ;
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

fragment HexDigits : [0-9A-Fa-f][0-9A-Fa-f_]* ;
fragment DecDigits : [0-9][0-9_]* ;
fragment OctDigits : [0-7][0-7_]* ;
fragment BinDigits : [01][01_]* ;
fragment Sign : [-+] ;

fragment RealLiteral
    :      DecDigits ('.' DecDigits)? ([eE] Sign? DecDigits)?
    | '0x' HexDigits ('.' HexDigits)? ([pP] Sign? HexDigits)?
    ;

fragment IntLiteral
    :      DecDigits
    | '0x' HexDigits
    | '0o' OctDigits
    | '0b' BinDigits
    ;

Real : RealLiteral [i]? ;
Int : IntLiteral [i]? ;

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

COLON : ':' ;
SEMI : ';' ;

//fragment OpHead : [\p{Sm}\p{Po}] ;
//fragment OpTail : OpHead ;
fragment SymbolHead : [-+=*/<>~^$&|!?%:] ;
fragment SymbolTail : SymbolHead ;
Symbol : SymbolHead SymbolTail* ;

