#!/bin/sh

set -eux

BAZEL_VERSION="${1}"
BAZEL_OS="${2}"
SHA256SUM="${3}"

# Download Bazel install script and verify matches checksum.
installer="bazel-${BAZEL_VERSION}-installer-${BAZEL_OS}-x86_64.sh"
wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${installer}"
"${SHA256SUM}" "tools/checksums/${installer}.sha256"

# Install Bazel.
chmod +x "${installer}"
"./${installer}" --user
rm "${installer}"

