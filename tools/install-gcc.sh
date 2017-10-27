#!/bin/bash

URL="http://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz";
DIR="gcc-7.2.0"

which -- $TARGET-as || exit $?

cd $SRC;

if [ ! -d "$DIR" ];  then
    wget "$URL";
    tar -xzf "$DIR.tar.gz";
    rm "$DIR.tar.gz";
fi

cd $DIR;
contrib/download_prerequisites || exit $?;
cd ..;
mkdir build-gcc;
cd build-gcc;

echo "configuring gcc...";
../$DIR/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers || exit $?;
echo "make all-gcc...";
make all-gcc || exit $?;
echo "make all-target-libgcc...";
make all-target-libgcc || exit $?;
echo "make install-gcc...";
make install-gcc || exit $?;
echo "make install-target-libgcc...";
make install-target-libgcc || exit 1;
