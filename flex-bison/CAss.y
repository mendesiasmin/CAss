%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

	extern FILE *yyin;
	FILE *file;
%}

%union
{
    char *intValue;
    char *stringValue;
}

%token <intValue> INTEGER
%token <stringValue> VARIABLE
%token INT ASSIGN SEMICOLON END
%token PLUS MINUS TIMES DIVIDE LEFT_PARENTHESIS RIGHT_PARENTHESIS
%left PLUS MINUS
%left TIMES DIVIDE
%left NEG
%right LEFT_PARENTHESIS RIGHT_PARENTHESIS

%start Input

%%

Input:
	/*    */
	| Input Line
	;
Line:
	END
	| Assignment END {
		//printf("Resultado: %d\n",$1); 
	}
	;
Assignment:
	INT VARIABLE SEMICOLON {
		fprintf(file, "%s DQ 0\n", $2);
	}
	| INT VARIABLE ASSIGN INTEGER SEMICOLON {
		fprintf(file, "%s DQ %s\n", $2, $4);
	}
/*	| INT VARIABLE ASSIGN Expression SEMICOLON {$$ = $4;}
	;
Expression:
	INTEGER {$$ = $1;}
	| Expression PLUS Expression{
		fprintf(file, "%d + %d\n", $1, $3);
		$$ =  $1 + $3;
	}
	| Expression MINUS Expression{
		fprintf(file, "%d - %d\n", $1, $3);
		$$ = $1 - $3;
	}
	| Expression TIMES Expression{
		fprintf(file, "%d * %d\n", $1, $3);
		$$ = $1 * $3;
	}
	| Expression DIVIDE Expression{
		fprintf(file, "%d / %d\n", $1, $3);
		$$ = $1 / $3;
	}
	| MINUS Expression %prec NEG{
		fprintf(file, "%d = -%d\n", $2, $2);
		$$ = -$2;
	}
	| LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS { $$=$2; }
   	;
*/
%%

int yyerror() {
	printf("ERROR\n");
}

int main(void) {

	file = fopen("compilado.txt", "r");

	if(file != NULL){
		fclose(file);
		remove("compilado.txt");
	}

	file = fopen("compilado.txt", "a");

	yyparse();

	fclose(file);
}
