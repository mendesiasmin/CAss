#ifndef STACK
#include "stack.h"
#define TRUE 1
#define FALSE 0
#endif

stack *create_stack() {
	return NULL;
}

int is_empty_stcak(stack* list) {
	return list == NULL;
}

stack *insert_scope(stack *list, char *scope) {

	stack *new_stack = (stack*) malloc(sizeof(stack));

	new_stack->next = NULL;
	new_stack->scope = (char*)malloc(sizeof(strlen(scope)));

	strcpy(new_stack->scope, scope);

	if(is_empty_stcak(list)) {
		list = new_stack;
	} else {
		new_stack->next = list;
		list = new_stack;
		//printf("Symbol was inserted with sucess\n");
	}
	return list;
}

stack *delete_scope(stack* list) {
	stack* aux = list;
	list = list->next;
	free(aux);

	return list;
}
char *take_scope(stack *list) {
	char* scope = (char*) malloc(sizeof(char)*strlen(list->scope));
	strcpy(scope, list->scope);

	return scope;
}
int find_scope(stack *list, char* scope) {
	stack *iterator_list = list;

	while(iterator_list != NULL) {
		if(strcmp(scope, iterator_list->scope) == 0) {
			return TRUE;
		}
		iterator_list = iterator_list->next;
	}
	return FALSE;
}
