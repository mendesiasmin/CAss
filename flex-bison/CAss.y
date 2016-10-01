%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "symbol_table.h"
#include "stack.h"

	extern FILE *yyin;
	FILE *file;
	char *variable;
	int numberScope = 0;

#define true 1
#define false 0

	node *symbol;
	stack *scopeOfFunction;

char* scopeGenerator() {

	char *validchars = "abcdefghijklmnopqrstuvwxiz";
	char *novastr;

	int str_len;

	// tamanho da string
	str_len = 10 + (rand() % 10);

	// aloca memoria
	novastr = (char*)malloc((str_len + 1)* sizeof(char));
	
	int i;

	for ( i = 0; i < str_len; i++ ) {
		novastr[i] = validchars[ rand() % strlen(validchars) ];
		novastr[i + 1] = 0x0;
	}

	printf("string gerada %s \n", novastr);

	return novastr;
}

%}

%union
{
		int bool;
    int intValue;
    char *stringValue;
}

%token INTEGER
%token <stringValue> VARIABLE
%token INT ASSIGN SEMICOLON END
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
	| Input Line
	;
Line:
	END
	| Assignment END {
		//printf("Resultado: %d\n",$1);
	}
	| If_statement END {
	}
	| LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
		printf("Scopo disso tudo adicionado %s\n", scopeOfFunction->scope);
	}
	| RIGHT_KEY {
		printf("Scopo disso tudo deletado %s\n", scopeOfFunction->scope);
		scopeOfFunction = delete_scope(scopeOfFunction);
	}
	;
Assignment:
	INT VARIABLE SEMICOLON {
		printf("Scopo dessa budega %s\n", scopeOfFunction->scope);

		if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2))) {
			yyerror(1, $2);
		} else {
			fprintf(file ,"%s DQ 0\n", $2);
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope);
		}
	}
	| INT VARIABLE ASSIGN Expression SEMICOLON {
		printf("Scopo dessa budega %s\n", scopeOfFunction->scope);

		if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2))) {
			yyerror(1, $2);
		} else {
			fprintf(file, "%s DQ %d\n", $2, $4);
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope);
		}
	}
	| VARIABLE ASSIGN Expression SEMICOLON {
		printf("Scopo dessa budega %s\n", scopeOfFunction->scope);

		if(find_symbol(symbol, $1) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $1))) {
			fprintf(file, "ADD %s, %d\n", $1, $3);
		} else {
			yyerror(2, $1);
		}
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
	VARIABLE{
	}
	| Expression{
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
