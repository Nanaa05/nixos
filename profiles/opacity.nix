{ pkgs, ... }:
let
  mk = import ../lib/controls.nix pkgs;

  opacityControls = mk {
    name = "opacity";
    alias = "opa";
    label = "Opacity";
    get = ''
      VAL="$(${pkgs.xprop}/bin/xprop -root GLOBAL_OPACITY 2>/dev/null | ${pkgs.gawk}/bin/awk -F' = ' 'NF > 1 { print $2 }')"
      if [ -n "$VAL" ]; then
        echo "$VAL%"
      else
        echo "unset"
      fi
    '';
    set = ''
      ${pkgs.xprop}/bin/xprop -root -f GLOBAL_OPACITY 32c -set GLOBAL_OPACITY "$VALUE"
      # detached: when opa is run from Emacs (M-!), Emacs is blocked waiting for us and
      # cannot answer emacsclient, so a foreground call would deadlock
      ( ${pkgs.coreutils}/bin/timeout 5 ${pkgs.emacs-gtk}/bin/emacsclient --eval "(progn (dolist (f (frame-list)) (when (display-graphic-p f) (set-frame-parameter f 'alpha-background $VALUE))) (add-to-list 'default-frame-alist '(alpha-background . $VALUE)))" ) </dev/null >/dev/null 2>&1 &
    '';
  };
in
{
  environment.systemPackages = [ opacityControls ];
}
