load("//tools/toolchain:toolchain.bzl", "new_toolchain_repository")
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

local_repository(
    name = "toolchain_i686_elf_cached",
    path = ".external/toolchain-i686-elf",
)

new_toolchain_repository(
    name = "toolchain-i686-elf",
    binutils_sha256 = "0d9d2bbf71e17903f26a676e7fba7c200e581c84b8f2f43e72d875d0e638771c",
    binutils_strip_prefix = "binutils-2.29.1",
    binutils_urls = [
        "http://ftp.gnu.org/gnu/binutils/binutils-2.29.1.tar.gz",
        "http://mirrors.peers.community/mirrors/gnu/binutils/binutils-2.29.1.tar.bz2",
    ],
    build_file = "//tools/toolchain:toolchain.BUILD",
    gcc_sha256 = "0153a003d3b433459336a91610cca2995ee0fb3d71131bd72555f2231a6efcfc",
    gcc_strip_prefix = "gcc-7.2.0",
    gcc_urls = [
        "http://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz",
        "https://mirrors.peers.community/mirrors/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz",
    ],
    target_triplet = "i686-elf",
)
