{ pkgs, lib, inputs, ... }:
let
  env = import ../env.nix;
  my-sxwm = pkgs.stdenv.mkDerivation {
    pname = "sxwm";
    version = "git";
    src = inputs.sxwm-src;
    buildInputs = with pkgs; [ libX11 libXinerama libXcursor ];
    makeFlags = [ "PREFIX=$(out)" ];
  };

  my-st = pkgs.st.overrideAttrs (oldAttrs: {
    src = inputs.st-src;

    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.libxcursor ];

    preBuild = ''
      export NIX_LDFLAGS="$NIX_LDFLAGS -lXcursor"
    '';

    patches = [
      (pkgs.fetchurl {
        url = "https://st.suckless.org/patches/alpha/st-alpha-20220206-0.8.5.diff";
        hash = "sha256-QuSAPOKmeDX35TOnB6iijjgEomztFjFFEIlwua7l+4E=";
      })
    ];

    postPatch = (oldAttrs.postPatch or "") + ''
      cp ${../dotfiles/st/config.h} config.def.h

      sed -i 's/char \*args\[\] = {prog, NULL};/char \*args\[\] = {prog, "-l", NULL};/' st.c
      sed -i 's/XC_xterm/XC_left_ptr/g' x.c
    '';
  });
in {
  environment.systemPackages = with pkgs; [
    my-sxwm
    my-st
    boomer
    firefox
    discord
    openssl
    spotify-player
    xinit xrandr xset xinput xkbcomp xwallpaper
    dmenu feh maim xclip xdotool wl-clipboard
    brightnessctl pcmanfm htop tmux fastfetch zip
    pavucontrol mpv yt-dlp emacs-nox
    terminus_font dejavu_fonts liberation_ttf noto-fonts-cjk-sans
  ];

  environment.variables = {
    ENV = "$HOME/.profile";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  systemd.user.services.x11-setup = {
    after = [ "default.target" ];
    wantedBy = [ "default.target" ];

    unitConfig = { StartLimitIntervalSec = 0; };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = lib.mkForce [ "DISPLAY=:0" ];
      Restart = "on-failure";
      RestartSec = 2;
      ExecStart = "${pkgs.writeShellScript "x11-setup" ''
        export XAUTHORITY=$HOME/.Xauthority
        while ! ${pkgs.xset}/bin/xset q >/dev/null 2>&1; do sleep 0.01; done
        ${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR

        MONITOR=$(${pkgs.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/cut -d ' ' -f1)

        # TODO: Dynamic Hz Min
        ${pkgs.xrandr}/bin/xrandr --newmode "1080p_${env.hzMin}Hz" 173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
        ${pkgs.xrandr}/bin/xrandr --addmode $MONITOR "1080p_${env.hzMin}Hz"
        ${pkgs.xrandr}/bin/xrandr --output $MONITOR --mode "1080p_${env.hzMin}Hz"

        printf "Xcursor.theme: Bibata-Modern-Ice\nXcursor.size: 24\n" | ${pkgs.xrdb}/bin/xrdb -merge
        
        ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr &
        ${pkgs.xset}/bin/xset r rate 300 50 &
        ${pkgs.xset}/bin/xset s off -dpms &
        ${pkgs.xwallpaper}/bin/xwallpaper --zoom /etc/nixos/wallpaper.jpg &
      ''}";
    };
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      options = "caps:escape";
    };
    displayManager.startx.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true;
  };
}
