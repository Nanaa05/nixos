{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    pkgs.seahorse
    inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
