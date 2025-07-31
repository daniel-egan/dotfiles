{
  pkgs,
  lib,
}:
{
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    dates = "weekly";
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 10d";
  };

  nix.settings.auto-optimise-store = true;
}
