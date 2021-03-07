#!/bin/sh

set -eux

# Install OS-specific dependencies.
case "${OS}" in
  darwin)
    brew install qemu
    ;;
  linux)
    LD_LIBRARY_PATH=/usr/local/lib64/:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt-get update
    sudo apt-get install -y libstdc++6 gcc-7 g++-7 qemu
    ;;
  *)
    echo "${OS} is not a supported OS."
    exit 1
esac

# Download Bazel install script and verify matches checksum.
wget -O install.sh "https://github.com/bazelbuild/bazel/releases/download/${V}/bazel-${V}-installer-${OS}-x86_64.sh"
case "${OS}" in
  darwin)
    shasum -a 256 -c "tools/checksums/bazel-${V}-installer-${OS}-x86_64"
    ;;
  linux)
    sha256sum --check "tools/checksums/bazel-${V}-installer-${OS}-x86_64"
    ;;
  *)
    echo "${OS} is not a supported OS."
    exit 1
esac

# Install Bazel.
chmod +x install.sh
./install.sh --user
rm install.sh

