{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "smouthos-devshell";
  inputsFrom = [
    (pkgs.buildFHSEnv {
      name = "smouthos-fhs";
      targetPkgs =
        pkgs: with pkgs; [
          bazel
          glibc
          gcc
          go
          gotools
          go-tools
          gdb
          file
          gettext
          gmp
          mpfr
          mpc
          isl
        ];
    }).env
  ];
  packages = with pkgs; [
    # QEMU needs to be in the devshell for integration tests
    # to see it.
    qemu
  ];
}
