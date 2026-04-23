{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
  };
  outputs =
    {
      self,
      nixpkgs,
      utils,
      zig,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zigpkg = zig.packages.${system}."0.16.0";
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            zigpkg
            qemu
          ];
        };

        packages.default = pkgs.buildEnv {
          name = "smouth-os-env";
          paths = with pkgs; [
            zigpkg
            qemu
            bash
            coreutils
          ];
        };
      }
    );
}
