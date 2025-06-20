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
    binutils_sha256 = "e4c38b893f590853fbe276a6b8a1268101e35e61849a07f6ee97b5ecc97fbff8",
    binutils_strip_prefix = "binutils-2.43.1",
    binutils_urls = [
        "https://mirrors.ocf.berkeley.edu/gnu/binutils/binutils-2.43.1.tar.gz",
        "https://ftp.gnu.org/gnu/binutils/binutils-2.43.1.tar.gz",
    ],
    gcc_sha256 = "ace8b8b0dbfe6abfc22f821cb093e195aa5498b7ccf7cd23e4424b9f14afed22",
    gcc_strip_prefix = "gcc-14.3.0",
    gcc_urls = [
        "https://mirrors.ocf.berkeley.edu/gnu/gcc/gcc-14.3.0/gcc-14.3.0.tar.gz",
        "https://ftp.gnu.org/gnu/gcc/gcc-14.3.0/gcc-14.3.0.tar.gz",
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

# Hedron's Compile Commands Extractor for Bazel
# https://github.com/hedronvision/bazel-compile-commands-extractor
http_archive(
    name = "hedron_compile_commands",

    # Replace the commit hash (0e990032f3c5a866e72615cf67e5ce22186dcb97) in both places (below) with the latest (https://github.com/hedronvision/bazel-compile-commands-extractor/commits/main), rather than using the stale one here.
    # Even better, set up Renovate and let it do the work for you (see "Suggestion: Updates" in the README).
    url = "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/a14ad3a64e7bf398ab48105aaa0348e032ac87f8.tar.gz",
    strip_prefix = "bazel-compile-commands-extractor-a14ad3a64e7bf398ab48105aaa0348e032ac87f8",
    # When you first run this tool, it'll recommend a sha256 hash to put here with a message like: "DEBUG: Rule 'hedron_compile_commands' indicated that a canonical reproducible form can be obtained by modifying arguments sha256 = ..."
    sha256 = "f01636585c3fb61c7c2dc74df511217cd5ad16427528ab33bc76bb34535f10a1",
)
load("@hedron_compile_commands//:workspace_setup.bzl", "hedron_compile_commands_setup")
hedron_compile_commands_setup()
load("@hedron_compile_commands//:workspace_setup_transitive.bzl", "hedron_compile_commands_setup_transitive")
hedron_compile_commands_setup_transitive()
load("@hedron_compile_commands//:workspace_setup_transitive_transitive.bzl", "hedron_compile_commands_setup_transitive_transitive")
hedron_compile_commands_setup_transitive_transitive()
load("@hedron_compile_commands//:workspace_setup_transitive_transitive_transitive.bzl", "hedron_compile_commands_setup_transitive_transitive_transitive")
hedron_compile_commands_setup_transitive_transitive_transitive()

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
