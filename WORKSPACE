load("//tools/toolchain:toolchain_repository.bzl", "toolchain_repository")
load("//tools/toolchain:premade_toolchain_repository.bzl", "premade_toolchain_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "gtest",
    sha256 = "94c634d499558a76fa649edb13721dce6e98fb1e7018dfaeba3cd7a083945e91",
    strip_prefix = "googletest-release-1.10.0",
    url = "https://github.com/google/googletest/archive/release-1.10.0.zip",
)

toolchain_repository(
    name = "toolchain-i686-elf",
    binutils_sha256 = "0d9d2bbf71e17903f26a676e7fba7c200e581c84b8f2f43e72d875d0e638771c",
    binutils_strip_prefix = "binutils-2.29.1",
    binutils_urls = [
        "http://ftp.gnu.org/gnu/binutils/binutils-2.29.1.tar.gz",
        "http://mirrors.peers.community/mirrors/gnu/binutils/binutils-2.29.1.tar.bz2",
    ],
    gcc_sha256 = "0153a003d3b433459336a91610cca2995ee0fb3d71131bd72555f2231a6efcfc",
    gcc_strip_prefix = "gcc-7.2.0",
    gcc_urls = [
        "http://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz",
        "https://mirrors.peers.community/mirrors/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz",
    ],
    target = "i686-elf",
)

premade_toolchain_repository(
    name = "toolchain-i686-elf-linux",
    paths = [
        "//tools/toolchain/premade:i686-elf-linux.0.zip",
        "//tools/toolchain/premade:i686-elf-linux.1.zip",
        "//tools/toolchain/premade:i686-elf-linux.2.zip",
        "//tools/toolchain/premade:i686-elf-linux.3.zip",
    ],
)

premade_toolchain_repository(
    name = "toolchain-i686-elf-darwin",
    paths = ["//tools/toolchain/premade:i686-elf-darwin.zip"],
)

# Rules needed for golang tests

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "ae8c36ff6e565f674c7a3692d6a9ea1096e4c1ade497272c2108a810fb39acd2",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/0.19.4/rules_go-0.19.4.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/0.19.4/rules_go-0.19.4.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "bazel_gazelle",
    sha256 = "7fc87f4170011201b1690326e8c16c5d802836e3a0d617d8f75c3af2b23180c4",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/bazel-gazelle/releases/download/0.18.2/bazel-gazelle-0.18.2.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.18.2/bazel-gazelle-0.18.2.tar.gz",
    ],
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()
