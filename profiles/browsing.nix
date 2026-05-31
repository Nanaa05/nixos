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
    openssl
    spotify-player
    
    xinit xrandr xset xinput xkbcomp
    dmenu picom feh xwallpaper maim xclip xdotool wl-clipboard
    brightnessctl pcmanfm htop tmux fastfetch zip

    pavucontrol mpv yt-dlp emacs-nox

    terminus_font dejavu_fonts liberation_ttf noto-fonts-cjk-sans    
  ];
}
