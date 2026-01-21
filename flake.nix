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
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig.packages.${system}."0.15.2"
            qemu
          ];
        };
      }
    );
}
