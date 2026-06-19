{ lib, ... }:
{
  services.pipewire.enable = lib.mkForce false;
  services.pulseaudio.enable = lib.mkForce false;
}
