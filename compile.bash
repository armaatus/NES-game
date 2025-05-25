#!/bin/bash

# Build NES game using cc65 on macOS
ca65 src/main.s
ca65 src/reset.s 
ca65 src/controllers.s
ca65 src/background.s

ld65 src/reset.o src/background.o src/controllers.o src/main.o -C nes.cfg -o game.nes

# Remove the build files
rm src/main.o
rm src/reset.o
rm src/controllers.o
rm src/background.o
