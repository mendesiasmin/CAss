#ifndef SYMBOL_TABLE
#include "symbol_table.h"
#define TRUE 1
#define FALSE 0
#endif

node* create_list() {
	return NULL;
}

int is_empty(node *list) {
	return list == NULL;
}

node* insert_symbol(node *list, char *symbol, char* scope, int type, int word, int value) {

	node *new_node = (node*) malloc(sizeof(node));

	new_node->next = NULL;

	new_node->symbol = symbol;
	new_node->scope = scope;
	new_node->type = type;
	new_node->word = word;
	new_node->value = value;

	if(is_empty(list)) {
		list = new_node;
	} else {
		node *iterator_list;
		iterator_list = list;
		while(iterator_list->next != NULL) {
			iterator_list = iterator_list->next;
		}
		new_node->previous = iterator_list;
		iterator_list->next = new_node;
		//printf("Symbol was inserted with sucess\n");
	}
	return list;
}

void imprime(node *list) {

	node* listAux = list;
	int i=0;

	while(listAux != NULL) {
		printf("Impress: %d %s %s %d %d %d\n", i++, listAux->symbol, listAux->scope, listAux->type, listAux->word, listAux->value);
		listAux = listAux->next;
	}
}

node* delete_symbol(node *list, node *delete){
		if(delete == list){
			delete->next->previous = NULL;
			list = delete->next;
		}
		else{
			delete->previous->next = delete->next;
			if(delete->next != NULL) delete->next->previous = delete->previous;
		}
		delete->next = NULL;
		delete->previous = NULL;
		free(delete);
		return list;
}

int find_symbol(node *list, char *symbol) {
	node *iterator_list = list;

	while(iterator_list != NULL) {
		if(strcmp(symbol, iterator_list->symbol) == 0) {
			return TRUE;
		}
		iterator_list = iterator_list->next;
	}

	/* If this function arrived here the list don't have the symbol */
	return FALSE;
}

char* take_scope_of_symbol(node *list, char *symbol, char* scope_actual) {
	node *iterator_list = list;

	while(iterator_list != NULL) {
		if((strcmp(symbol, iterator_list->symbol) == 0) && (strcmp(scope_actual, iterator_list->scope) == 0)) {
			return iterator_list->scope;
		}
		iterator_list = iterator_list->next;
	}
	return "global";
}

node* take_symbol(node *list, char *symbol) {
	node *iterator_list = list;

	while(iterator_list != NULL) {
		if(strcmp(symbol, iterator_list->symbol) == 0) {
			return iterator_list;
		}
		iterator_list = iterator_list->next;
	}
	return NULL;
}

node* take_last(node *list, int type) {

	node *iterator_list = list;
	node *pointer = NULL;

	while(iterator_list != NULL) {
		if(iterator_list->type == type) {
			pointer = iterator_list;
		}
		iterator_list = iterator_list->next;
	}
	return pointer;
}

node* take_last_symbol(node *list){
	node *iterator_list = list;

	while(iterator_list->next != NULL) {
		iterator_list = iterator_list->next;
	}
	return iterator_list;
}
