%option yylineno

%{
#include "sintatico.h"
#include <stdlib.h>
#include "symbol_table.h"
#include "stack.h"

extern FILE *file;
extern int function;

%}

white [ \t]+
letter [A-Za-z]
word {letter}+
digit [0-9]
integer {digit}+
variable ({word}|_)({word}|integer|_)*

%%

<<EOF>> {
	fprintf(file, "\n.Letext0:\n.Ldebug_info0:\n.Ldebug_abbrev0:\n.Ldebug_line0:\n");
	for(int i = 0; i <= 2*function; i++){
		fprintf(file, ".LASF%d:\n", i);
	}
	exit(0);
}
"int" return (INT);
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
"/*" return (INITIAL_COMMENT);
"*/" return (END_COMMENT);

{variable} {
	yylval.stringValue = malloc(sizeof(char)*(strlen(yytext)+1));
	strncpy(yylval.stringValue, yytext, strlen(yytext)+1);
	return(VARIABLE);
}
{integer} {
	yylval.intValue = atoi(yytext);
	return (INTEGER);
}
";" return (SEMICOLON);
"\n" { /*ignore*/ };

%%

int yywrap() {
	return 1;
}
