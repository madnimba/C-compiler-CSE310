flex 2005019.l
g++ -c lex.yy.c -o lex.yy.o
g++ -o my_executable lex.yy.o 2005019.cpp
./my_executable input.txt

rm my_executable