{
  description = "MoonBit LLM client development shell";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, moonbit-overlay, ... }:
    {
      devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ moonbit-overlay.overlays.default ];
          };
          shell = pkgs.mkShell {
            packages = [
              pkgs.moonbit-bin.latest
              pkgs.nodejs
            ];
          };
        in
        {
          ci = shell;
          default = shell;
        }
      );
    };
}
