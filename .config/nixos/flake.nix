{
  description = "Basic Apps and Tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      packages.x86_64-linux = {
        nixfmt = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style; # Nix formatter
      };
    };
}
