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
	char *compare[4];
	//node *symbol;
	node* this_symbol;
	node* this_variable;
	node* this_variable2;
	//stack *scopeOfFunction;
	int word = 4;
	int flag_if = 0;
	int flag_if_position = 0;
	int flag_switch;
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
%type <stringValue> VARIABLE Conditional

%token MAIN RETURN
%token INTEGER  VARIABLE
%token INT ASSIGN SEMICOLON END TAB
%token COMPARE BIGGER SMALLER BIGGER_THEN SMALLER_THEN DIFFERENT NOT AND OR
%token IF ELSE ELSE_IF SWITCH BREAK CASE COLON DEFAULT
%token FOR WHILE DO
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
 	Assignment SEMICOLON {
	}
	| If_statement {
	}
	| For_statement END {
	}
	| Switch_statement {
	}
	| LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
	}
	| RIGHT_KEY {
		//(symbol);
		if(!strcmp(scopeOfFunction->next->scope, "global")){
			if(find_symbol(symbol, "return")){
				scopeOfFunction = delete_scope(scopeOfFunction);
			}
			else
				yyerror(2, "return\0");
		}
		else if(take_last(symbol, _IF) != NULL){
			this_symbol = take_last(symbol, _IF);
			fprintf(file, ".L%d:\n", l-1);
			symbol = delete_symbol(symbol, this_symbol);
			scopeOfFunction = delete_scope(scopeOfFunction);
		}
		else if(take_last(symbol, _SWITCH) != NULL){
			this_symbol = take_last(symbol, _SWITCH);
			fprintf(file, ".L%d:\n", l);
			symbol = delete_symbol(symbol, this_symbol);
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
		fprintf(file, ".LFB0:\n");
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
			fprintf(file, "\n.LFE0:\n.Letext0:\n.Ldebug_info0:\n.Ldebug_abbrev0:\n.Ldebug_line0:\n.LASF1:\n.LASF2:\n.LASF0:\n");
		}
	}
	;
Assignment:
	INT VARIABLE {
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
	| INT VARIABLE ASSIGN Expression {

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
	| VARIABLE ASSIGN Expression {
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
	| Expression PLUS Expression{
		$$ = $1 + $3;
	}
	| VARIABLE PLUS Expression{
		this_symbol = take_symbol(symbol, $1);
		if(!this_symbol) yyerror(2, $1);
		else $$ = this_symbol->value + $3;
	}
	| Expression PLUS VARIABLE{
		this_symbol = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $3);
		else $$ = $1 + this_symbol->value;
	}
	| VARIABLE PLUS VARIABLE{
		this_symbol = take_symbol(symbol, $1);
		this_variable = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $1);
		else if(!this_variable) yyerror(2, $3);
		else $$ = this_symbol->value + this_variable->value;
	}
	| Expression MINUS Expression{
		$$ = $1 - $3;
	}
	| VARIABLE MINUS Expression{
		this_symbol = take_symbol(symbol, $1);
		if(!this_symbol) yyerror(2, $1);
		else $$ = this_symbol->value - $3;
	}
	| Expression MINUS VARIABLE{
		this_symbol = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $3);
		else $$ = $1 - this_symbol->value;
	}
	| VARIABLE MINUS VARIABLE{
		this_symbol = take_symbol(symbol, $1);
		this_variable = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $1);
		else if(!this_variable) yyerror(2, $3);
		else $$ = this_symbol->value - this_variable->value;
	}
	| Expression TIMES Expression{
		$$ = $1 * $3;
	}
	| VARIABLE TIMES Expression{
		this_symbol = take_symbol(symbol, $1);
		if(!this_symbol) yyerror(2, $1);
		else $$ = this_symbol->value * $3;
	}
	| Expression TIMES VARIABLE{
		this_symbol = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $3);
		else $$ = $1 * this_symbol->value;
	}
	| VARIABLE TIMES VARIABLE{
		this_symbol = take_symbol(symbol, $1);
		this_variable = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $1);
		else if(!this_variable) yyerror(2, $3);
		else $$ = this_symbol->value * this_variable->value;
	}
	| Expression DIVIDE Expression{
		$$ = $1 / $3;
	}
	| VARIABLE DIVIDE Expression{
		this_symbol = take_symbol(symbol, $1);
		if(!this_symbol) yyerror(2, $1);
		else $$ = this_symbol->value / $3;
	}
	| Expression DIVIDE VARIABLE{
		this_symbol = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $3);
		else $$ = $1 / this_symbol->value;
	}
	| VARIABLE DIVIDE VARIABLE{
		this_symbol = take_symbol(symbol, $1);
		this_variable = take_symbol(symbol, $3);
		if(!this_symbol) yyerror(2, $1);
		else if(!this_variable) yyerror(2, $3);
		else $$ = this_symbol->value / this_variable->value;
	}
	|  MINUS Expression %prec NEG{
		$$ = -$2;
	}
	|  MINUS VARIABLE %prec NEG{
		this_symbol = take_symbol(symbol, $2);
		if(!this_symbol) yyerror(2, $2);
		else $$ = -this_symbol->value;
	}

	| LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS {
		$$ = $2;
	}
  ;

If_statement:
	IF Conditional {
		symbol = insert_symbol(symbol, "IF\0", scopeOfFunction->scope, _IF, l, 0);
		switch (*compare[3]) {
			case '0':
				fprintf(file, "\ncmp\t%s, %s\n", compare[0], compare[1]);
				break;
			case '1':
				fprintf(file, "\ncmp\tDWORD PTR [rbp-%s], %s\n", compare[0], compare[1]);
				break;
			case '2':
				fprintf(file, "\ncmp\t%s, DWORD PTR [rbp-%s]\n", compare[0], compare[1]);
				break;
			case '3':
				fprintf(file, "\nmov eax, DWORD PTR [rbp-%s]\n", compare[0]);
				fprintf(file, "cmp\teax, DWORD PTR [rbp-%s]\n", compare[1]);
				break;
		}
		fprintf(file, "%s\t.L%d\n", compare[2], l);
		l++;
	}
	| RIGHT_KEY ELSE LEFT_KEY{
		fprintf(file, "jmp\t.L%d\n", l);
		fprintf(file, ".L%d:\n\n", l-1);
		l++;
	}
	| RIGHT_KEY ELSE_IF Conditional LEFT_KEY{
		fprintf(file, "jmp\t.L%d\n", l);
		fprintf(file, ".L%d:\n", l-1);
		switch (*compare[3]) {
			case '0':
				fprintf(file, "\ncmp\t%s, %s\n", compare[0], compare[1]);
				break;
			case '1':
				fprintf(file, "\ncmp\tDWORD PTR [rbp-%s], %s\n", compare[0], compare[1]);
				break;
			case '2':
				fprintf(file, "\ncmp\t%s, DWORD PTR [rbp-%s]\n", compare[0], compare[1]);
				break;
			case '3':
				fprintf(file, "\nmov eax, DWORD PTR [rbp-%s]\n", compare[0]);
				fprintf(file, "cmp\teax, DWORD PTR [rbp-%s]\n", compare[1]);
				break;
		}
		fprintf(file, "%s\t.L%d\n", compare[2], l);
		l++;
	}
	;

For_statement:
	FOR LEFT_PARENTHESIS Assignment {
	  actual_label = l++;
		fprintf(file, "\n.L%d:", actual_label);
	}
	| Conditional SEMICOLON Assignment RIGHT_PARENTHESIS LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
		this_symbol = take_last(symbol, _IF);
		l++;
		fprintf(file, "jump\t.L%d\n\n", actual_label);
	}
	;

Switch_statement:
	SWITCH LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS {
		symbol = insert_symbol(symbol, "", scopeOfFunction->scope, _SWITCH, l, 0);
		fprintf(file, "\nmov eax, %d", $3);
		flag_switch = 0;
	}
	| SWITCH LEFT_PARENTHESIS VARIABLE RIGHT_PARENTHESIS {
		symbol = insert_symbol(symbol, "", scopeOfFunction->scope, _SWITCH, l, 0);
		fprintf(file, "\nmov eax, DWORD PTR [rbp-%d]", take_symbol(symbol, $3)->word);
		flag_switch = 0;
	}
	| CASE Expression COLON {
		if(flag_switch){
			fprintf(file, "jmp\t.L%d\n", ++l);
			fprintf(file, ".L%d:\n", l-1);
		}
		else {
			flag_switch = 1;
		}
		fprintf(file, "\ncmp\teax, %d\n", $2);
		fprintf(file, "jne\t.L%d\n", l);
	}
	| CASE VARIABLE COLON {
		if(flag_switch){
			fprintf(file, "jmp\t.L%d\n", ++l);
			fprintf(file, ".L%d:\n", l-1);
		}
		else {
			flag_switch = 1;
		}
		fprintf(file, "\ncmp\teax, DWORD PTR [rbp-%d]\n", take_symbol(symbol, $2)->word);
		fprintf(file, "jne\t.L%d\n", l);
	}
	| DEFAULT COLON {
		fprintf(file, "jmp\t.L%d\n", ++l);
		fprintf(file, ".L%d:\n\n", l-1);
	}
	| BREAK SEMICOLON{ /*Nothing do */ }
	;

Conditional:
	Expression COMPARE Expression{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jne");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '0';
	}
	| VARIABLE COMPARE Expression{
		compare[0] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jne");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '1';
	}
	| Expression COMPARE VARIABLE{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jne");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '2';
	}
	| VARIABLE COMPARE VARIABLE {
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jne");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '3';
	}
	| Expression DIFFERENT Expression{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "je");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '0';
	}
	| VARIABLE DIFFERENT Expression{
		compare[0] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "je");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '1';
	}
	| Expression DIFFERENT VARIABLE{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "je");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '2';
	}
	| VARIABLE DIFFERENT VARIABLE {
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "je");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '3';
	}
	| Expression SMALLER_THEN Expression{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jg");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '0';
	}
	| VARIABLE SMALLER_THEN Expression{
		compare[0] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jg");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '1';
	}
	| Expression SMALLER_THEN VARIABLE{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jg");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '2';
	}
	| VARIABLE SMALLER_THEN VARIABLE {
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jg");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '3';
	}
	| Expression BIGGER_THEN Expression{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jle");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '0';
	}
	| VARIABLE BIGGER_THEN Expression{
		compare[0] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[1], 20, "%d", $3);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jle");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '1';
	}
	| Expression BIGGER_THEN VARIABLE{
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", $1);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jle");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '2';
	}
	| VARIABLE BIGGER_THEN VARIABLE {
		compare[0] = (char*)malloc(sizeof(char)*20);
		snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
		compare[1] = (char*)malloc(sizeof(char)*10);
		snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
		compare[2] = (char*)malloc(sizeof(char)*4);
		strcpy(compare[2], "jle");
		compare[3] = (char*)malloc(sizeof(char));
		*compare[3] = '3';
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
	fprintf(file, ".Ltext0:\n\n");

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
