#!/bin/sh
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

FILENAME="$HOME/Pictures/Screenshots/shot_$(date +%Y-%m-%d_%H-%M-%S).png"

maim -s | tee "$FILENAME" | xclip -selection clipboard -t image/png
