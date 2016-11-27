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
	node* this_symbol;
	node* this_variable;
	node* this_variable2;
	int word = 4;
	int flag_if = 0;
	int flag_if_position = 0;
	int flag_switch;
	int l = 2;
	int n = 0;
	int funcao = 0;
	int comment = false;

%}

%union
{
	char *stringValue;
	int intValue;
	int bool;
}

%type <intValue> Expression INTEGER
%type <stringValue> VARIABLE Conditional

%token RETURN
%token INTEGER  VARIABLE
%token INT ASSIGN SEMICOLON END TAB
%token COMPARE BIGGER SMALLER BIGGER_THEN SMALLER_THEN DIFFERENT NOT AND OR
%token IF ELSE ELSE_IF SWITCH BREAK CASE COLON DEFAULT
%token FOR WHILE DO
%token PLUS MINUS TIMES DIVIDE LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_KEY RIGHT_KEY
%token INITIAL_COMMENT END_COMMENT

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
	| For_statement {
	}
	| Switch_statement {
	}
	| While_statement {
	}
	| LEFT_KEY {
		scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
	}
	| RIGHT_KEY {
		scopeOfFunction = delete_scope(scopeOfFunction);
		if(!strcmp(scopeOfFunction->scope, "global")){
			if(!find_symbol(symbol, "return"))
				yyerror(2, "return\0");
		}
		else if(take_last(symbol, _IF) != NULL && take_last(symbol, _IF)->scope == scopeOfFunction->scope){
			this_symbol = take_last(symbol, _IF);
			fprintf(file, ".L%d:\n", this_symbol->word);
			symbol = delete_symbol(symbol, this_symbol);
		}
		else if(take_last(symbol, _SWITCH) != NULL && take_last(symbol, _SWITCH)->scope == scopeOfFunction->scope){
			this_symbol = take_last(symbol, _SWITCH);
			fprintf(file, ".L%d:\n", this_symbol->word);
			symbol = delete_symbol(symbol, this_symbol);
		}
		else if(take_last(symbol, _WHILE) && take_last(symbol, _WHILE)->scope == scopeOfFunction->scope){
			this_symbol = take_last(symbol, _WHILE);
			fprintf(file, "jmp .L%d\n", this_symbol->word);
			fprintf(file, ".L%d:\n", this_symbol->word-1);
			symbol = delete_symbol(symbol, this_symbol);
		}
		else if(take_last(symbol, _FOR) && take_last(symbol, _FOR)->scope == scopeOfFunction->scope){
			this_symbol = take_last(symbol, _FOR);
			fprintf(file, "jmp .L%d\n", this_symbol->word);
			fprintf(file, ".L%d:\n", this_symbol->word-1);
			symbol = delete_symbol(symbol, this_symbol);
		}
		else if(!(take_last(symbol, _RETURN) && take_last(symbol, _RETURN)->scope == scopeOfFunction->scope)){
			yyerror(2, "return\0");
		}
	}
	| INT VARIABLE LEFT_PARENTHESIS RIGHT_PARENTHESIS {
		char* variable = (char*)malloc(sizeof(char)*5);
		strcpy(variable, $2);
		symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _FUNCTION, 0, 0);
		fprintf(file, "%s:\n", $2);
		fprintf(file, ".LFB%d:\n", funcao);
		fprintf(file, "push	rbp\n");
		fprintf(file, "mov		rbp, rsp\n\n");
	}
	| RETURN INTEGER SEMICOLON RIGHT_KEY{
		if(scopeOfFunction->next == NULL ||  !find_symbol(symbol, "main"))
			yyerror(3,"");
		else{
			char* variable = (char*)malloc(sizeof(char)*7);
			strcpy(variable, "return");
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _FUNCTION, 0, $2);
			fprintf(file, "\nmov		eax, %d\n", $2);
			fprintf(file, "pop		rbp\n");
			fprintf(file, "ret\n");
			fprintf(file, "\n.LFE%d:\n.Letext%d:\n.Ldebug_info%d:\n.Ldebug_abbrev%d:\n.Ldebug_line%d:\n.LASF1:\n.LASF2:\n.LASF0:\n\n", funcao, funcao, funcao, funcao, funcao);
			funcao++;
		}
	}
	| RETURN VARIABLE SEMICOLON RIGHT_KEY{
		if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2, scopeOfFunction->scope), scopeOfFunction->scope)) {
			char* variable = (char*)malloc(sizeof(char)*7);
			strcpy(variable, "return");
			symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _FUNCTION, 0, $2);
			this_symbol = take_symbol(symbol, $2);
			fprintf(file, "\nmov		eax, %d\n", this_symbol->value);
			fprintf(file, "pop		rbp\n");
			fprintf(file, "ret\n");
			fprintf(file, "\n.LFE%d:\n.Letext%d:\n.Ldebug_info%d:\n.Ldebug_abbrev%d:\n.Ldebug_line%d:\n.LASF1:\n.LASF2:\n.LASF0:\n\n", funcao, funcao, funcao, funcao, funcao);
			funcao++;
		} else {
			yyerror(2, $2);
		}
	}
	| INITIAL_COMMENT {
		comment = true;
	} Input END_COMMENT {
		comment = false;
	}
	;

Assignment:
	INT VARIABLE {
		if(!comment){
			if(find_symbol(symbol, $2) &&
				find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2, scopeOfFunction->scope), scopeOfFunction->scope)) {
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
	}
	| INT VARIABLE ASSIGN Expression {
		if(!comment) {
			if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2, scopeOfFunction->scope), scopeOfFunction->scope)) {
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
	}
	| INT VARIABLE ASSIGN VARIABLE {
		if(!comment) {
			if(find_symbol(symbol, $2) && find_scope(scopeOfFunction, take_scope_of_symbol(symbol, $2, scopeOfFunction->scope), scopeOfFunction->scope)) {
				yyerror(1, $2);
			} else {
				char* variable = (char*)malloc(sizeof(strlen($2)));
				strcpy(variable, $2);
				this_variable2 = take_symbol(symbol, $4);
				if(this_variable2) {
					symbol = insert_symbol(symbol, variable, scopeOfFunction->scope, _INTEGER, word, this_variable2->value);
					word += 4;
					fprintf(file ,"mov DWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_symbol->word, this_variable2->word);
				}
			}
		}
	}
	| VARIABLE ASSIGN Expression {
			if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			if(this_symbol) {
				this_symbol->value = $3;
				fprintf(file ,"mov DWORD PTR [rbp-%d], %d\n", this_symbol->word, this_symbol->value);
			} else {
				yyerror(2, $1);
			}
		}
	}
	| VARIABLE ASSIGN VARIABLE {
		if(!comment) {
			this_variable = take_symbol(symbol, $1);
			this_variable2 = take_symbol(symbol, $3);
			if(this_variable) {
				if(this_variable2) {
					this_variable->value = this_variable2->value;
					fprintf(file ,"mov DWORD PTR [rbp-%d], DWORD PTR [rbp-%d]\n", this_variable->word, this_variable2->word);
				}
				else {
					yyerror(2, $3);
				}
			} else {
				yyerror(2, $1);
			}
		}
	}
	| VARIABLE PLUS PLUS {
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			if(this_symbol) {
				this_symbol->value = this_symbol->value + 1;
				fprintf(file ,"add DWORD PTR [rbp-%d], 1\n", this_symbol->word);
			} else {
				yyerror(2, $1);
			}
		}
	}
	| PLUS PLUS VARIABLE {
		if(!comment) {
			this_symbol = take_symbol(symbol, $3);
			if(this_symbol) {
				this_symbol->value = this_symbol->value + 1;
				fprintf(file ,"add DWORD PTR [rbp-%d], 1\n", this_symbol->word);
			} else {
				yyerror(2, $3);
			}
		}
	}
	| VARIABLE MINUS MINUS {
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			if(this_symbol) {
				this_symbol->value = this_symbol->value - 1;
				fprintf(file ,"sub DWORD PTR [rbp-%d], 1\n", this_symbol->word);
			} else {
				yyerror(2, $1);
			}
		}
	}
	| MINUS MINUS VARIABLE {
		if(!comment) {
			this_symbol = take_symbol(symbol, $3);
			if(this_symbol) {
				this_symbol->value = this_symbol->value - 1;
				fprintf(file ,"sub DWORD PTR [rbp-%d], 1\n", this_symbol->word);
			} else {
				yyerror(2, $3);
			}
		}
	}
	;

Expression:
	INTEGER {
		if(!comment) {
			$$ = $1;
		}
	}
	| Expression PLUS Expression{
		if(!comment) {
			$$ = $1 + $3;
		}
	}
	| VARIABLE PLUS Expression{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			if(!this_symbol) yyerror(2, $1);
			else $$ = this_symbol->value + $3;
		}
	}
	| Expression PLUS VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $3);
			else $$ = $1 + this_symbol->value;
		}
	}
	| VARIABLE PLUS VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			this_variable = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $1);
			else if(!this_variable) yyerror(2, $3);
			else $$ = this_symbol->value + this_variable->value;
		}
	}
	| Expression MINUS Expression{
		if(!comment) {
			$$ = $1 - $3;
		}
	}
	| VARIABLE MINUS Expression{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			if(!this_symbol) yyerror(2, $1);
			else $$ = this_symbol->value - $3;
		}
	}
	| Expression MINUS VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $3);
			else $$ = $1 - this_symbol->value;
		}
	}
	| VARIABLE MINUS VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			this_variable = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $1);
			else if(!this_variable) yyerror(2, $3);
			else $$ = this_symbol->value - this_variable->value;
		}
	}
	| Expression TIMES Expression{
		if(!comment) {
			$$ = $1 * $3;
		}
	}
	| VARIABLE TIMES Expression{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			if(!this_symbol) yyerror(2, $1);
			else $$ = this_symbol->value * $3;
		}
	}
	| Expression TIMES VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $3);
			else $$ = $1 * this_symbol->value;
		}
	}
	| VARIABLE TIMES VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			this_variable = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $1);
			else if(!this_variable) yyerror(2, $3);
			else $$ = this_symbol->value * this_variable->value;
		}
	}
	| Expression DIVIDE Expression{
		if(!comment) {
			$$ = $1 / $3;
		}
	}
	| VARIABLE DIVIDE Expression{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			if(!this_symbol) yyerror(2, $1);
			else $$ = this_symbol->value / $3;
		}
	}
	| Expression DIVIDE VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $3);
			else $$ = $1 / this_symbol->value;
		}
	}
	| VARIABLE DIVIDE VARIABLE{
		if(!comment) {
			this_symbol = take_symbol(symbol, $1);
			this_variable = take_symbol(symbol, $3);
			if(!this_symbol) yyerror(2, $1);
			else if(!this_variable) yyerror(2, $3);
			else $$ = this_symbol->value / this_variable->value;
		}
	}
	|  MINUS Expression %prec NEG{
		if(!comment) {
			$$ = -$2;
		}
	}
	|  MINUS VARIABLE %prec NEG{
		if(!comment) {
			this_symbol = take_symbol(symbol, $2);
			if(!this_symbol) yyerror(2, $2);
			else $$ = -this_symbol->value;
		}
	}

	| LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS {
		if(!comment) {
			$$ = $2;
		}
	}
  ;

If_statement:
	IF Conditional {
		if(!comment) {
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
	}
	| RIGHT_KEY ELSE LEFT_KEY{
		if(!comment) {
			this_symbol = take_last(symbol, _IF);
			fprintf(file, "jmp\t.L%d\n", l);
			fprintf(file, ".L%d:\n\n", this_symbol->word);
			this_symbol->word = l;
			l++;
		}
	}
	| RIGHT_KEY ELSE_IF Conditional LEFT_KEY{
		if(!comment) {
			this_symbol = take_last(symbol, _IF);
			fprintf(file, "jmp\t.L%d\n", l);
			fprintf(file, ".L%d:\n", this_symbol->word);
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
			this_symbol->word = l;
			l++;
		}
	}
	;

For_statement:
	FOR LEFT_PARENTHESIS Assignment SEMICOLON	Conditional SEMICOLON {
		if(!comment) {
			symbol = insert_symbol(symbol, "FOR", scopeOfFunction->scope, _FOR, ++l, 0);
			fprintf(file, "\n.L%d:\n", l);
			switch (*compare[3]) {
				case '0':
					fprintf(file, "cmp\t%s, %s\n", compare[0], compare[1]);
					break;
				case '1':
					fprintf(file, "cmp\tDWORD PTR [rbp-%s], %s\n", compare[0], compare[1]);
					break;
				case '2':
					fprintf(file, "cmp\t%s, DWORD PTR [rbp-%s]\n", compare[0], compare[1]);
					break;
				case '3':
					fprintf(file, "mov eax, DWORD PTR [rbp-%s]\n", compare[0]);
					fprintf(file, "cmp\teax, DWORD PTR [rbp-%s]\n", compare[1]);
					break;
			}
			fprintf(file, "%s\t.L%d\n", compare[2], l-1);
			l++;
		}
	} Assignment RIGHT_PARENTHESIS{
		/*Nothing Do*/
	}
	;

While_statement:
	DO LEFT_KEY {
		if(!comment) {
			symbol = insert_symbol(symbol, "DO", scopeOfFunction->scope, _WHILE, l++, 0);
			scopeOfFunction = insert_scope(scopeOfFunction, scopeGenerator());
			fprintf(file, "\n.L%d:\n", l-1);
		}
	}
	Input RIGHT_KEY WHILE Conditional SEMICOLON {
		if(!comment) {
			this_symbol = take_last(symbol, _WHILE);
			switch (*compare[3]) {
				case '0':
					fprintf(file, "cmp\t%s, %s\n", compare[0], compare[1]);
					break;
				case '1':
					fprintf(file, "cmp\tDWORD PTR [rbp-%s], %s\n", compare[0], compare[1]);
					break;
				case '2':
					fprintf(file, "cmp\t%s, DWORD PTR [rbp-%s]\n", compare[0], compare[1]);
					break;
				case '3':
					fprintf(file, "mov eax, DWORD PTR [rbp-%s]\n", compare[0]);
					fprintf(file, "cmp\teax, DWORD PTR [rbp-%s]\n", compare[1]);
					break;
			}
			fprintf(file, "%s\t.L%d\n", compare[2], l);
			fprintf(file, "jmp .L%d\n", this_symbol->word);
			fprintf(file, ".L%d:\n", l++);
			symbol = delete_symbol(symbol, this_symbol);
			scopeOfFunction = delete_scope(scopeOfFunction);
		}
	}
	| WHILE Conditional {
		if(!comment) {
			symbol = insert_symbol(symbol, "WHILE", scopeOfFunction->scope, _WHILE, ++l, 0);
			fprintf(file, "\n.L%d:\n", l);
			switch (*compare[3]) {
				case '0':
					fprintf(file, "cmp\t%s, %s\n", compare[0], compare[1]);
					break;
				case '1':
					fprintf(file, "cmp\tDWORD PTR [rbp-%s], %s\n", compare[0], compare[1]);
					break;
				case '2':
					fprintf(file, "cmp\t%s, DWORD PTR [rbp-%s]\n", compare[0], compare[1]);
					break;
				case '3':
					fprintf(file, "mov eax, DWORD PTR [rbp-%s]\n", compare[0]);
					fprintf(file, "cmp\teax, DWORD PTR [rbp-%s]\n", compare[1]);
					break;
			}
			fprintf(file, "%s\t.L%d\n", compare[2], l-1);
			l++;
		}
	}
	;

Switch_statement:
	SWITCH LEFT_PARENTHESIS Expression RIGHT_PARENTHESIS {
		if(!comment) {
			symbol = insert_symbol(symbol, "SWITCH", scopeOfFunction->scope, _SWITCH, l, 0);
			fprintf(file, "\nmov eax, %d", $3);
			flag_switch = 0;
		}
	}
	| SWITCH LEFT_PARENTHESIS VARIABLE RIGHT_PARENTHESIS {
		if(!comment) {
			symbol = insert_symbol(symbol, "SWITCH", scopeOfFunction->scope, _SWITCH, l, 0);
			fprintf(file, "\nmov eax, DWORD PTR [rbp-%d]", take_symbol(symbol, $3)->word);
			flag_switch = 0;
		}
	}
	| CASE Expression COLON {
		if(!comment) {
			this_symbol = take_last(symbol, _SWITCH);
			if(flag_switch){
				fprintf(file, "jmp\t.L%d\n", l);
				fprintf(file, ".L%d:\n", this_symbol->word);
			}
			else {
				flag_switch = 1;
			}
			fprintf(file, "\ncmp\teax, %d\n", $2);
			fprintf(file, "jne\t.L%d\n", l);
			this_symbol->word = l;
			l++;
		}
	}
	| CASE VARIABLE COLON {
		if(!comment) {
			this_symbol = take_last(symbol, _SWITCH);
			if(flag_switch){
				fprintf(file, "jmp\t.L%d\n", l);
				fprintf(file, ".L%d:\n", this_symbol->word);
			}
			else {
				flag_switch = 1;
			}
			fprintf(file, "\ncmp\teax, DWORD PTR [rbp-%d]\n", take_symbol(symbol, $2)->word);
			fprintf(file, "jne\t.L%d\n", l);
			this_symbol->word = l;
			l++;
		}
	}
	| DEFAULT COLON {
		if(!comment) {
			this_symbol = take_last(symbol, _SWITCH);
			fprintf(file, "jmp\t.L%d\n", l);
			fprintf(file, ".L%d:\n\n", this_symbol->word);
			this_symbol->word = l;
			l++;
		}
	} Input {
		//Imprimir o que tem dentro do default
	}
	| BREAK SEMICOLON{ /*Nothing do */ }
	;

Conditional:
	Expression COMPARE Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jne");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '0';
		}
	}
	| VARIABLE COMPARE Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jne");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '1';
		}
	}
	| Expression COMPARE VARIABLE{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jne");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '2';
		}
	}
	| VARIABLE COMPARE VARIABLE {
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jne");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '3';
		}
	}
	| Expression DIFFERENT Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "je");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '0';
		}
	}
	| VARIABLE DIFFERENT Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "je");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '1';
		}
	}
	| Expression DIFFERENT VARIABLE{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "je");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '2';
		}
	}
	| VARIABLE DIFFERENT VARIABLE {
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "je");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '3';
		}
	}
	| Expression SMALLER_THEN Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jg");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '0';
		}
	}
	| VARIABLE SMALLER_THEN Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jg");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '1';
		}
	}
	| Expression SMALLER_THEN VARIABLE{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jg");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '2';
		}
	}
	| VARIABLE SMALLER_THEN VARIABLE {
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jg");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '3';
		}
	}
	| Expression BIGGER_THEN Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jle");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '0';
		}
	}
	| VARIABLE BIGGER_THEN Expression{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[1], 20, "%d", $3);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jle");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '1';
		}
	}
	| Expression BIGGER_THEN VARIABLE{
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", $1);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jle");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '2';
		}
	}
	| VARIABLE BIGGER_THEN VARIABLE {
		if(!comment) {
			compare[0] = (char*)malloc(sizeof(char)*20);
			snprintf(compare[0], 20, "%d", take_symbol(symbol, $1)->word);
			compare[1] = (char*)malloc(sizeof(char)*10);
			snprintf(compare[1], 20, "%d", take_symbol(symbol, $3)->word);
			compare[2] = (char*)malloc(sizeof(char)*4);
			strcpy(compare[2], "jle");
			compare[3] = (char*)malloc(sizeof(char));
			*compare[3] = '3';
		}
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
		case 4:
			printf("Condicao invalida no laco do/while\n");
			break;
		case 5:
			printf("Função deveria retornar um inteiro\n");
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