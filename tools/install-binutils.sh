URL="http://ftp.gnu.org/gnu/binutils/binutils-2.29.1.tar.gz";
DIR="binutils-2.29.1";

cd $SRC;

if [ ! -d "$DIR" ];  then
    wget "$URL";
    tar -xzf "$DIR.tar.gz";
    rm "$DIR.tar.gz";
fi

mkdir -p build-binutils;
cd build-binutils;

echo "./configure in binutils..."
../"$DIR"/configure --target=$TARGET --prefix=$PREFIX --with-sysroot --disable-nls --disable-werror || exit $?
echo "make on binutils..."
make || exit $?;
echo "make install on binutils..."
make install || exit $?;

