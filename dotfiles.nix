{ pkgs, ... }: {
  home.stateVersion = "24.05";

  # ==========================================
  # .emacs
  # ==========================================
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
    extraPackages = epkgs: [ 
      epkgs.xclip
      epkgs.magit
      epkgs.web-mode
      epkgs.rust-mode
      epkgs.go-mode
      epkgs.php-mode
      epkgs.yaml-mode
      epkgs.markdown-mode
      epkgs.typescript-mode
      epkgs.kotlin-mode
      epkgs.dockerfile-mode
      epkgs.cuda-mode
      epkgs.jtsx
      epkgs.ewal
      epkgs.nix-mode
      epkgs.company
    ];
  };

  # ==========================================
  # The Full, Fixed .emacs Initialization file
  # ==========================================
  home.file.".emacs".text = ''
    ;;; -*- lexical-binding: t -*-

    (require 'package)
    (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
    (package-initialize)

    ;; X11 Clipboard configuration hooks
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

    (global-display-line-numbers-mode 1)
    (setq display-line-numbers-type 'visual)
    (setq display-line-numbers-current-absolute t)

    (tooltip-mode -1)
    (setq ring-bell-function 'ignore)
    (setq initial-scratch-message "")

    (delete-selection-mode t)

    (global-unset-key (kbd "C-z"))
    (global-set-key (kbd "C-x C-z") 'suspend-frame)

    (defvar my-keys-minor-mode-map
      (let ((map (make-sparse-keymap)))
        (define-key map (kbd "C-q") 'delete-backward-char)
        (define-key map (kbd "M-q") 'backward-kill-word)
        map)
      "Keymap for my-keys-minor-mode.")

    (define-minor-mode my-keys-minor-mode
      "This string is REQUIRED by Emacs, do not delete it."
      :init-value t
      :lighter " my-keys"
      :global t)

    (my-keys-minor-mode 1)
    (custom-set-variables
     '(send-mail-function 'mailclient-send-it)
     '(warning-suppress-log-types '((native-compiler))))
    (custom-set-faces
     )

    ;; Language major mode bindings
    (add-to-list 'auto-mode-alist '("\\.jsx\\'" . web-mode))
    (add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
    (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
    (add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode))
    (add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode))
  '';

  # ==========================================
  # .xinitrc (Using the local configuration asset)
  # ==========================================
  home.file.".xinitrc" = {
    executable = true;
    text = ''
      #!/bin/sh
      export XDG_RUNTIME_DIR="$HOME/.local/run"
      mkdir -p "$XDG_RUNTIME_DIR"
      chmod 700 "$XDG_RUNTIME_DIR"

      xset r rate 300 50 &
      xset s off -dpms &

      picom -b &
      
      # Target the local hardware file copy
      xwallpaper --zoom /etc/nixos/wallpaper.jpg &

      pipewire &
      pipewire-pulse &
      wireplumber &

      exec sxwm
    '';
  };

  # ==========================================
  # Picom Blur Engine Configuration
  # ==========================================
home.file.".config/picom.conf".text = ''
    # Performance Backend
    backend = "glx";
    glx-copy-from-front = false;

    # Opacity settings
    active-opacity = 1.0;
    inactive-opacity = 1.0;
    frame-opacity = 1.0;

    # Hardware-accelerated Dual-Kawase blur
    blur: {
      method = "dual_kawase";
      strength = 6;
      background = true;
      background-frame = false;
      background-fixed = false;
    };

    # Explicitly enforce blurring rule on suckless terminal classes
    blur-background-exclude = [
      "window_type = 'desktop'",
      "_GTK_FRAME_EXTENTS@"
    ];

    wintypes: {
      tooltip = { fade = true; shadow = true; opacity = 0.75; focus = true; full-shadow = false; };
      dock = { shadow = false; clip-shadow-above = true; }
      dnd = { shadow = false; }
      popup_menu = { opacity = 1.0; }
      dropdown_menu = { opacity = 1.0; }
    };
  ''; 
  # ==========================================
  # .profile
  # ==========================================
  home.file.".profile".text = ''
    if [ -z "$XDG_RUNTIME_DIR" ]; then
        export XDG_RUNTIME_DIR=/tmp/run-$(id -u)
        if [ ! -d "$XDG_RUNTIME_DIR" ]; then
            mkdir -p "$XDG_RUNTIME_DIR"
            chmod 700 "$XDG_RUNTIME_DIR"
        fi
    fi

    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        startx
    fi

    export LANG=en_US.UTF-8
    alias doas='sudo'
  '';

  # ==========================================
  # .tmux.conf
  # ==========================================
  home.file.".tmux.conf".text = ''
    set-window-option -g mode-keys vi
    bind-key -T copy-mode-vi v send-keys -X begin-selection
    bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
  '';

  # ==========================================
  # .config/sxwmrc
  # ==========================================
  home.file.".config/sxwmrc".text = ''
    focused_border_colour    : #31827f
    unfocused_border_colour  : #000000
    swap_border_colour       : #eeeeee

    gaps                    : 30
    border_width            : 2
    master_width            : 50
    resize_master_amount    : 1
    resize_stack_amount     : 20
    move_window_amount      : 50
    resize_window_amount    : 50
    snap_distance           : 5
    motion_throttle         : 60
    should_float            : "pcmanfm", "obs"
    new_win_focus           : true
    warp_cursor             : true
    floating_on_top         : true
    new_win_master          : false
    can_swallow             : "st"
    can_be_swallowed        : "mpv", "sxiv"
    start_fullscreen        : "mpv", "vlc"

    mod_key : super

    bind : mod + Return : "st"
    bind : mod + e : "pcmanfm"
    bind : mod + b : "qutebrowser"
    bind : mod + alt + b : "dillo"
    bind : mod + shift + b : "st -e w3m"
    bind : mod + space : "dmenu_run"

    call : mod + shift + q : close_window
    call : mod + c : centre_window
    call : mod + shift + e : quit
    call : mod + m : toggle_monocle

    call : mod + j : focus_next
    call : mod + k : focus_prev
    call : mod + comma : focus_prev_mon
    call : mod + period : focus_next_mon
    call : mod + shift + comma : move_prev_mon
    call : mod + shift + period : move_next_mon

    call : mod + shift + j : master_next
    call : mod + shift + k : master_prev

    call : mod + l : master_increase
    call : mod + h : master_decrease
    call : mod + ctrl + l : stack_increase
    call : mod + ctrl + h : stack_decrease

    call : mod + Up : move_win_up
    call : mod + Down : move_win_down
    call : mod + Left : move_win_left
    call : mod + Right : move_win_right

    call : mod + shift + Up : resize_win_up
    call : mod + shift + Down : resize_win_down
    call : mod + shift + Left : resize_win_left
    call : mod + shift + Right : resize_win_right

    call : mod + equal : increase_gaps
    call : mod + minus : decrease_gaps

    call : mod + p : toggle_floating
    call : mod + shift + p : global_floating
    call : mod + shift + f : fullscreen
    call : mod + r : reload_config

    scratchpad : mod + alt + 1 : create 1
    scratchpad : mod + alt + 2 : create 2
    scratchpad : mod + alt + 3 : create 3
    scratchpad : mod + alt + 4 : create 4

    scratchpad : mod + ctrl + 1 : toggle 1
    scratchpad : mod + ctrl + 2 : toggle 2
    scratchpad : mod + ctrl + 3 : toggle 3
    scratchpad : mod + ctrl + 4 : toggle 4

    scratchpad : mod + alt + shift + 1 : remove 1
    scratchpad : mod + alt + shift + 2 : remove 2
    scratchpad : mod + alt + shift + 3 : remove 3
    scratchpad : mod + alt + shift + 4 : remove 4

    workspace : mod + 1          : move 1
    workspace : mod + shift + 1  : swap 1
    workspace : mod + 2          : move 2
    workspace : mod + shift + 2  : swap 2
    workspace : mod + 3          : move 3
    workspace : mod + shift + 3  : swap 3
    workspace : mod + 4          : move 4
    workspace : mod + shift + 4  : swap 4
    workspace : mod + 5          : move 5
    workspace : mod + shift + 5  : swap 5
    workspace : mod + 6          : move 6
    workspace : mod + shift + 6  : swap 6
    workspace : mod + 7          : move 7
    workspace : mod + shift + 7  : swap 7
    workspace : mod + 8          : move 8
    workspace : mod + shift + 8  : swap 8
    workspace : mod + 9          : move 9
    workspace : mod + shift + 9  : swap 9
  '';

  # ==========================================
  # .config/glib-2.0/settings/keyfile
  # ==========================================
  home.file.".config/glib-2.0/settings/keyfile".text = ''
    [org/gtk/settings/file-chooser]
    window-position=(398, 129)
    window-size=(1124, 822)
    date-format='regular'
    location-mode='path-bar'
    show-hidden=false
    show-size-column=true
    show-type-column=true
    sidebar-width=156
    sort-column='name'
    sort-directories-first=false
    sort-order='ascending'
    type-format='category'
  '';

  # ==========================================
  # .config/htop/htoprc
  # ==========================================
  home.file.".config/htop/htoprc".text = ''
    htop_version=3.4.1-3.4.1
    config_reader_min_version=3
    fields=0 48 17 18 38 39 40 2 46 47 49 1
    hide_kernel_threads=1
    hide_userland_threads=0
    hide_running_in_container=0
    shadow_other_users=0
    show_thread_names=0
    show_program_path=1
    highlight_base_name=0
    highlight_deleted_exe=1
    shadow_distribution_path_prefix=0
    highlight_megabytes=1
    highlight_threads=1
    highlight_changes=0
    highlight_changes_delay_secs=5
    find_comm_in_cmdline=1
    strip_exe_from_cmdline=1
    show_merged_command=0
    header_margin=1
    screen_tabs=1
    detailed_cpu_time=0
    cpu_count_from_one=0
    show_cpu_usage=1
    show_cpu_frequency=0
    show_cpu_temperature=0
    degree_fahrenheit=0
    show_cached_memory=1
    update_process_names=0
    account_guest_in_cpu_meter=0
    color_scheme=0
    enable_mouse=1
    delay=15
    hide_function_bar=0
    header_layout=two_50_50
    column_meters_0=LeftCPUs2 Memory Swap
    column_meter_modes_0=1 1 1
    column_meters_1=RightCPUs2 Tasks LoadAverage Uptime
    column_meter_modes_1=1 2 2 2
    tree_view=0
    sort_key=47
    tree_sort_key=0
    sort_direction=-1
    tree_sort_direction=1
    tree_view_always_by_pid=0
    all_branches_collapsed=0
    screen:Main=PID USER PRIORITY NICE M_VIRT M_RESIDENT M_SHARE STATE PERCENT_CPU PERCENT_MEM TIME Command
    .sort_key=PERCENT_MEM
    .tree_sort_key=PID
    .tree_view_always_by_pid=0
    .tree_view=0
    .sort_direction=-1
    .tree_sort_direction=1
    .all_branches_collapsed=0
    screen:I/O=PID USER IO_PRIORITY IO_RATE IO_READ_RATE IO_WRITE_RATE Command
    .sort_key=IO_RATE
    .tree_sort_key=PID
    .tree_view_always_by_pid=0
    .tree_view=0
    .sort_direction=-1
    .tree_sort_direction=1
    .all_branches_collapsed=0
  '';
}
