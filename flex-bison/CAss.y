%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <ctype.h>
#include "symbol_table.h"
#include "stack.h"

#define true 1
#define false 0

	extern FILE *yyin;
	FILE *file;
	char *variable;
	node *symbol;
	node* this_symbol;
	node* this_variable;
	node* this_variable2;
	stack *scopeOfFunction;
	int word = 4;
	int flag = true;
	int l = 2;
	int actual_label = 0;

%}

%union
{
	char *stringValue;
    int intValue;
    int bool;
}

%type <intValue> Expression INTEGER
%type <stringValue> VARIABLE

%token MAIN RETURN
%token INTEGER  VARIABLE
%token INT ASSIGN SEMICOLON END TAB
%token COMPARE BIGGER SMALLER BIGGER_THEN SMALLER_THEN DIFFERENT NOT AND OR
%token IF ELSE ELSE_IF FOR
%token PLUS MINUS TIMES DIVIDE LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_KEY RIGHT_KEY

%left PLUS MINUS
%left TIMES DIVIDE
%left NEG
%right LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_KEY RIGHT_KEY

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
	| For_statement END {
	}
	| LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
	}
	| RIGHT_KEY {
		if(!strcmp(scopeOfFunction->next->scope, "global")){
			if(find_symbol(symbol, "return")){
				scopeOfFunction = delete_scope(scopeOfFunction);
			}
			else
				yyerror(2, "return\0");
		}
		else if(take_last_if(symbol) != NULL){
			this_symbol = take_last_if(symbol);
			fprintf(file, ".L%d:\n", this_symbol->word);
			scopeOfFunction = delete_scope(scopeOfFunction);
		}
		else{
			scopeOfFunction = delete_scope(scopeOfFunction);
		}
	}
	| INT MAIN LEFT_PARENTHESIS RIGHT_PARENTHESIS{
		char* variable = (char*)malloc(sizeof(char)*5);
		strcpy(variable, "main");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _FUNCTION, 0, 0);
		fprintf(file, "main:\n");
		fprintf(file, "push	rbp\n");
		fprintf(file, "mov		rbp, rsp\n\n");
	}
	| RETURN INTEGER SEMICOLON{
		if(scopeOfFunction->next == NULL ||  !find_symbol(symbol, "main"))
			yyerror(3,"");
		else{
			char* variable = (char*)malloc(sizeof(char)*7);
			strcpy(variable, "return");
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _FUNCTION, 0, $2);
			fprintf(file, "\nmov		eax, %d\n", $2);
			fprintf(file, "pop		rbp\n");
			fprintf(file, "ret\n");
		}
	}
	;
Assignment:
	INT VARIABLE SEMICOLON {
		if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2))) {
			yyerror(1, $2);
		} else {
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _INTEGER, word, 0);
			word += 4;
			this_symbol = take_symbol(symbol, variable);
			fprintf(file ,"mov DWORD PTR [rbp-%d], %d\n", this_symbol->word, this_symbol->value);
		}
	}
	| INT VARIABLE ASSIGN Expression SEMICOLON {

		if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2))) {
			yyerror(1, $2);
		} else {
			char* variable = (char*)malloc(sizeof(strlen($2)));
			strcpy(variable, $2);
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _INTEGER, word, $4);
			word += 4;
			this_symbol = take_symbol(symbol, variable);
			fprintf(file ,"mov DWORD PTR [rbp-%d], %d\n", this_symbol->word, this_symbol->value);
		}
	}
	| VARIABLE ASSIGN Expression SEMICOLON {
		this_symbol = take_symbol(symbol, $1);
		if(this_symbol) {
			this_symbol->value = $3;
			fprintf(file ,"mov DWORD PTR [rbp-%d], %d\n", this_symbol->word, this_symbol->value);
		} else {
			yyerror(2, $1);
		}
	}
	| VARIABLE PLUS PLUS {
		this_symbol = take_symbol(symbol, $1);
		if(this_symbol) {
			this_symbol->value = this_symbol->value + 1;
			fprintf(file ,"add DWORD PTR [rbp-%d], 1\n", this_symbol->word);
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
			yyerror(2, $1);
		else{
			if(flag){
				this_variable = this_symbol;
				flag = false;
			}
			else{
				this_variable2 = this_symbol;
				flag = true;
			}
			$$ = this_symbol->value;
		}
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
	IF LEFT_PARENTHESIS Conditional RIGHT_PARENTHESIS LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
		this_symbol = take_last_if(symbol);
		l++;
	}
	| RIGHT_KEY ELSE LEFT_KEY{
		this_symbol = take_last_if(symbol);
		fprintf(file, ".L%d:\n\n", l);
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _IF, l, 0);
		l++;
	}
	| RIGHT_KEY ELSE_IF Conditional LEFT_KEY{
		this_symbol = take_last_if(symbol);
		fprintf(file, ".L%d:\n\n", l-1);

	}
	;

For_statement:
	FOR LEFT_PARENTHESIS Assignment {
	  actual_label = l++;
		fprintf(file, "\n.L%d:", actual_label);
	}
	Conditional SEMICOLON Assignment RIGHT_PARENTHESIS LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
		this_symbol = take_last_if(symbol);
		l++;
		fprintf(file, "jump\t.L%d\n\n", actual_label);
	}
Conditional:
	Expression COMPARE Expression{
		variable = (char*)malloc(sizeof(char)*13);
		strcpy(variable, "If_statement");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _IF, l, 0);
		this_symbol = take_last_if(symbol);
		if(this_variable != NULL && this_variable2 != NULL)
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_variable->word, this_variable2->word);
		else if(this_variable != NULL){
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], %d\n", this_variable->word, $3);
		}
		else{
			fprintf(file, "\ncmp %d, %d\n", $1, $3);
		}
		fprintf(file, "jne\t.L%d\n", this_symbol->word);
		this_variable = NULL;
		this_variable2 = NULL;
		flag = true;
	}
	| Expression DIFFERENT Expression{
		variable = (char*)malloc(sizeof(char)*15);
		strcpy(variable, "If_statement\0");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _IF, l, 0);
		this_symbol = take_last_if(symbol);

		if(this_variable != NULL && this_variable2 != NULL)
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_variable->word, this_variable2->word);
		else if(this_variable != NULL){
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], %d\n", this_variable->word, $3);
		}
		else{
			fprintf(file, "\ncmp %d, %d\n", $1, $3);
		}
		fprintf(file, "je\t.L%d\n", this_symbol->word);
		this_variable = NULL;
		this_variable2 = NULL;
		flag = true;
	}
	| Expression SMALLER_THEN Expression{
		variable = (char*)malloc(sizeof(char)*15);
		strcpy(variable, "If_statement\0");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _IF, l, 0);
		this_symbol = take_last_if(symbol);

		if(this_variable != NULL && this_variable2 != NULL)
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_variable->word, this_variable2->word);
		else if(this_variable != NULL){
			f(file, "\ncmp\tDWORD PTR [rbp-%d], %d\n", this_variable->word, $3);
		}
		else{
			fprintf(file, "\ncmp %d, %d\n", $1, $3);
		}
		fprintf(file, "jg\t.L%d\n", this_symbol->word);
		this_variable = NULL;
		this_variable2 = NULL;
		flag = true;
	}
	| Expression BIGGER_THEN Expression{
		variable = (char*)malloc(sizeof(char)*15);
		strcpy(variable, "If_statement\0");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _IF, l, 0);
		this_symbol = take_last_if(symbol);

		if(this_variable != NULL && this_variable2 != NULL)
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_variable->word, this_variable2->word);
		else if(this_variable != NULL){
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], %d\n", this_variable->word, $3);
		}
		else{
			fprintf(file, "\ncmp %d, %d\n", $1, $3);
		}
		fprintf(file, "jle\t.L%d\n", this_symbol->word);
		this_variable = NULL;
		this_variable2 = NULL;
		flag = true;
	}
	| Expression SMALLER Expression{
		variable = (char*)malloc(sizeof(char)*15);
		strcpy(variable, "If_statement\0");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _IF, l, 0);
		this_symbol = take_last_if(symbol);

		if(this_variable != NULL && this_variable2 != NULL)
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_variable->word, this_variable2->word);
		else if(this_variable != NULL){
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], %d\n", this_variable->word, $3);
		}
		else{
			fprintf(file, "\ncmp %d, %d\n", $1, $3);
		}
		fprintf(file, "jg\t.L%d\n", this_symbol->word);
		this_variable = NULL;
		this_variable2 = NULL;
		flag = true;
	}
	| Expression BIGGER Expression{
		variable = (char*)malloc(sizeof(char)*15);
		strcpy(variable, "If_statement\0");
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _IF, l, 0);
		this_symbol = take_last_if(symbol);

		if(this_variable != NULL && this_variable2 != NULL)
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_variable->word, this_variable2->word);
		else if(this_variable != NULL){
			fprintf(file, "\ncmp\tDWORD PTR [rbp-%d], %d\n", this_variable->word, $3);
		}
		else{
			fprintf(file, "\ncmp %d, %d\n", $1, $3);
		}
		fprintf(file, "jle\t.L%d\n", this_symbol->word);
		this_variable = NULL;
		this_variable2 = NULL;
		flag = true;
	}
	| Conditional AND Conditional{

	}
	| Conditional OR Conditional{

	}
	| NOT Conditional {

	}
	| LEFT_PARENTHESIS Conditional RIGHT_PARENTHESIS{

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

	free(file);
	free(variable);
	free(symbol);
	free(this_symbol);
	free(this_variable);
	free(this_variable2);
	free(scopeOfFunction);
}
