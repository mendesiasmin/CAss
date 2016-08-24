%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
%}

%token INT
%token INTEGER
%token ASSIGN
%token VARIABLE
%token SEMICOLON
%token END
/*%token PLUS MINUS TIMES DIVIDE

%left PLUS MINUS
%right TIMES DIVIDE */

%start Input

%%

Input:
	/*Empty*/
	| Input Line
	;
Line:
	END
	| Assignment END { printf("Resultado: %d\n",$1); }
	;
Assignment:
	INT VARIABLE ASSIGN INTEGER SEMICOLON {$$ = $4;}
	/*| Expression PLUS Expression{$$ = $1+$3;}
	| Expression MINUS Expression{$$ = $1-$3;}
	| Expression TIMES Expression{$$ = $1*$3;}
	| Expression DIVIDE Expression{$$ = $1/$3;}*/
	;

%%

int yyerror() {
	printf("ERROR\n");
}	

int main(void) {
   yyparse();
}