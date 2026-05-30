{ config, lib, pkgs, ... }:
let
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
      convert ${./wallpaper.jpg} \
        -resize "1920x1080^" \
        -gravity center \
        -extent "1920x1080" \
        $out/splash.png      

      sed -i 's/desktop-image: .*/desktop-image: "background.png"\ndesktop-image-scale-method: "crop"\ndesktop-image-h-align: "center"\ndesktop-image-v-align: "center"/' $out/theme.txt
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./gpu.nix
  ];

  boot.loader.grub.theme = my-custom-grub-theme;
  
  boot.loader.grub.splashImage = "${my-custom-grub-theme}/splash.png";
  
  boot.loader.grub.devices = [ "nodev" ];
  
  boot.loader.grub.splashMode = "normal";

  boot.loader.grub.gfxmodeEfi = "keep";
  boot.initrd.kernelModules = [ "i915" "amdgpu" ];

  boot.kernelParams = [ 
    "noresume" 
    "quiet" 
    "boot.shell_on_fail" 
    "loglevel=3" 
    "rd.systemd.show_status=false" 
    "rd.udev.log_level=3" 
    "udev.log_priority=3" 
    "vt.global_cursor_default=0"
  ];
  
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.initrd.systemd.tpm2.enable = false;
  
  systemd.tpm2.enable = false;

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

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      options = "caps:escape";
    };
    displayManager.startx.enable = true;
  };

  services.libinput = {
    enable = true;
    mouse.naturalScrolling = true;
    touchpad.naturalScrolling = true;
  };

  users.users.lynaten = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" ];
  };

  environment.systemPackages = with pkgs; [
    vim wget curl git pciutils usbutils vis fzf fd ripgrep xclip devenv tree
    bibata-cursors
  ];

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr
  '';

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };
  
  time.timeZone = "Asia/Jakarta";

  system.stateVersion = "25.11";
}
