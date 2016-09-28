%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "symbol_table.h"

	extern FILE *yyin;
	FILE *file;
	char *variable;

	#define true 1
	#define false 0

	node *symbol;

%}

%union
{
    int intValue;
    char *stringValue;
}


%token INTEGER
%token <stringValue> VARIABLE
%token INT ASSIGN SEMICOLON END
%token COMPARE BIGGER SMALLER BIGGER_THEN SMALLER_THEN
%token IF ELSE
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
		//printf("Resultado: %d\n",$1); 
	}
	;
Assignment:
	INT VARIABLE SEMICOLON {
		if(find_symbol(symbol, $2, "main")) {
			yyerror(1, $2);
		} else {
			fprintf(file ,"%s DQ 0\n", $2);
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, "main");
		}
	}
	| INT VARIABLE ASSIGN INTEGER SEMICOLON {
		if(find_symbol(symbol, $2, "main")) {
			yyerror(1, $2);
		} else {
			fprintf(file, "%s DQ %d\n", $2, $4);
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, "main");
		}
	}
	| INT VARIABLE ASSIGN Expression SEMICOLON {
		if(find_symbol(symbol, $2, "main")) {
			yyerror(1, $2);
		} else {
			fprintf(file, "%s DQ %d\n", $2, $4);
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, "main");
		}
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
	| LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS {
		$$=$2;
	}
   	;
/*If_statement:
	IF LEFT_PARENTHESIS Conditional RIGHT_PARENTHESIS{

	}
Conditional:
	INTEGER {
		
	}
	| INTEGER COMPARE INTEGER{
		fprintf(file, "==\n");
	}*/
%%

int yyerror(int typeError, char* variable) {

	printf("ERROR:\n");

	switch(typeError) {
		case 1:
			printf("Variavel %s ja declarada\n", variable);
			break;
		//default:
			//nothing to do
	}
	exit(0);
}

int main(void) {


	symbol = create_list();

	file = fopen("compilado.txt", "r");

	if(file != NULL){
		fclose(file);
		remove("compilado.txt");
	}

	file = fopen("compilado.txt", "a");

	yyparse();

	fclose(file);
}
