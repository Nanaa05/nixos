{ pkgs, inputs, ... }:
let
  # Compile SXWM completely from source
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
      # Base program adjustments
      sed -i 's/char \*args\[\] = {prog, NULL};/char \*args\[\] = {prog, "-l", NULL};/' st.c
      sed -i 's/alpha = .*/alpha = 0.4;/g' config.def.h
      sed -i 's/Liberation Mono:pixelsize=12/DejaVu Sans Mono:pixelsize=26/g' config.def.h
      
      sed -i 's/{[[:space:]]\+TERMMOD,[[:space:]]\+XK_Prior,[[:space:]]\+zoom,[[:space:]]\+{.f = +1}[[:space:]]\+},/{ ControlMask,            XK_equal,        zoom,           {.f = +1} },/g' config.def.h
      sed -i 's/{[[:space:]]\+TERMMOD,[[:space:]]\+XK_Next,[[:space:]]\+zoom,[[:space:]]\+{.f = -1}[[:space:]]\+},/{ ControlMask,            XK_minus,        zoom,           {.f = -1} },/g' config.def.h
      
      sed -i 's/static unsigned int mouseshape = .*/static unsigned int mouseshape = XC_left_ptr;/g' config.def.h

      sed -i 's/XC_xterm/XC_left_ptr/g' x.c
    '';
  });

in {
  environment.systemPackages = with pkgs; [
    my-sxwm
    my-st
    boomer
    firefox
    openssl
    
    # X11 Core / Window Manager Tools
    xinit xrandr xset xinput xkbcomp
    dmenu picom feh xwallpaper maim xclip xdotool wl-clipboard
    brightnessctl pcmanfm htop tmux fastfetch zip

    # Audio Applications
    pavucontrol mpv yt-dlp emacs-nox

    # Media/Fonts
    terminus_font dejavu_fonts liberation_ttf noto-fonts-cjk-sans
  ];
}
