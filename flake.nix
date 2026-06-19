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
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
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
          ./profiles/no-nvidia.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
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
