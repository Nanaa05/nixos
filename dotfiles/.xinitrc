#!/bin/sh
systemctl --user start x11-setup.service
# compositor before the window manager, so the first frame is already composited
# (no picom unit on the min profile: ignore the error)
systemctl --user start picom.service 2>/dev/null

# Window manager: EXWM (Emacs) by default.  WM=sxwm startx  gives the old sxwm session.
# If Emacs/EXWM dies within 20 seconds (broken config), fall back to sxwm instead of a dead screen.
if [ "${WM:-exwm}" = exwm ]; then
    start=$(date +%s)
    /etc/profiles/per-user/lynaten/bin/emacs -l "$HOME/.config/emacs-exwm.el"
    [ $(( $(date +%s) - start )) -ge 20 ] && exit 0
fi

exec sxwm
