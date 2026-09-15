{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnome-network-displays
    miraclecast
  ];

  # Avahi for network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  programs.dconf.enable = true;

  # Audio capturing
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # XDG Portals
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr # Wayland portal (removed xapp since we are off X11)
    ];

    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ]; # Force wlroots for screencasting
      };
    };
  };

  networking.networkmanager.wifi.backend = "wpa_supplicant";
  networking.firewall.trustedInterfaces = [ "p2p-wl+" ];
  networking.firewall.allowedTCPPorts = [ 7236 7250 ];
  networking.firewall.allowedUDPPorts = [ 7236 5353 ];
}
