load("//tools/toolchain:toolchain.bzl", "new_toolchain_repository")

http_archive(
    name = "com_google_googletest",
    url = "https://github.com/google/googletest/archive/master.zip",
    strip_prefix = "googletest-master"
)

new_toolchain_repository(
    name = "toolchain-i686-elf",
    build_file = "//tools/toolchain:toolchain.BUILD",
    binutils_urls = ["http://ftp.gnu.org/gnu/binutils/binutils-2.29.1.tar.gz", "http://mirrors.peers.community/mirrors/gnu/binutils/binutils-2.29.1.tar.bz2"],
    binutils_sha256 = "0d9d2bbf71e17903f26a676e7fba7c200e581c84b8f2f43e72d875d0e638771c",
    binutils_strip_prefix = "binutils-2.29.1",
    gcc_urls = ["http://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz", "https://mirrors.peers.community/mirrors/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.gz"],
    gcc_sha256 = "0153a003d3b433459336a91610cca2995ee0fb3d71131bd72555f2231a6efcfc",
    gcc_strip_prefix = "gcc-7.2.0",
    target_triplet = "i686-elf",
)
