;;; -*- lexical-binding: t -*-

(with-eval-after-load 'xclip
  (setq xclip-method 'xclip)
  (setq xclip-program "xclip"))

(require 'xclip)
(xclip-mode 1)

(setq inhibit-startup-message t)
(menu-bar-mode -1)

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))

(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(when (fboundp 'fringe-mode)
  (fringe-mode 0))

;; a reload must also switch off a global mode left on by an older config
(when (bound-and-true-p global-display-line-numbers-mode)
  (global-display-line-numbers-mode -1))
;; show no-break spaces (U+00A0, used by Claude Code's prompt) as normal spaces, not underlined
(setq nobreak-char-display nil)
(setq display-line-numbers-type 'visual)
(setq display-line-numbers-current-absolute t)

;; Line numbers only in programming, text, and config files
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

;; Explicitly off in dired, terminals, and compilation
(dolist (hook '(dired-mode-hook
                term-mode-hook
                vterm-mode-hook
                shell-mode-hook
                eshell-mode-hook
                compilation-mode-hook
                special-mode-hook))
  (add-hook hook (lambda ()
                   (setq display-line-numbers nil)
                   (display-line-numbers-mode -1))))

(tooltip-mode -1)
(setq ring-bell-function 'ignore)
(setq initial-scratch-message "")

(delete-selection-mode t)
(setq-default truncate-lines t)

(global-unset-key (kbd "C-z"))
(global-set-key (kbd "C-x C-z") 'suspend-frame)

(defvar custom-keys-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-q") 'delete-backward-char)
    (define-key map (kbd "M-q") 'backward-kill-word)
    map)
  "Keymap for custom-keys-minor-mode.")

(define-minor-mode custom-keys-minor-mode
  "This string is REQUIRED by Emacs, do not delete it."
  :init-value t
  :lighter " custom-keys"
  :global t)

(custom-keys-minor-mode 1)
(custom-set-variables
 '(send-mail-function 'mailclient-send-it)
 '(warning-suppress-log-types '((native-compiler))))
(custom-set-faces
 )

(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

;; PDFs open inside Emacs (pdf-tools; its epdfinfo server is built by Nix). RET in dired opens
;; them in a pdf-view buffer, so no browser window gets involved. Keys: n/p page, SPC scroll,
;; + / - zoom, C-s search, q bury.
;; the Nix-built package is on load-path but not package-activated, so load its autoloads
(when (load "pdf-tools-autoloads" t t)
  (pdf-loader-install))

(defun nix-reload-packages ()
  "Pick up packages from the latest rebuild without restarting Emacs."
  (interactive)
  (let* ((bin (file-truename (executable-find "emacs")))
         (wrapper (expand-file-name ".emacs-wrapped" (file-name-directory bin))))
    (unless (file-readable-p wrapper)
      (user-error "No wrapper at %s" wrapper))
    (with-temp-buffer
      (insert-file-contents wrapper)
      (if (re-search-forward
           "\\(/nix/store/[^/ ]+-emacs-packages-deps\\)/share/emacs/site-lisp" nil t)
          (let* ((deps (match-string 1))
                 (share (expand-file-name "share/emacs" deps)))
            (load-file (expand-file-name "site-lisp/subdirs.el" share))
            (when (boundp 'native-comp-eln-load-path)
              (add-to-list 'native-comp-eln-load-path
                           (expand-file-name "native-lisp/" share)))
            (message "Loaded packages from %s" deps))
        (user-error "No emacs-packages-deps path in %s" wrapper)))))

(defun reload-config ()
  (interactive)
  (nix-reload-packages)
  (load-file user-init-file)
  ;; the window-manager Emacs also reloads the EXWM config
  (when (and (featurep 'exwm) (bound-and-true-p exwm--connection))
    (load-file (expand-file-name "~/.config/emacs-exwm.el"))
    ;; EXWM only registers global keys at startup; redo it, then grab them for X windows
    (dolist (k exwm-input-global-keys)
      (exwm-input--set-key (car k) (cdr k)))
    (exwm-input--update-global-prefix-keys)
    (exwm-reset)))

;; Language major mode bindings
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode))
(add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode))
(add-to-list 'auto-mode-alist '("sxwmrc\\'" . conf-space-mode))
(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-mode))
(add-to-list 'auto-mode-alist '("\\.mako\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.svelte\\'" . svelte-mode))

(add-to-list 'custom-theme-load-path
             (file-name-directory (locate-library "catppuccin-theme")))

;; Custom face theming for terminal (-nw) mode:
;; Keeps background transparent while giving text/syntax bright, glowing, light colors.
(defun my/apply-nw-theme (&optional frame)
  (let ((target-frame (or frame (selected-frame))))
    (unless (display-graphic-p target-frame)
      ;; terminal mouse reports; without this st sends C-y/C-e for the wheel (= yank)
      (xterm-mouse-mode 1)
      ;; Keep base background completely transparent
      (set-face-background 'default "unspecified-bg" target-frame)
      (set-face-background 'fringe "unspecified-bg" target-frame)
      (set-face-foreground 'default "#cdd6f4" target-frame)
      (set-face-background 'cursor "#f5e0dc" target-frame)
    
    ;; Syntax faces with light, vibrant colors:
    (set-face-foreground 'font-lock-comment-face "#9399b2")       ;; Soft readable grey
    (set-face-foreground 'font-lock-doc-face "#a6adc8")           ;; Light subtext
    (set-face-foreground 'font-lock-string-face "#a6e3a1")        ;; Light green
    (set-face-foreground 'font-lock-keyword-face "#f38ba8")       ;; Light pink/red
    (set-face-foreground 'font-lock-function-name-face "#89b4fa")  ;; Light vivid blue
    (set-face-foreground 'font-lock-variable-name-face "#f9e2af")  ;; Warm light yellow
    (set-face-foreground 'font-lock-type-face "#cba6f7")          ;; Light mauve/purple
    (set-face-foreground 'font-lock-constant-face "#fab387")      ;; Light peach
    (set-face-foreground 'font-lock-builtin-face "#f5c2e7")       ;; Light rose pink
    (set-face-foreground 'font-lock-warning-face "#f38ba8")       ;; Crisp warning red
    
    ;; UI elements:
    (set-face-foreground 'line-number "#6c7086")
    (set-face-foreground 'line-number-current-line "#f5e0dc")
    ;; 181825
    ;; b4befe
    (set-face-background 'region "#737373")                       ;; Darker selection background
    (set-face-foreground 'region nil)
    (set-face-background 'mode-line "#11111b")                    ;; Very dark mode-line
    (set-face-foreground 'mode-line "#cdd6f4")
    (set-face-background 'mode-line-inactive "#000000")           ;; Pure black inactive mode-line
    (set-face-foreground 'mode-line-inactive "#6c7086")
    (set-face-foreground 'minibuffer-prompt "#b4befe")            ;; Light lavender
    (set-face-bold 'minibuffer-prompt t))))

;; Background transparency (text stays opaque); `opa` overrides it at runtime
(defvar my/alpha-background 75)
(add-to-list 'default-frame-alist `(alpha-background . ,my/alpha-background))
(when (display-graphic-p)
  (set-frame-parameter nil 'alpha-background my/alpha-background))

;; Nerd Font icons (private use areas) come from the symbols font
(defun my/setup-icon-fonts ()
  (when (display-graphic-p)
    (dolist (range '((#xe000 . #xf8ff) (#xf0000 . #xffffd)))
      (set-fontset-font t range "Symbols Nerd Font Mono" nil 'prepend))))
(my/setup-icon-fonts) ; also on reload-config from a graphical frame

(defun my/apply-theme (frame)
  (if (display-graphic-p frame)
      (with-selected-frame (or frame (selected-frame))
        (setq catppuccin-flavor 'mocha)
        (load-theme 'catppuccin t)
        ;; Pitch black background instead of Catppuccin dark gray
        (set-face-background 'default "#000000")
        (my/setup-icon-fonts)
        ;; GUI Default Zoom Level (150 = 15pt)
        (set-face-attribute 'default nil :height 200))
    (with-selected-frame (or frame (selected-frame))
      (my/apply-nw-theme frame))))

;; every new frame gets it, not just the first (EXWM and plain emacs make frames too)
(add-hook 'after-make-frame-functions #'my/apply-theme)
(unless (daemonp)
  (my/apply-theme nil))

(autoload 'vterm "vterm" "Open a vterm terminal." t)
(global-set-key (kbd "C-c t") 'vterm)
(setq vterm-min-window-width 10) ; let the terminal shrink to the window so text wraps (default 80 clips it)
;; Mouse wheel in vterm: forward it to a running program (SGR mouse report), like st does,
;; so apps such as Claude Code can scroll themselves. At a bare prompt, or in copy mode
;; (C-c C-t), the wheel scrolls the Emacs buffer as usual.
(defun my/vterm-wheel (up)
  (lambda (event)
    (interactive "e")
    ;; forward only while a program (Claude, less, vim...) runs in the foreground;
    ;; at a bare shell prompt the wheel scrolls the buffer as usual
    (if (or (bound-and-true-p vterm-copy-mode)
            (not (process-running-child-p (get-buffer-process (current-buffer)))))
        (mwheel-scroll event)
      (vterm-send-string (if up "\e[<64;1;1M" "\e[<65;1;1M")))))

(with-eval-after-load 'vterm
  (define-key vterm-mode-map (kbd "<wheel-up>") (my/vterm-wheel t))
  (define-key vterm-mode-map (kbd "<wheel-down>") (my/vterm-wheel nil))
  ;; terminal frames (xterm-mouse-mode) may report the wheel as mouse-4/5
  (define-key vterm-mode-map (kbd "<mouse-4>") (my/vterm-wheel t))
  (define-key vterm-mode-map (kbd "<mouse-5>") (my/vterm-wheel nil)))

;; M-x <control>: commands generated from the manifests lib/controls.nix writes
;; (name, alias, hint). Empty input shows the value, anything else sets it.
(defun my/control-define (name hint)
  (defalias (intern name)
    (lambda (value)
      (interactive (list (read-string (format "%s %s (empty = show): " name hint))))
      (let ((args (unless (string-empty-p value) (list value))))
        (message "%s" (string-trim
                       (with-output-to-string
                         (apply #'call-process name nil standard-output nil args))))))))

(defun my/controls-register ()
  "Define one command per control manifest (name and alias)."
  (interactive)
  (let ((dir "/run/current-system/sw/share/emacs-controls"))
    (when (file-directory-p dir)
      (dolist (file (directory-files dir t "^[^.]"))
        (pcase (with-temp-buffer
                 (insert-file-contents file)
                 (split-string (buffer-string) "\n" t))
          (`(,name ,alias ,hint)
           (my/control-define name hint)
           (my/control-define alias hint)))))))

(my/controls-register)
