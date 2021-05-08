#!/bin/sh

if [ -z "${BAZEL_OS}" ]; then
  I386_PREMADE_CONFIG_FLAG=""
else
  I386_PREMADE_CONFIG_FLAG="--config i386-${BAZEL_OS}-premade"
fi

set -eux;

bazel test \
  --config ci \
  --  //...

bazel test \
  --config ci \
  --config i386 \
  ${I386_PREMADE_CONFIG_FLAG} \
  -- //...
