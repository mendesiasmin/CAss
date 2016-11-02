#ifndef SYMBOL_TABLE_HEADER
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

//Types
#define _FUNCTION 0
#define _INTEGER 1
#define _IF 2
#define _VARIABLE 3
#define _SWITCH 4

#endif
typedef struct Node node;

struct Node {

	char *symbol;
	char *scope;
	int type;
	int word;
	int value;
	int conditional;
	node *next;
	node *previous;
};

node *symbol;

/* Creating list */
node *create_list();
/* Verify if list is empty, return 0 to false, and 1 to true */
int is_empty(node *list);
/* Insert a variable name in list */
node* insert_symbol(node *list, char *symbol, char *scope, int type, int word, int value);
/* Search the variable name in the same scope */
int find_symbol(node *list, char *symbol);
void imprime(node *list);
char* take_scope_of_symbol(node *list, char *symbol);
node* take_symbol(node *list, char *symbol);
node* take_last(node *list, int type);
node* take_last_symbol(node *list);
node* delete_symbol(node *list, node *delete);
