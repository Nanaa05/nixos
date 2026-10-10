{ pkgs, ... }:
let
  mk = import ../lib/controls.nix pkgs;

  opacityControls = mk {
    name = "opacity";
    alias = "opa";
    label = "Opacity";
    get = ''
      VAL="$(${pkgs.xprop}/bin/xprop -root OPACITY_VALUE 2>/dev/null | ${pkgs.gawk}/bin/awk -F' = ' 'NF > 1 { print $2 }')"
      [ -n "$VAL" ] || VAL="$(${pkgs.xprop}/bin/xprop -root GLOBAL_OPACITY 2>/dev/null | ${pkgs.gawk}/bin/awk -F' = ' 'NF > 1 { print $2 }')"
      if [ -n "$VAL" ]; then
        echo "$VAL%"
      else
        echo "unset"
      fi
    '';
    set = ''
      # the value you asked for, as reported by `opa`
      ${pkgs.xprop}/bin/xprop -root -f OPACITY_VALUE 32c -set OPACITY_VALUE "$VALUE"
      # st sits on top of an Emacs frame under EXWM, so its own alpha would stack on the
      # frame's: keep st fully transparent there and let the Emacs frame carry the opacity
      if [ -S "/run/user/$(id -u)/emacs/exwm" ]; then ST_VALUE=0; else ST_VALUE="$VALUE"; fi
      ${pkgs.xprop}/bin/xprop -root -f GLOBAL_OPACITY 32c -set GLOBAL_OPACITY "$ST_VALUE"
      # detached in its own session: (1) from M-! Emacs is blocked waiting for us and cannot
      # answer emacsclient, so a foreground call would deadlock; (2) from the s-& prompt the
      # command gets a pty, and a plain background job is killed when its shell exits
      ${pkgs.util-linux}/bin/setsid -f ${pkgs.coreutils}/bin/timeout 5 ${pkgs.emacs-gtk}/bin/emacsclient --eval "(progn (dolist (f (frame-list)) (when (display-graphic-p f) (set-frame-parameter f 'alpha-background $VALUE))) (add-to-list 'default-frame-alist '(alpha-background . $VALUE)))" </dev/null >/dev/null 2>&1
      ${pkgs.util-linux}/bin/setsid -f ${pkgs.coreutils}/bin/timeout 5 ${pkgs.emacs-gtk}/bin/emacsclient -s exwm --eval "(progn (dolist (f (frame-list)) (when (display-graphic-p f) (set-frame-parameter f 'alpha-background $VALUE))) (add-to-list 'default-frame-alist '(alpha-background . $VALUE)))" </dev/null >/dev/null 2>&1
    '';
  };
in
{
  environment.systemPackages = [ opacityControls ];
}
