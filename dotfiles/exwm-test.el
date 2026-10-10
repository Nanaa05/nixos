;;; exwm-test.el --- minimal EXWM config for a nested Xephyr test -*- lexical-binding: t -*-
;; Run with:  Xephyr :1 -screen 1280x720 &
;;            DISPLAY=:1 emacs -Q -l ~/nixos/dotfiles/exwm-test.el
;; Nothing here touches the real session or ~/.emacs.

(require 'exwm)

;; GTK emits allocation warnings when EXWM resizes a frame that has bars
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; same look as the real config (emacs -Q skips ~/.emacs)
(add-to-list 'custom-theme-load-path
             (file-name-directory (locate-library "catppuccin-theme")))
(setq catppuccin-flavor 'mocha)
(load-theme 'catppuccin t)
(set-face-background 'default "#000000")

(setq exwm-workspace-number 2)

;; name each X window's buffer after its title
(add-hook 'exwm-update-class-hook
          (lambda () (exwm-workspace-rename-buffer exwm-class-name)))
(add-hook 'exwm-update-title-hook
          (lambda () (exwm-workspace-rename-buffer
                      (format "%s: %s" exwm-class-name exwm-title))))

;; No Super bindings: the host sxwm grabs Super, so the nested Emacs would never see it.
;; Use the normal Emacs keys instead (they already pass through EXWM):
;;   M-&       run a program, e.g. st or firefox
;;   C-x b     switch between Emacs buffers and X windows
;;   C-x 0/1/2/3, C-x o   window commands
;;   M-x exwm-reset       re-tile the current window
;;   C-x C-c   quit this Emacs
;; let M-& start several programs at once, each in its own hidden output buffer
(setq async-shell-command-buffer 'new-buffer)
(add-to-list 'display-buffer-alist
             '("\\*Async Shell Command\\*" (display-buffer-no-window)))
(setq exwm-input-global-keys nil)

(exwm-wm-mode 1)
