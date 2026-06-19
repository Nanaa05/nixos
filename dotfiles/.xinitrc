#!/bin/sh
exec sxwm

# if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
#     eval $(dbus-launch --sh-syntax --exit-with-session)
# fi

# systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR

# export ENV="$HOME/.profile"
# export XCURSOR_THEME="Bibata-Modern-Ice"
# export XCURSOR_SIZE="24"

# setxkbmap -option caps:escape &

# xrandr --output eDP --mode 1920x1080 --rate 120
# xsetroot -cursor_name left_ptr &

# xset r rate 300 50 &
# xset s off -dpms &

# exec sxwm
