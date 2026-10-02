{ lib, ... }:
{
  hardware.bluetooth.enable = lib.mkForce false;
}
