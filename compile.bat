..\cc65\bin\ca65 src\tutorial.s -o build\tutorial.o
..\cc65\bin\ca65 src\reset.s -o build\reset.o
..\cc65\bin\ca65 src\controllers.s -o build\controllers.o
..\cc65\bin\ca65 src\background.s -o build\background.o

..\cc65\bin\ld65 build\reset.o build\background.o build\controllers.o build\tutorial.o -C nes.cfg -o tutorial.nes
