#!/bin/bash

export TARGET="$1"
case $TARGET in
    i686-elf)
        ;;
    *)
        echo "Invalid target: $TARGET";
        exit 1;
esac

export ROOT="$(dirname $(realpath $0))"
export PREFIX="$ROOT/compilers/$TARGET"
export SRC="$PREFIX/src"
# export SRC="$ROOT/src"
# export PREFIX="$ROOT/compilers"

mkdir -p $SRC;
mkdir -p $PREFIX/bin;

export PATH="$PATH:$PREFIX/bin"

echo "Installing binutils..."
sh $ROOT/install-binutils.sh || exit 1;
echo "Installing g++..." 
sh $ROOT/install-gcc.sh || exit 1;
