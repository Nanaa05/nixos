#!/bin/sh
export XDG_RUNTIME_DIR="$HOME/.local/run"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

export ENV="$HOME/.profile"
export XCURSOR_THEME="Bibata-Modern-Ice"
export XCURSOR_SIZE="24"

xsetroot -cursor_name left_ptr &

xset r rate 300 50 &
xset s off -dpms &

picom -b &

xwallpaper --zoom /etc/nixos/wallpaper.jpg &

pipewire &
pipewire-pulse &
wireplumber &

exec sxwm
