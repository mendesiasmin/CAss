#ifndef SYMBOL_TABLE_HEADER
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#endif
typedef struct Node node;

struct Node {

	char *symbol;
	char *scope;
	node *next;
};
/* Creating list */
node *create_list();
/* Verify if list is empty, return 0 to false, and 1 to true */
int is_empty(node *list);
/* Insert a variable name in list */
void insert_symbol(node *list, char *symbol, node *new_node);
/* Search the variable name in the same scope */
int find_symbol(node *list, char *symbol, char *scope);
