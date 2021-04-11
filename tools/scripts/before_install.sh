#!/bin/sh

set -eux

# Install OS-specific dependencies.
case "${OS}" in
  darwin)
    brew install qemu
    ;;
  linux)
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt-get update
    sudo apt-get install -y libstdc++6 gcc-7 g++-7 qemu
    ;;
  *)
    echo "${OS} is not a supported OS."
    exit 1
esac

# Download Bazel install script and verify matches checksum.
installer="bazel-${V}-installer-${OS}-x86_64.sh"
wget "https://github.com/bazelbuild/bazel/releases/download/${V}/${installer}"
case "${OS}" in
  darwin)
    shasum -a 256 -c "tools/checksums/${installer}.sha256"
    ;;
  linux)
    sha256sum --check "tools/checksums/${installer}.sha256"
    ;;
  *)
    echo "${OS} is not a supported OS."
    exit 1
esac

# Install Bazel.
chmod +x "${installer}"
"./${installer}" --user
rm "${installer}"

