{ pkgs, ... }: {
  home.stateVersion = "24.05";

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
    extraPackages = epkgs: with epkgs; [ 
      xclip
      magit
      web-mode
      rust-mode
      go-mode
      php-mode
      yaml-mode
      markdown-mode
      typescript-mode
      kotlin-mode
      dockerfile-mode
      cuda-mode
      jtsx
      ewal
      nix-mode
      company
    ];
  };

  home.file.".emacs".text = builtins.readFile ./dotfiles/.emacs;

  home.file.".xinitrc" = {
    executable = true;
    text = builtins.readFile ./dotfiles/.xinitrc;
  };

  home.file.".config/picom.conf".text = builtins.readFile ./dotfiles/picom.conf;
  
  home.file.".profile".text = builtins.readFile ./dotfiles/.profile;

  home.file.".tmux.conf".text = builtins.readFile ./dotfiles/.tmux.conf;

  home.file.".config/sxwmrc".text = builtins.readFile ./dotfiles/sxwmrc;
}
