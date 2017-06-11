#!/bin/sh
set -e

source ./config.sh

for PROJECT in $PROJECTS; do
  (cd $PROJECT && DESTDIR="$SYSROOT" $MAKE test)
done

for PROJECT in $PROJECTS; do
  (cd $PROJECT && ./test.out)
done
