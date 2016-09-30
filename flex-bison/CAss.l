%{
#include "sintatico.h"
#include <stdlib.h>
%}

white [ \t]+
letter [A-Za-z]
word {letter}+
digit [0-9]
integer {digit}+
variable ({word}|_)({word}|integer|_)*

%%

{white} { /*ignore*/ };
"int" return   (INT);
"=" return (ASSIGN);
"+" return (PLUS);
"-" return (MINUS);
"/" return (DIVIDE);
"*" return (TIMES);
"(" return (LEFT_PARENTHESIS);
")" return (RIGHT_PARENTHESIS);
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
"\n" return(END);
"\t" return(TAB);

%%

yywrap () {
	exit(0);
}
