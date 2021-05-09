#!/bin/sh

set -eux;

ACTION="${1}"
CONFIG="${2}"

bazel
  --output_base "${HOME}/.cache/bazel/output" \
  --experimental_repository_cache "${HOME}/.bazel_repository_cache" \
  "${ACTION}" \
  --test_strategy standalone \
  --genrule_strategy standalone \
  --config ci \
  --config "${CONFIG}" \
  --  //...
