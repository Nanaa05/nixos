{ config, pkgs, ... }:
{
  imports = [ ../configuration.nix ];
  nixpkgs.hostPlatform.system = "i686-linux";
}
