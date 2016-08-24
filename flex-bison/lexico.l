%{
#include "sintatico.h"
#include <stdlib.h>
%}

white [ /t]+
letter [A-Za-z]
word {letter}+
digit [0-9]
integer {digit}+
variable ({word}|_)({word}|{integer}|_)*


%%

{white} { /*ignore*/ };
"int" return   (INT);
"=" return (ASSIGN);
{variable} return(VARIABLE);
{integer} {
	yylval=atoi(yytext);
	return (INTEGER);
}
";" return (SEMICOLON);
"\n" return(END);

%%
yywrap () {
	return 0;
}
