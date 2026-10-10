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
    '';
  };
in
{
  environment.systemPackages = [ opacityControls ];
}
