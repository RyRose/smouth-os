#!/bin/sh

set -eux

# Download Bazel install script and verify matches checksum.
installer="bazel-${BAZEL_VERSION}-installer-${BAZEL_OS}-x86_64.sh"
wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${installer}"
case "${BAZEL_OS}" in
  darwin)
    shasum -a 256 -c "tools/checksums/${installer}.sha256"
    ;;
  linux)
    sha256sum --check "tools/checksums/${installer}.sha256"
    ;;
  *)
    echo "${BAZEL_OS} is not a supported OS."
    exit 1
esac

# Install Bazel.
chmod +x "${installer}"
"./${installer}" --user
rm "${installer}"

