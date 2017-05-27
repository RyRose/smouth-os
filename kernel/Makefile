qemu: all
	qemu-system-i386 -kernel build/kernel.bin

all: kernel

kernel: build/kernel.bin
	
build/kernel.bin: obj/kernel.o obj/boot.o src/linker.ld
	i686-elf-gcc -T src/linker.ld -o build/kernel.bin -ffreestanding -O2 -nostdlib obj/boot.o obj/kernel.o -lgcc

obj/kernel.o: src/kernel.cc
	i686-elf-g++ -c src/kernel.cc -o obj/kernel.o -ffreestanding -O2 -Wall -Wextra -fno-exceptions -fno-rtti

obj/boot.o: src/boot.s
	i686-elf-g++ -std=gnu99 -ffreestanding -g -c src/boot.s -o obj/boot.o

clean:
	rm -r obj
	rm -r build
	mkdir obj
	mkdir build
