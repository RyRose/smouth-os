{
  description = "Flake for setting up development of Smouth OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      self,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        { pkgs, system, ... }:
        {
          devShells.default = pkgs.mkShell {
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
          };
        };
    };
}
