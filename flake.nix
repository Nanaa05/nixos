{
  description = "Lynaten's Multi-State NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sxwm-src = {
      url = "github:uint23/sxwm";
      flake = false;
    };

    st-src = {
      url = "git+https://git.suckless.org/st?ref=refs/tags/0.8.5";
      flake = false;
    };

    spotifast = {
      url = "github:crmne/spotifast";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      env = import ./env.nix;
      mkSystem = { currentHz, extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            ({ ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  stdenv = prev.stdenv // { lib = prev.lib; };
                })
                (import ./dotfiles/overlay-boomer/default.nix)
              ];
            })

            ./configuration.nix
            ./profiles/min.nix
            ./profiles/sound.nix
          ] ++ extraModules
            ++ nixpkgs.lib.optional env.hasNvidia ./profiles/no-nvidia.nix
            ++ [
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.extraSpecialArgs = { inherit currentHz env; };
                home-manager.users.lynaten = import ./dotfiles.nix;
              }
            ];
        };
      connectedModules = [
        ./profiles/internet.nix
        ./profiles/bluetooth.nix
        ./profiles/miracast.nix
        ./profiles/spotifast.nix
      ];
    in {
      nixosConfigurations = {
        save = mkSystem {
          currentHz = env.hzMin;
          extraModules = [ ./profiles/power-save.nix ];
        };
        min = mkSystem {
          currentHz = env.hzMin;
          extraModules = connectedModules;
        };
        max = mkSystem {
          currentHz = env.hzMax;
          extraModules = connectedModules ++ [ ./profiles/max.nix ];
        };
      };
    };
}
