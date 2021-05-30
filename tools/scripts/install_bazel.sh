#!/bin/sh

set -eux

BAZEL_VERSION="${1}"
BAZEL_OS="${2}"

# Download Bazel install script and verify matches checksum.
installer="bazel-${BAZEL_VERSION}-installer-${BAZEL_OS}-x86_64.sh"
wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${installer}"

if command -v sha256sum &>/dev/null; then
  sha256sum --check "tools/checksums/${installer}.sha256"
elif command -v shasum &>/dev/null; then
  shasum -a 256 -c "tools/checksums/${installer}.sha256"
else
  echo "No binary available for verify sha256 checksums."
  exit 1
fi

# Install Bazel.
chmod +x "${installer}"
"./${installer}" --user
rm "${installer}"

