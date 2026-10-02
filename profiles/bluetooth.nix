{ pkgs, lib, ... }:
{
  hardware.bluetooth.enable = true;
  environment.systemPackages = with pkgs; [
    bluetuith
  ];
}
