#ifndef STACK_HEADER
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#endif

typedef struct Node node;

struct Node {
	char *scope;
	node *next;
};

/* Creating stack */
node *create_stack();
/* Verify if stack is empty, return 0 to false, and 1 to true */

node* insert_scope(node *list, char *scope);

char* take_scope(node *list);

node* delete_scope(node* list);
