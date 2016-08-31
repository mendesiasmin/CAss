CAss: flex-bison/CAss.l flex-bison/CAss.y
	bison -d flex-bison/CAss.y
	mv CAss.tab.h outputs/sintatico.h
	mv CAss.tab.c outputs/sintatico.c
	flex flex-bison/CAss.l
	mv lex.yy.c outputs/lexico.c
	gcc -o CAss outputs/sintatico.c outputs/lexico.c

clean:
	rm outputs/lexico.* outputs/sintatico.* CAss
run: 
	./CAss < in
