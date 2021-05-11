calc: calc.s
	nasm -f elf calc.s -o calc.o
	gcc -m32 -Wall -g calc.o -o calc
	rm calc.o
	
.PHONY:clean

clean:
	rm -f *.o calc