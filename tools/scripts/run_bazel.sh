#!/bin/sh

set -eux;

ACTION="${1:-test}"
CONFIG="${2:-i386}"
CACHE="${3:-false}"

function run_bazel_config() {
  config="${1}"

  if [ "${CACHE}" = "true" ]; then
    bazel \
      --output_base "${HOME}/.cache/bazel/output" \
      "${ACTION}" \
      --experimental_repository_cache "${HOME}/.bazel_repository_cache" \
      --test_strategy standalone \
      --genrule_strategy standalone \
      --config ci \
      --config "${config}" \
      --  //...
    return
  fi

  bazel "${ACTION}" \
    --config ci \
    --config "${config}" \
    --  //...
}

function main() {
  run_bazel_config "${CONFIG}"
}

main
