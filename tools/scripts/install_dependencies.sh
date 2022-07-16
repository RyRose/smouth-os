#!/bin/sh

set -eux;

if which dnf; then
  sudo dnf install gcc g++ make bison flex gmp-devel libmpc-devel mpfr-devel texinfo qemu
elif which apt; then
  sudo apt-get install build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo
else
  echo Automatic dependency installation not supported for your OS.
  exit 1
fi
