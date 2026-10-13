{ pkgs, lib, ... }:
let 
  env = import ../env.nix;
in {
  imports  = [
    ../gpu.nix
    ../logger.nix # TEMPORARY, see logger.nix
  ];
  
  services.picom.enable = true;
  
  systemd.user.services.picom = {
    after = [ "x11-setup.service" ];
    # started by ~/.xinitrc once x11-setup is done: at login X is not up yet, so picom failed
    # and systemd retried 3 s later, after Emacs had already opened without a compositor
    wantedBy = lib.mkForce [ ];

    serviceConfig = {
      Environment = lib.mkForce [ "DISPLAY=:0" ];
      # the 120 Hz modeset moved into x11-setup (profiles/min.nix): doing it here as well meant
      # a second modeset right as Emacs opened, which blanked the screen
      ExecStart = lib.mkForce "${pkgs.picom}/bin/picom --config /home/lynaten/nixos/dotfiles/picom.conf";
    };
  };
}
