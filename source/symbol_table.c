#ifndef SYMBOL_TABLE
#include "symbol_table.h"
#define TRUE 1
#define FALSE 0
#endif

node *create_list() {
	
	node *list;
	list = (node*)malloc(sizeof(node));
	if(list == NULL) {
		printf("ERROR IN ALOCATION");
		exit(1);	
	}
	list->next = NULL;
	return list;
}

int is_empty(node *list) {
	
	if(list->next == NULL ) {
		return TRUE;
	} else {
		return FALSE;
	}
}

void insert_symbol(node *list, char *symbol, node *new_node) {
	if(new_node == NULL || list == NULL) {
		printf("MEMORY ERROR, OR ALOCATION ERROR");
		exit(1);
	}
	new_node->next = NULL;
	strcpy(new_node->symbol, symbol);
	if(is_empty(list)) {
		list->next = new_node;
	} else {
		node *iterator_list;
		iterator_list = list->next;
		while(iterator_list != NULL) {
			iterator_list = iterator_list->next;
		}
		iterator_list->next = new_node;
		printf("Symbol was inserted with sucess");	
	}
}

int find_symbol(node *list, char *symbol, char *scope) {
	if(list == NULL) {
		printf("ERROR IN ALOCATION");
	}
	int symbol_found = FALSE;
	node *iterator_list = list->next;
	while(iterator_list != NULL) {
		if(strcmp(symbol, iterator_list->symbol) == 0) {
			symbol_found = TRUE;
			return TRUE;
		} 
		iterator_list = iterator_list->next;
	
	}
	
	/* If this function arrived here the list don't have the symbol */
	return FALSE;
}
