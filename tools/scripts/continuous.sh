#!/bin/sh

set -eux;

CONFIG="${1}"

bazel test \
  --config ci \
  --config "${CONFIG}" \
  --  //...
