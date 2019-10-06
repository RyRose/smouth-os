load("//tools/toolchain:toolchain_repository.bzl", "toolchain_repository")
load("//tools/toolchain:premade_toolchain_repository.bzl", "premade_toolchain_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# rules_cc is required transitively by googletest.
http_archive(
    name = "rules_cc",
    strip_prefix = "rules_cc-master",
    urls = ["https://github.com/bazelbuild/rules_cc/archive/master.zip"],
)

http_archive(
    name = "googletest",
    strip_prefix = "googletest-master",
    url = "https://github.com/google/googletest/archive/master.zip",
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

http_archive(
    name = "toolchain-i686-elf-linux",
    urls = ["https://storage.googleapis.com/smouth-os/toolchain-i686-elf-linux.zip"],
    build_file = "//tools/toolchain:toolchain.BUILD",
    sha256 = "30106bd24018a911d3bc6f3de58d16f20cc1ea393b04d34c40692c640609b8c6",
)

premade_toolchain_repository(
    name = "toolchain-i686-elf-darwin",
    path = "//tools/toolchain/premade:i686-elf-darwin.zip",
)

# Rules needed for golang tests

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_go",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/0.19.4/rules_go-0.19.4.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/0.19.4/rules_go-0.19.4.tar.gz",
    ],
    sha256 = "ae8c36ff6e565f674c7a3692d6a9ea1096e4c1ade497272c2108a810fb39acd2",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "bazel_gazelle",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/bazel-gazelle/releases/download/0.18.2/bazel-gazelle-0.18.2.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.18.2/bazel-gazelle-0.18.2.tar.gz",
    ],
    sha256 = "7fc87f4170011201b1690326e8c16c5d802836e3a0d617d8f75c3af2b23180c4",
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()
