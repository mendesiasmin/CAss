#include <stdio.h>
#include <stdlib.h>

int main() {

	char str;
	FILE* file = fopen("inAux.txt", "w+");

	while(scanf("%c", &str) == 1) {
		if(str!='{' && str!='}')
			fprintf(file, "%c", str);
		else {
			fprintf(file, "\n%c\n", str);
		}
	}

	fclose(file);

	unlink("in.txt");
	rename("inAux.txt", "in.txt");

	return 0;
}
