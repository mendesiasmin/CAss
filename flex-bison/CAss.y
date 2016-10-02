%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "symbol_table.h"
#include "stack.h"

	extern FILE *yyin;
	FILE *file;
	char *variable;

#define true 1
#define false 0

	node *symbol;
	node* this_symbol;
	stack *scopeOfFunction;

%}

%union
{
		int bool;
    int intValue;
    char *stringValue;
}

%token MAIN RETURN
%token INTEGER
%token <stringValue> VARIABLE
%token INT ASSIGN SEMICOLON END TAB
%token COMPARE BIGGER SMALLER BIGGER_THEN SMALLER_THEN DIFFERENT NOT AND OR
%token IF ELSE ELSE_IF
%token PLUS MINUS TIMES DIVIDE LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_KEY RIGHT_KEY

%left PLUS MINUS
%left TIMES DIVIDE
%left NEG
%right LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_KEY RIGHT_KEY

%type<intValue> Expression INTEGER

%start Input

%%

Input:
	/*    */
	| Input Line{
	}
	;
Line:
	END
	| Assignment END {
	}
	| If_statement END {
	}
	| LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
	}
	| RIGHT_KEY {

		if(!strcmp(scopeOfFunction->next->scope, "global")){
			if(find_symbol(symbol, "return"))
				scopeOfFunction = delete_scope(scopeOfFunction);
			else
				yyerror(4, "return\0");
		}
		else{
			scopeOfFunction = delete_scope(scopeOfFunction);
		}
	}
	| INT MAIN LEFT_PARENTHESIS RIGHT_PARENTHESIS{
		char* variable = (char*)malloc(sizeof(char)*5);
		strcpy(variable, "main");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _FUNCTION, 0);
	}
	| RETURN INTEGER SEMICOLON{
		if(scopeOfFunction->next == NULL ||  !find_symbol(symbol, "main"))
			yyerror(3,"");
		else{
			char* variable = (char*)malloc(sizeof(char)*7);
			strcpy(variable, "return");
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _FUNCTION, $2);
		}
	}
	;

Assignment:
	INT VARIABLE SEMICOLON {
		if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2))) {
			yyerror(1, $2);
		} else {
			fprintf(file ,"%s DQ 0\n", $2);
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _INTEGER, 0);
		}
	}
	| INT VARIABLE ASSIGN Expression SEMICOLON {

		if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2))) {
			yyerror(1, $2);
		} else {
			fprintf(file, "%s DQ %d\n", $2, $4);
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _INTEGER, $4);
		}
	}
	| VARIABLE ASSIGN Expression SEMICOLON {

		this_symbol = take_symbol(symbol, $1);
		if(this_symbol) {
			this_symbol->value = $3;
			fprintf(file, "ADD %s, %d\n", $1, $3);
		} else {
			yyerror(2, $1);
		}
	}
;

Expression:
	INTEGER {
		$$ = $1;
	}
	| VARIABLE{
		this_symbol = take_symbol(symbol, $1);
		if(!this_symbol)
			yyerror(4, $1);
		else
			$$ = this_symbol->value;
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
		$$ = $2;
	}
  ;

If_statement:
	IF LEFT_PARENTHESIS Conditional RIGHT_PARENTHESIS {
		fprintf(file, "if\n");
	}
	| ELSE_IF LEFT_PARENTHESIS Conditional RIGHT_PARENTHESIS{
		fprintf(file, "else if\n");
	}
	| ELSE {
		fprintf(file, "else\n");
	}
Conditional:
	Operandor COMPARE Operandor{
		fprintf(file, "	== ");
	}
	| Operandor DIFFERENT Operandor{
		fprintf(file, "	!= ");
	}
	| Operandor SMALLER_THEN Operandor{
		fprintf(file, "	< ");
	}
	| Operandor BIGGER_THEN Operandor{
		fprintf(file, " > ");
	}
	| Operandor SMALLER Operandor{
		fprintf(file, "	<= ");
	}
	| Operandor BIGGER Operandor{
		fprintf(file, " >= ");
	}
	| Conditional AND Conditional{
		fprintf(file, " AND ");
	}
	| Conditional OR Conditional{
		fprintf(file, " OR	 ");
	}
	| NOT Operandor{
		fprintf(file, " NOT ");
	}
	| NOT LEFT_PARENTHESIS Conditional RIGHT_PARENTHESIS{
		fprintf(file, "NOT Conditional ");
	}
	| LEFT_PARENTHESIS Conditional RIGHT_PARENTHESIS{

	}

Operandor:
	Expression{
	}
	;
%%

int yyerror(int typeError, char* variable) {

	printf("ERROR:\n");

	switch(typeError) {
		case 1:
			printf("Variavel %s ja declarada\n", variable);
			break;
		case 2:
			printf("Variavel %s nao foi declarada\n", variable);
			break;
		case 3:
			printf("Fora de escopo\n");
			break;
		case 4:
			printf("Variavel %s nao foi declarada\n", variable);
			break;
		//default:
			//nothing to do
	}
	exit(0);
}

int main(void) {

	symbol = create_list();
	scopeOfFunction = create_stack();
	scopeOfFunction = insert_scope(scopeOfFunction, "global");

	file = fopen("compilado.txt", "r");

	if(file != NULL){
		fclose(file);
		remove("compilado.txt");
	}

	file = fopen("compilado.txt", "a");

	yyparse();

	fclose(file);
}
