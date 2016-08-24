calc: lexico.l CAss.y
	bison -d CAss.y
	mv CAss.tab.h sintatico.h
	mv CAss.tab.c sintatico.c
	flex lexico.l
	mv lex.yy.c lexico.c
	gcc -o calc sintatico.c lexico.c

clean:
	rm lexico.* sintatico.* calc.exe
