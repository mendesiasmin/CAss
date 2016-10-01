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

node* insert_symbol(node *list, char *symbol, char* scope) {

	node *new_node = (node*) malloc(sizeof(node));

	new_node->next = NULL;
	new_node->symbol = (char*)malloc(sizeof(strlen(symbol)));
	new_node->scope = (char*)malloc(sizeof(strlen(scope)));

	strcpy(new_node->symbol, symbol);
	strcpy(new_node->scope, scope);

	if(is_empty(list)) {
		list = new_node;
	} else {
		node *iterator_list;
		iterator_list = list;
		while(iterator_list->next != NULL) {
			iterator_list = iterator_list->next;
		}
		iterator_list->next = new_node;
		printf("Symbol was inserted with sucess\n");
	}
	return list;
}

void imprime(node *list) {

	node* listAux = list;
	int i=0;

	while(listAux != NULL) {
		printf("Impress: %d %s %s\n", i++, listAux->symbol, listAux->scope);
		listAux = listAux->next;
	}
}

int find_symbol(node *list, char *symbol, char *scope) {
	node *iterator_list = list;

	imprime(list);

	while(iterator_list != NULL) {
		if(strcmp(symbol, iterator_list->symbol) == 0) {
			return TRUE;
		}
		iterator_list = iterator_list->next;
	}

	/* If this function arrived here the list don't have the symbol */
	return FALSE;
}
