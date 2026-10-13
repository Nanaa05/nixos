{ pkgs, lib, inputs, config, ... }:
let
  env = import ../env.nix;
  my-sxwm = pkgs.stdenv.mkDerivation {
    pname = "sxwm";
    version = "git";
    src = inputs.sxwm-src;
    buildInputs = with pkgs; [ libX11 libXinerama libXcursor libXext ];
    patches = [ ../dotfiles/sxwm-global-opacity.patch ];
    makeFlags = [ "PREFIX=$(out)" ];
  };

  my-boomer = pkgs.stdenv.mkDerivation {
    pname = "boomer";
    version = "git";
    src = inputs.boomer-src;
    nativeBuildInputs = [ pkgs.nim_1_0 pkgs.patchelf ];
    buildInputs = with pkgs; [ libX11 libXrandr libGL ];
    buildPhase = ''
      export HOME=$TMPDIR
      nim -p:${inputs.nim-x11-src} -p:${inputs.nim-opengl-src}/src c -d:release src/boomer.nim
    '';
    installPhase = "install -Dt $out/bin src/boomer";
    dontStrip = true;
    postFixup = ''
      patchelf --set-rpath ${lib.makeLibraryPath (with pkgs; [ stdenv.cc.cc libX11 libXrandr libGL ])} $out/bin/boomer
    '';
  };

  # Minimal picom config, used only while boomer-live runs on profiles without a
  # compositor: no effects, it only exists to draw the zoomed screen. The shader
  # shows every window as X does without a compositor (alpha ignored).
  zoomPicomDir = pkgs.runCommand "picom-zoom-only" { } ''
    mkdir -p $out
    cat > $out/picom.conf <<'EOF'
    backend = "glx";
    vsync = true;
    shadow = false;
    fading = false;
    rules = ({
      shader = "opaque.frag";
    });
    EOF
    cat > $out/opaque.frag <<'EOF'
    #version 330
    in vec2 texcoord;
    uniform sampler2D tex;
    vec4 window_shader() {
      vec2 texsize = textureSize(tex, 0);
      vec4 c = texture2D(tex, texcoord / texsize, 0);
      return vec4(c.rgb, 1.0);
    }
    EOF
  '';

  # s-Z: use the running (patched) picom if there is one, otherwise start a
  # zoom-only picom for the lifetime of boomer.
  boomer-live = pkgs.writeShellScriptBin "boomer-live" ''
    # the ack holds picom's pid: a leftover from a picom that died doesn't count
    has_ack() {
      pid=$(${pkgs.xprop}/bin/xprop -root _BOOMER_ZOOM_ACK 2>/dev/null | sed -n 's/.*= *//p')
      [ -n "$pid" ] && [ -d "/proc/$pid" ]
    }
    if has_ack; then
      exec ${my-boomer}/bin/boomer --live "$@"
    fi
    start=$(date +%s%N)
    ${pkgs.picom}/bin/picom --config ${zoomPicomDir}/picom.conf &
    picom_pid=$!
    trap 'kill -INT $picom_pid 2>/dev/null' EXIT
    for _ in $(seq 1 100); do
      has_ack && break
      sleep 0.02
    done
    echo "boomer-live: picom ready in $(( ($(date +%s%N) - start) / 1000000 )) ms" >&2
    ${my-boomer}/bin/boomer --live "$@"
  '';

  my-st = pkgs.st.overrideAttrs (oldAttrs: {
    src = inputs.st-src;

    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.libxcursor ];

    preBuild = ''
      export NIX_LDFLAGS="$NIX_LDFLAGS -lXcursor"
    '';

    patches = [
      (pkgs.fetchurl {
        url = "https://st.suckless.org/patches/alpha/st-alpha-20240814-a0274bc.diff";
        hash = "sha256-Vi9qS67euJyLbfssLxSmn5Mn+otxpQk+cCGeOXlLjUI=";
      })
      ../dotfiles/st/runtime-alpha.patch
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
    my-boomer
    boomer-live
    firefox
    zoom-us
    discord
    openssl
    spotify-player
    krita
    codex
    codex-acp
    claude-code
    claude-agent-acp
    opencode
    sops age
    xinit xrandr xset xinput xkbcomp xwallpaper
    (python3.withPackages (ps: [ ps.xlib ]))
    dmenu feh maim xclip xdotool wl-clipboard
    brightnessctl pcmanfm htop tmux fastfetch zip cava clock-rs
    pavucontrol mpv emacs-nox
    terminus_font dejavu_fonts liberation_ttf noto-fonts-cjk-sans
    vscode
    krita
  ];

  environment.variables = {
    ENV = "$HOME/.profile";
    BROWSER = "firefox";
    EDITOR = "emacs";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  systemd.user.services.x11-setup = {
    serviceConfig = {
      Type = "oneshot";
      Environment = lib.mkForce [ "DISPLAY=:0" ];
      ExecStart = "${pkgs.writeShellScript "x11-setup" ''
        export XAUTHORITY=$HOME/.Xauthority
        while ! ${pkgs.xset}/bin/xset q >/dev/null 2>&1; do sleep 0.01; done
        ${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR

        MONITOR=$(${pkgs.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/cut -d ' ' -f1)

        # TODO: Dynamic Hz Min
        ${pkgs.xrandr}/bin/xrandr --newmode "1080p_${env.hzMin}Hz" 173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
        ${pkgs.xrandr}/bin/xrandr --addmode $MONITOR "1080p_${env.hzMin}Hz"
        # one modeset only: every extra one blanks the panel for about a second. The max profile
        # (the one with picom) goes straight to its final rate instead of 60 Hz and then 120 Hz.
        ${if config.services.picom.enable
          then ''${pkgs.xrandr}/bin/xrandr --output $MONITOR --mode ${env.resFHD} --rate ${env.hzMax}''
          else ''${pkgs.xrandr}/bin/xrandr --output $MONITOR --mode "1080p_${env.hzMin}Hz"''}

        printf "Xcursor.theme: Bibata-Modern-Ice\nXcursor.size: 24\n" | ${pkgs.xrdb}/bin/xrdb -merge
        
        ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr &
        ${pkgs.xset}/bin/xset r rate 300 50 &
        ${pkgs.xset}/bin/xset s off -dpms &
        ${pkgs.xwallpaper}/bin/xwallpaper --zoom /home/lynaten/nixos/wallpaper.jpg
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
