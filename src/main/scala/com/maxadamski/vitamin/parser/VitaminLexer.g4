lexer grammar VitaminLexer;

Shebang : '#!' ~[\n\r]* -> channel(HIDDEN) ;
NL : '\r'? '\n' '\r'? -> channel(HIDDEN) ;
WS : [\t ]+ -> channel(HIDDEN) ;

fragment Radix  : '0' [box] | [1-9][0-9]* '#' ;
fragment Digit1 : [0-9A-Za-z][0-9A-Za-z_]* ;
fragment Digit2 : [0-9][0-9_]* ;
Num1 : Radix Digit1 ;
Num2 : Digit2 ('.' Digit2)? ;
//Num2 : Digit2 ('.' Digit2)? ([eE] [+-]? Digit2)? [i]? ;

Str1 : Atom? '"' ('\\"' | ~["\n\r])* '"' ;
Str2 : Atom? '"""' ('\\"'  | .)*? '"""' ;

Comment1 : '//' ~[\n\r]* -> channel(HIDDEN) ; 
Comment2 : '/*' (Comment2 | .)*? '*/' -> channel(HIDDEN) ;

fragment SymbHead : [:<>=_.*/~^$&|!?%+-] ;
fragment SymbTail : SymbHead | [@#] ;
fragment NameHead : [@#A-Za-z_] ;
fragment NameTail : [A-Za-z0-9_!?'] ;
Symb : Reserved | SymbHead SymbTail* ;
Atom : NameHead NameTail* ;

IN : 'in' ;
SEMI : ';' ;
COMMA : ',' ;
QUASI : '`' ;
LBRACE : '{' ;
RBRACE : '}' ;
LBRACK : '[' ;
RBRACK : ']' ;
LPAREN : '(' ;
RPAREN : ')' ;

fragment Reserved
    : 'let' | 'var' | 'def' | 'fun' | 'type' | 'data' | 'enum' | 'protocol' | 'instance'
    | 'not' | 'and' | 'or' | 'div' | 'mod' | 'rem' | 'where' | 'as' | IN
	;
