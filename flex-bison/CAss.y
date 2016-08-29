%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
%}

%token INT INTEGER ASSIGN VARIABLE SEMICOLON END
%token PLUS MINUS TIMES DIVIDE LEFT_PARENTHESIS RIGHT_PARENTHESIS
%left PLUS MINUS
%left TIMES DIVIDE
%left NEG
%right LEFT_PARENTHESIS RIGHT_PARENTHESIS

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
	| INT VARIABLE ASSIGN Expression SEMICOLON {$$ = $4;}
	;
Expression:
	INTEGER {$$ = $1;}
	| Expression PLUS Expression{printf("%d + %d\n", $1, $3);  $$ =  $1 + $3;}
	| Expression MINUS Expression{printf("%d - %d\n", $1, $3); $$ = $1 - $3;}
	| Expression TIMES Expression{printf("%d * %d\n", $1, $3); $$ = $1 * $3;}
	| Expression DIVIDE Expression{printf("%d / %d\n", $1, $3); $$ = $1 / $3;}
	| MINUS Expression %prec NEG {printf("%d = -%d\n", $2, $2); $$ = -$2;}
	| LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS { $$=$2; }
   	;

%%

int yyerror() {
	printf("ERROR\n");
}	

int main(void) {
	yyparse();
}
