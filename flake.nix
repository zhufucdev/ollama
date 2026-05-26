{
  description = "Hardcoded Gemma vision budget as the original one, but higher.";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs =
    {
      nixpkgs,
      self,
      ...
    }:
    let
      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or (toString (self.lastModified or 0));

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      overlay = final: prev: {
        ollama = final.callPackage ./nix/package.nix { inherit version; };
        ollama-rocm = final.callPackage ./nix/package.nix {
          inherit version;
          acceleration = "rocm";
        };
      };

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        }
      );
    in
    {
      overlays.default = overlay;

      nixosModules.default =
        { ... }:
        {
          nixpkgs.overlays = [ overlay ];
        };

      packages = forAllSystems (system: {
        default = nixpkgsFor.${system}.ollama;
      });
    };
}
