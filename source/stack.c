#ifndef STACK
#include "stack.h"
#define TRUE 1
#define FALSE 0
#endif

node *create_stack() {
	return NULL;
}

node* insert_scope(node *list, char *scope) {

	node *new_node = (node*) malloc(sizeof(node));

	new_node->next = NULL;
	new_node->scope = (char*)malloc(sizeof(strlen(scope)));

	strcpy(new_node->scope, scope);

	if(is_empty(list)) {
		list = new_node;
	} else {
		new_node->next = list;
		list = new_node;
		printf("Symbol was inserted with sucess\n");	
	}
	return list;
}

node* delete_scope(node* list) {
	node* aux = list;
	list = list->next;
	free(aux);
}
char* take_scope(node *list) {
	return list->scope;
}
