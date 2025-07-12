#!/bin/bash

clear
nasm -f elf32 main.asm -o main.o
ld -m elf_i386 main.o -o main

if [[ "$1" == "--debug" || "$1" == "-d" ]]; then
    gdb -ex "layout asm" \
        -ex "break _start" \
        -ex "run" \
        main
    
    clear
else
    ./main
fi
