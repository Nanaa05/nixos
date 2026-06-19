{ pkgs, lib, ... }:
let 
  env = import ../env.nix;
in {
  imports  = [
    ../gpu.nix
  ];
  
  services.picom.enable = true;
  
  systemd.user.services.picom = {
    after = [ "default.target" "x11-setup.service" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Environment = lib.mkForce [ "DISPLAY=:0" ];
      ExecStartPre = "${pkgs.writeShellScript "set-120hz" ''
        MONITOR=$(${pkgs.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/cut -d ' ' -f1)

        # TODO: Dynamic Hz Max
        ${pkgs.xrandr}/bin/xrandr --output $MONITOR --mode ${env.resFHD} --rate ${env.hzMax}
      ''}";
      ExecStart = lib.mkForce "${pkgs.picom}/bin/picom --config /etc/nixos/dotfiles/picom.conf";
    };
  };
}
  
