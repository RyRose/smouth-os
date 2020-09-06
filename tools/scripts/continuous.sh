#!/bin/sh

if [[ "${OS}" == "" ]]; then
  I386_CONFIG="i386"
else
  I386_CONFIG="i386-${OS}-premade"
fi

set -eu;

bazel build \
  --config ci \
  --  //... -//tools/toolchain/...

bazel test \
  --config ci \
  --  //... -//tools/toolchain/...

bazel build \
  --config ci \
  --config "${I386_CONFIG}" \
  -- //kernel

bazel run \
  --config ci \
  --config "${I386_CONFIG}" \
  -- //tools/go/cmd/qemu:serial
