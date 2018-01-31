#!/usr/bin/sh

nasm boot.asm -f bin -o boot.bin
nasm main.asm -f bin -o main.bin
cat boot.bin main.bin > image.bin
