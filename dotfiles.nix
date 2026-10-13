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
  home.file.".emacs.d/early-init.el".text =
    let res = builtins.filter builtins.isString (builtins.split "x" env.resFHD);
    in ''
    ;;; early-init.el -*- lexical-binding: t -*-
    (add-to-list 'default-frame-alist '(alpha-background . 75))
    ;; the first frame is created before ~/.emacs runs, so give it the theme's colours now:
    ;; otherwise it opens white, then turns black when the theme loads
    (add-to-list 'default-frame-alist '(background-color . "#000000"))
    (add-to-list 'default-frame-alist '(foreground-color . "#cdd6f4"))
    (setq frame-inhibit-implied-resize t)
    ;; Emacs is the window manager, so nothing maximizes its first frame: it sat small at the
    ;; top left until EXWM started. Create it screen-sized. initial-frame-alist = first frame
    ;; only, later frames (emacsclient -c) keep the normal size.
    (dolist (p '((left . 0) (top . 0)
                 (width . (text-pixels . ${builtins.elemAt res 0}))
                 (height . (text-pixels . ${builtins.elemAt res 1}))
                 (internal-border-width . 0)
                 (menu-bar-lines . 0) (tool-bar-lines . 0)
                 (vertical-scroll-bars) (horizontal-scroll-bars)))
      (add-to-list 'initial-frame-alist p))
    ;; load-theme costs ~0.4 s once a graphical frame exists (every face is realized on it).
    ;; With no frame yet it only records the face specs. ~/.emacs skips its own load when the
    ;; theme is already on. Graphical X sessions only: emacs -nw keeps its terminal faces.
    (when (and (getenv "DISPLAY") (not (member "-nw" command-line-args)))
      (when-let* ((lib (locate-library "catppuccin-theme")))
        (add-to-list 'custom-theme-load-path (file-name-directory lib))
        (setq catppuccin-flavor 'mocha)
        (load-theme 'catppuccin t)))
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
