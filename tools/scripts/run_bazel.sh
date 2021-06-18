#!/bin/sh

set -eux;

ACTION="${1:-test}"
CONFIG="${2:-i386}"
CACHE="${3:-false}"

if [ "${CACHE}" = "true" ]; then
  bazel \
    --output_base "${HOME}/.cache/bazel/output" \
    "${ACTION}" \
    -s \
    --experimental_repository_cache "${HOME}/.bazel_repository_cache" \
    --test_strategy standalone \
    --genrule_strategy standalone \
    --config ci \
    --config "${CONFIG}" \
    --  //...
  exit
fi

bazel "${ACTION}" \
  -s \
  --config ci \
  --config "${CONFIG}" \
  --  //...
