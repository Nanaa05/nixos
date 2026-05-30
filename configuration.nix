{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./intel-gpu.nix
  ];

  # Bootloader configuration
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.kernelParams = [ 
    "noresume" 
  ];

  boot.initrd.systemd.tpm2.enable = false;
  systemd.tpm2.enable = false;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Replaces Alpine OpenRC getty definitions for tty1 autologin
  services.getty.autologinUser = "lynaten";

  # services.openssh.enable = true;
  # services.openssh.settings.PermitRootLogin = "yes";
  
  # The fixed, modern structured configuration for logind!
  services.logind.settings = {
    Login = {
      NAutoVTs = 2;
      ReserveVT = 2;
    };
  };

  # Sound Engine
  security.rtkit.enable = true;
  security.sudo.extraConfig = ''
    Defaults env_keep += "HOME"
  '';

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # X11 Capabilities
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    displayManager.startx.enable = true;
  };

  services.libinput = {
    enable = true;
    mouse.naturalScrolling = true;
    touchpad.naturalScrolling = true;
  };
  # Docker
  # virtualisation.docker.enable = true;

  users.users.lynaten = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" ];
  };

  environment.systemPackages = with pkgs; [
    vim wget curl git pciutils usbutils
  ];
  time.timeZone = "Asia/Jakarta";

  system.stateVersion = "25.11";
}
