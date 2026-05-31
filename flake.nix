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

    boomer-src = {
      url = "github:tsoding/boomer";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      browsing = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ({ ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                stdenv = prev.stdenv // { lib = prev.lib; };
              })
              (import "${inputs.boomer-src}/overlay/default.nix")
            ];
          })

          ./configuration.nix
          ./profiles/browsing.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.lynaten = import ./dotfiles.nix;
          }
        ];
      };

      dev = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ({ ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                stdenv = prev.stdenv // { lib = prev.lib; };
              })
              (import "${inputs.boomer-src}/overlay/default.nix")
            ];
          })

          ./configuration.nix
          ./profiles/developer.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.lynaten = import ./dotfiles.nix;
          }
        ];
      };

      gaming = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
           ({ ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                stdenv = prev.stdenv // { lib = prev.lib; };
              })
              (import "${inputs.boomer-src}/overlay/default.nix")
            ];
          })

          ./configuration.nix
          ./profiles/gaming.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.lynaten = import ./dotfiles.nix;
          }
        ];
      };
    };
  };
}
