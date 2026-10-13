{ pkgs, ... }:
let
  mk = import ../lib/controls.nix pkgs;
  conf = "/home/lynaten/nixos/dotfiles/picom.conf";

  # picom has no runtime option for blur strength, so this edits the blur block of the
  # config it already reads and restarts it. 0 = blur off (method "none").
  blurControls = mk {
    name = "blur";
    alias = "blr";
    label = "Blur";
    hint = "<0-20>";
    max = 20;
    unit = "";
    get = ''
      if grep -q '^method = "none";' ${conf}; then
        echo 0
      else
        ${pkgs.gawk}/bin/awk -F'[ ;=]+' '/^strength =/ { print $2 }' ${conf}
      fi
    '';
    set = ''
      if [ "$VALUE" -eq 0 ]; then
        ${pkgs.gnused}/bin/sed -i 's/^method = .*/method = "none";/' ${conf}
      else
        ${pkgs.gnused}/bin/sed -i -e 's/^method = .*/method = "dual_kawase";/' \
                                  -e "s/^strength = .*/strength = $VALUE;/" ${conf}
      fi
      # detached in its own session, same reason as `opa`: M-! blocks Emacs while we run, and a
      # plain background job dies with the s-& prompt's shell
      ${pkgs.util-linux}/bin/setsid -f ${pkgs.systemd}/bin/systemctl --user restart picom </dev/null >/dev/null 2>&1
    '';
  };
in
{
  environment.systemPackages = [ blurControls ];
}
