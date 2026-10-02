{ pkgs, inputs, ... }:
{
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = [
    inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
