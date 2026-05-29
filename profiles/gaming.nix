{ pkgs, ... }: {
  imports = [ ./browsing.nix ];

  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    lutris heroic mangohud discord
  ];
}
