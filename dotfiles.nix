{ pkgs, env, currentHz, config, ... }:
{
  home.stateVersion = "24.05";

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-gtk;
    extraPackages = epkgs: with epkgs; [ 
      xclip
      exwm
      catppuccin-theme
      vterm
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
      lua-mode
      nim-mode
      glsl-mode
      cmake-mode
      agent-shell
      svelte-mode
      graphviz-dot-mode
      csv-mode
      pdf-tools
    ];
  };

  services.emacs.enable = true;

  # home.file.".emacs".text = builtins.readFile ./dotfiles/.emacs;
  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider = {
      openrouter.options.apiKey = "{file:/run/secrets/openrouter-api-key}";
      kilo = {
        npm = "@ai-sdk/openai-compatible";
        name = "Kilo Gateway";
        options = {
          baseURL = "https://api.kilo.ai/api/gateway";
          apiKey = "{file:/run/secrets/kilo-api-key}";
        };
        models = {
          "kilo-auto/free".name = "Kilo Auto Free";
        };
      };
    };
    model = "openrouter/openrouter/free";
  };
  home.file.".emacs".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/dotfiles/.emacs";
  home.file.".xinitrc" = {
    executable = true;
    text = builtins.readFile ./dotfiles/.xinitrc;
  };
  # EXWM: the window-manager Emacs (started by ~/.xinitrc) loads this after ~/.emacs
  home.file.".config/emacs-exwm.el".text = import ./dotfiles/exwm.nix { inherit env; };
  # the first frame must be created transparent (ARGB), so set it before ~/.emacs runs
  home.file.".emacs.d/early-init.el".text = ''
    ;;; early-init.el -*- lexical-binding: t -*-
    (add-to-list 'default-frame-alist '(alpha-background . 75))
  '';
  home.file.".config/picom.conf".text = builtins.readFile ./dotfiles/picom.conf;
  home.file.".profile".text = builtins.readFile ./dotfiles/.profile;
  home.file.".tmux.conf".text = builtins.readFile ./dotfiles/.tmux.conf;
  home.file.".config/sxwmrc".text = import ./dotfiles/sxwmrc.nix { inherit env currentHz; };
  home.file.".config/vis".source = ./dotfiles/vis;
  home.file.".local/bin".source = ./dotfiles/bin;
  home.file.".config/spotify-player".source = ./dotfiles/spotify-player;
  home.file.".config/boomer".source = ./dotfiles/boomer;
  home.file.".config/devenv".source = ./dotfiles/devenv;
}
