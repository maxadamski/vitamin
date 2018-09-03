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

program : chunk ;
block : '{' chunk '}' ;
chunk : (stat | decl)* ;

stat
    : expr SEMI
    // ifStatement
    // whileStatement
    //| 'break' SEMI
    ;

decl
    : variable SEMI
    | functionDirective SEMI
    | commandDirective SEMI
    ;

//function : 'fun' name parameters '->' name block ;

constantArg : (name COLON)? constant ;
functionDirective : '#' name '(' constantArg? (',' constantArg)* ')' ;
commandDirective : '#' name constant* ;

//clause : '(' expr ')' ;
//ifStatement : 'if' clause block ('else' 'if' clause block)* ('else' block)? ;
//whileStatement : 'while' clause block ;

variable : 'var' expr ;
expr : primary+ ;

primary
    : constant
    | '(' expr ')'
    ;

//expression : pre* primary suf* ( bin? pre* primary suf* )* ;

constant : string | number | symbol | name ;
symbol : Symbol | COLON ;
name : Name ;

number : Number ;
string : String ;


/****************************
 *       Lexer Rules        *
 ****************************/

ShebangLine : '#!' ~[\u000A\u000D]* -> channel(HIDDEN) ;

fragment Whitespace : [ \t]+ ;
fragment Newline : '\r'? '\n' '\r'? ;
WS : Whitespace -> skip ;
NL : Newline -> skip ;

fragment HexDigits : [0-9A-Fa-f][0-9A-Fa-f_]* ;
fragment DecDigits : [0-9][0-9_]* ;
fragment OctDigits : [0-7][0-7_]* ;
fragment BinDigits : [01][01_]* ;
fragment Sign : [-+] ;
fragment RealNumberLiteral
    :      DecDigits ( '.' DecDigits )? ( [eE] Sign? DecDigits )?
    | '0x' HexDigits ( '.' HexDigits )? ( [pP] Sign? HexDigits )?
    | '0o' OctDigits
    | '0b' BinDigits
    ;

Number : RealNumberLiteral [i]? ;

fragment EscapedString : '"' ( '\\' . | ~["\n\r] )* '"' ;
String : EscapedString ;

Rune : '\'' '\\'? . '\'' ;

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

