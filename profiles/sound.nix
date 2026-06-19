{ pkgs, ... }:
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  systemd.user.services.pipewire.partOf = [ "picom.service" ];
  systemd.user.services.pipewire-pulse.partOf = [ "picom.service" ];
  systemd.user.services.wireplumber.partOf = [ "picom.service" ];
  systemd.user.sockets.pipewire.partOf = [ "picom.service" ];
  systemd.user.sockets.pipewire-pulse.partOf = [ "picom.service" ];
}
  
