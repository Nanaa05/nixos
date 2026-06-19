{ config, lib, pkgs, ... }:
let
  env = import ./env.nix;
  my-custom-grub-theme = pkgs.stdenv.mkDerivation {
    pname = "elegant-grub-custom";
    version = "1.0";
    src = ./elegant-grub-theme;
    nativeBuildInputs = [ pkgs.imagemagick ];
    installPhase = ''
      mkdir -p $out
      
      cp common/terminus*.pf2 $out/
      cp common/unifont-16.pf2 $out/
      cp config/theme-sharp-left-dark-1080p.txt $out/theme.txt
      cp -r assets/assets-icons-dark/icons-dark-1080p $out/icons
      cp assets/assets-other/other-1080p/select_e-forest-dark.png $out/select_e.png
      cp assets/assets-other/other-1080p/select_c-forest-dark.png $out/select_c.png
      cp assets/assets-other/other-1080p/select_w-forest-dark.png $out/select_w.png
      cp assets/assets-other/other-1080p/sharp-left-alt.png $out/info.png

      cp ${./background.png} $out/background.png

      # TODO: Dynamic Resize Value
      convert ${./wallpaper.jpg} \
        -resize "${env.resNative}^" \
        -gravity center \
        -extent "${env.resNative}" \
        $out/splash.png

      sed -i 's/desktop-image: .*/desktop-image: "background.png"\ndesktop-image-scale-method: "crop"\ndesktop-image-h-align: "center"\ndesktop-image-v-align: "center"/' $out/theme.txt
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  

  boot.loader.grub.theme = my-custom-grub-theme;
  
  boot.loader.grub.splashImage = "${my-custom-grub-theme}/splash.png";
  boot.loader.grub.splashMode = "normal";
  boot.loader.grub.efiSupport = true; 
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.gfxmodeEfi = "auto"; 
  boot.loader.grub.gfxmodeBios = "auto";  
  
  boot.kernelParams = [ 
    "noresume" 
    "quiet" 
    "boot.shell_on_fail" 
    "loglevel=3" 
    "rd.systemd.show_status=false" 
    "rd.udev.log_level=3" 
    "udev.log_priority=3" 
    "vt.global_cursor_default=0"
    "8250.nr_uarts=0"
    "vt.default_red=10,21,42,38,71,176,78,193,89,21,42,38,71,176,78,193"
    "vt.default_grn=23,76,90,107,80,66,157,197,108,76,90,107,80,66,157,197"
    "vt.default_blu=25,78,79,111,70,55,108,197,110,78,79,111,70,55,108,197"
  ];
  
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.initrd.systemd.tpm2.enable = false;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.bash}/bin/bash -c 'echo $$(( $$(cat /sys/class/backlight/%k/max_brightness) * 20 / 100 )) > /sys/class/backlight/%k/brightness'"
  '';

  systemd.services."systemd-backlight@".enable = false;
  
  systemd.tpm2.enable = false;
  
  systemd.services."getty@".serviceConfig.ExecStartPre = pkgs.writeScript "tty-theme" ''
    #!/bin/sh
    if [ "$TERM" = "linux" ]; then
      printf '%b' '\e]P00a1719\e]P1154C4E\e]P22A5A4F\e]P3266B6F\e]P4475046\e]P5B04237\e]P64E9D6C\e]P7c1c5c5\e]P8596c6e\e]P9154C4E\e]PA2A5A4F\e]PB266B6F\e]PC475046\e]PDB04237\e]PE4E9D6C\e]PFc1c5c5\ec' > /dev/%I
    fi
  '';

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.getty.autologinUser = "lynaten";
  services.getty.helpLine = "";
  services.getty.greetingLine = "";
  
  services.logind.settings = {
    Login = {
      NAutoVTs = 2;
      ReserveVT = 2;
    };
  };

  security.rtkit.enable = true;
  security.sudo.extraConfig = ''
    Defaults env_keep += "HOME"
  '';
  
  security.pki.certificateFiles = [
    ./itb-gitlab.crt
  ];

  console.useXkbConfig = true;

  services.libinput = {
    enable = true;
    mouse.naturalScrolling = false;
    touchpad.naturalScrolling = true;
    touchpad.tappingDragLock = false;
  };

  # services.openssh = {
  #   enable = true;
  # };

  users.users.lynaten = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" ];
  };

  nix.settings.trusted-users = [ "root" "@wheel" "lynaten" ];

  fonts.packages = with pkgs; [
    terminus_font
  ];

  console = {
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
  };
  
  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    vim wget curl git pciutils usbutils vis fzf fd ripgrep xclip devenv tree
    bibata-cursors

    # TODO: Dynamic Battery Name
    (pkgs.writeShellScriptBin "power" ''
    cat /sys/class/power_supply/${env.battery}/capacity
    '')
    
    
    (pkgs.writeShellScriptBin "font" '' 
      if [ -z "$1" ]; then
        echo "Usage: font <size>"
        echo "Available sizes: 12, 14, 16, 18, 20, 22, 24, 28, 32"
        exit 1
      fi

      SIZE=$1
      FONT_PATH="${pkgs.terminus_font}/share/consolefonts/ter-v''${SIZE}n.psf.gz"

      if [ ! -f "$FONT_PATH" ]; then
        echo "Error: Size $SIZE is not a valid Terminus font variant."
        exit 1
      fi

      setfont "$FONT_PATH"
      echo "TTY font updated to Terminus size $SIZE"
    '')
    (pkgs.writeShellScriptBin "light" ''
      if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 0 ] || [ "$1" -gt 100 ]; then
        echo "Usage: light <0-100>"
        exit 1
      fi

      TARGET=$1

      if [ "$TARGET" -lt 2 ]; then
        TARGET=2
      fi

      ${pkgs.brightnessctl}/bin/brightnessctl set "''${TARGET}%" -q
      echo "Backlight adjusted to ''${TARGET}%"
    '')
  ];
  
  time.timeZone = "Asia/Jakarta";

  system.stateVersion = "25.11";
}
