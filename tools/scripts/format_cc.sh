#!/bin/sh

set -eu;

ROOTDIR="$(git rev-parse --show-toplevel)"

find "${ROOTDIR}" -iname '*.h' -o -iname '*.cc' \
  | xargs clang-format -i "-style=file:${ROOTDIR}/.clang-format"
