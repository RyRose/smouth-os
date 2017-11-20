#!/bin/bash

case $1 in
    i386)
      export TARGET=i686-elf;
        ;;
    *)
        echo "Invalid architecture: $1";
        exit 1;
esac

if [ ! -d "tools/compilers/$TARGET" ]; then
  ./tools/install.sh $TARGET || exit $?;
fi

bazel build :iso --spawn_strategy=standalone --crosstool_top=//tools:toolchain --cpu=$1 --host_cpu=$1 --strip=never --verbose_failures || exit $?
qemu-system-$1 -cdrom bazel-genfiles/os.iso -monitor stdio -s
