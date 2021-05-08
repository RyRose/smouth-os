#!/bin/sh

set -eux;

CROSS_COMPILE_CONFIG="${1:-i386}"

bazel test \
  --config ci \
  --  //...

bazel test \
  --config ci \
  --config "${CROSS_COMPILE_CONFIG}" \
  -- //...
