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

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let env = import ./env.nix;
    in {
      nixosConfigurations = {
        min = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
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
            ./profiles/miracast.nix
            ./profiles/bluetooth.nix
            ./profiles/spotifast.nix
          ] ++ nixpkgs.lib.optional env.hasNvidia ./profiles/no-nvidia.nix ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { currentHz = env.hzMin; inherit env; };
              home-manager.users.lynaten = import ./dotfiles.nix;
            }
          ];
        };
        max = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
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
            ./profiles/max.nix
            ./profiles/bluetooth.nix
            ./profiles/spotifast.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { currentHz = env.hzMax; inherit env; };
              home-manager.users.lynaten = import ./dotfiles.nix;
            }
          ];
        };
      };
    };
}
