%{
#include "sintatico.h"
#include <stdlib.h>
#include "symbol_table.h"
#include "stack.h"
%}

white [ \t]+
letter [A-Za-z]
word {letter}+
symbols [""'/*-+.,<>:?~^=-_!@#$%&º°|)(]
digit [0-9]
integer {digit}+
variable ({word}|_)({word}|integer|_)*
phrase ({word}|{white}|{symbols}|{digit})*
barrabarra [//]
comment ({barrabarra})({phrase})*

%%

"int" return (INT);
"main" return (MAIN);
"return" return (RETURN);
"for" return (FOR);
"if" return (IF);
"else" return (ELSE);
"else if" return (ELSE_IF);	
"switch" return (SWITCH);
"case" return (CASE);
"default" return (DEFAULT);
":" return (COLON);
"break" return (BREAK);
"while" return (WHILE);
"do" return (DO);
"==" return (COMPARE);
"!=" return (DIFFERENT);
"<=" return (SMALLER);
">=" return (BIGGER);
"<" return (SMALLER_THEN);
">" return (BIGGER_THEN);
"!" return (NOT);
"&&" return (AND);
"||" return (OR);
"=" return (ASSIGN);
"+" return (PLUS);
"-" return (MINUS);
"/" return (DIVIDE);
"*" return (TIMES);
"(" return (LEFT_PARENTHESIS);
")" return (RIGHT_PARENTHESIS);
"{" return (LEFT_KEY);
"}" return (RIGHT_KEY);

{white} { /*ignore*/ };

{comment} { /*ignore*/ };

{variable} {
	yylval.stringValue = malloc(strlen(yytext));
	strncpy(yylval.stringValue, yytext, strlen(yytext));
	return(VARIABLE);
}

{integer} {
	yylval.intValue = atoi(yytext);
	return (INTEGER);
}

";" return (SEMICOLON);
"\n" { /*ignore*/ };
"\t" return(TAB);

%%

yywrap () {
	exit(0);
}
