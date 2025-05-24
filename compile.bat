..\cc65\bin\ca65 src\main.s
..\cc65\bin\ca65 src\reset.s 
..\cc65\bin\ca65 src\controllers.s
..\cc65\bin\ca65 src\background.s

..\cc65\bin\ld65 src\reset.o src\background.o src\controllers.o src\main.o -C nes.cfg -o game.nes

del src\main.o
del src\reset.o
del src\controllers.o
del src\background.o
