parser grammar VitaminParser;
options { tokenVocab=VitaminLexer; }

// TODO: replace the ANTLR parser with the Pratt Parser

file : body EOF ;
body : expr? (SEMI expr)* SEMI* ;
expr : prim+ ;
prim : call ((list)+ func?)? | lite ;
call : atom | func | list ;
list : LPAREN (expr (COMMA expr)* COMMA? )? RPAREN ;
func : LBRACE (expr IN)? body RBRACE ;
atom : Atom | QUASI (Symb | Atom) QUASI ;
lite : Symb | Num1 | Num2 | Str1 | Str2 ;
