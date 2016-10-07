#ifndef STACK_HEADER
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#endif

typedef struct Stack stack;

struct Stack {
	char *scope;
	stack *next;
};

stack *scopeOfFunction;

/* Creating stack */
stack *create_stack();

/* Verify if stack is empty, return 0 to false, and 1 to true */
int is_empty_stcak(stack* list);

stack* insert_scope(stack *list, char *scope);

char* take_scope(stack *list);

stack* delete_scope(stack* list);

int find_scope(stack* list, char* scope);

char* scopeGenerator();
