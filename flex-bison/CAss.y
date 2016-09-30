%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "symbol_table.h"

	extern FILE *yyin;
	FILE *file;
	char *variable;

%}

%union
{
    int intValue;
    char *stringValue;
}


%token INTEGER
%token <stringValue> VARIABLE
%token INT ASSIGN SEMICOLON END TAB
%token PLUS MINUS TIMES DIVIDE LEFT_PARENTHESIS RIGHT_PARENTHESIS
%left PLUS MINUS
%left TIMES DIVIDE
%left NEG
%right LEFT_PARENTHESIS RIGHT_PARENTHESIS

%type<intValue> Expression INTEGER

%start Input

%%

Input:
	/*    */
	| Input Line
	;
Line:
	END
	| Assignment END {
		
	}
	;
Assignment:
	INT VARIABLE SEMICOLON {
		
	}
	| INT VARIABLE ASSIGN INTEGER SEMICOLON {
		fprintf(file, "mov\tDWORD PTR [rbp-4], %d\n", $4);
	}
	| INT VARIABLE ASSIGN Expression SEMICOLON {
		fprintf(file, "mov\tDWORD PTR [rbp-4], %d\n", $4);
	}
	| VARIABLE ASSIGN INTEGER SEMICOLON{
		fprintf(file, "mov\tDWORD PTR [rbp-8], %d\n", $3);
	}
	| VARIABLE ASSIGN Expression SEMICOLON{
		fprintf(file, "mov\tDWORD PTR [rbp-8], %d\n", $3);
	}
	;
Expression:
	INTEGER {
		$$ = $1;
	}
	| Expression PLUS Expression{
		$$ = $1 + $3;

	}
	| Expression MINUS Expression{
		$$ = $1 - $3;
	}
	| Expression TIMES Expression{
		$$ = $1 * $3;
	}
	| Expression DIVIDE Expression{
		$$ = $1 / $3;
	}
	| MINUS Expression %prec NEG{
		$$ = -$2;
	}
	| LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS{
		$$=$2;
	}
   	;
%%

int yyerror() {
	printf("ERROR\n");
}

int main(void) {

	node *symbol = create_list();
	file = fopen("compilado.txt", "r");

	if(file != NULL){
		fclose(file);
		remove("compilado.txt");
	}

	file = fopen("compilado.txt", "a");

	yyparse();

	fclose(file);
}
