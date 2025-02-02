{
  description = "Flake for setting up development of Smouth OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux"; # Replace with your system if needed
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
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
}
