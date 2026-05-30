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

  # Compile ST from source with the Alpha patch applied and transparency configured
  my-st = pkgs.st.overrideAttrs (oldAttrs: {
    src = inputs.st-src;

    patches = [
      (pkgs.fetchurl {
        url = "https://st.suckless.org/patches/alpha/st-alpha-20220206-0.8.5.diff";
        # The exact hash expected by the Nix compiler
        hash = "sha256-QuSAPOKmeDX35TOnB6iijjgEomztFjFFEIlwua7l+4E=";
      })
    ];

    # Post-patch script to force background opacity and perfect DejaVu text spacing
    postPatch = oldAttrs.postPatch or "" + ''
      sed -i 's/alpha = .*/alpha = 0.4;/g' config.def.h
      sed -i 's/Liberation Mono:pixelsize=12/DejaVu Sans Mono:pixelsize=26/g' config.def.h
      sed -i 's/{ TERMMOD,             XK_Prior,       zoom,           {.f = +1} },/{ ControlMask,            XK_equal,        zoom,           {.f = +1} },/g' config.def.h
      sed -i 's/{ TERMMOD,             XK_Next,        zoom,           {.f = -1} },/{ ControlMask,            XK_minus,       zoom,           {.f = -1} },/g' config.def.h
    '';
  });

in {
  environment.systemPackages = with pkgs; [
    my-sxwm
    my-st
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
  
	# services.picom = {
  #   enable = true;
  # };
}
