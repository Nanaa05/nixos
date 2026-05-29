{ pkgs, ... }: {
  imports = [ ./browsing.nix ];

  environment.systemPackages = with pkgs; [
    # Compilers & Runtimes
    gnumake gcc clang patch nodejs python3 uv
    
    # Databases & Networking
    mariadb postgresql aria2 nmap openvpn syncthing wrk docker-compose
  ];
}
