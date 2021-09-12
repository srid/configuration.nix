{
  description = "Srid's NixOS configuration";

  inputs = {
    # To update nixpkgs (and thus NixOS), pick the nixos-unstable rev from
    # https://status.nixos.org/
    # 
    # This ensures that we always use the official nix cache.
    nixpkgs.url = "github:nixos/nixpkgs/4f6d8095fd51954120a1d08ea5896fe42dc3923b";

    nixos-hardware.url = github:NixOS/nixos-hardware/master;
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    himalaya.url = "github:soywod/himalaya";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-doom-emacs.url = "github:vlaci/nix-doom-emacs";
    emanote.url = "github:srid/emanote";
  };

  outputs = inputs@{ self, home-manager, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      # Make configuration for any computer I use in my home office.
      mkHomeMachine = bare: configurationNix: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        # Arguments to pass to all modules.
        specialArgs = { inherit system inputs; };
        modules = (
          [
            # System configuration
            configurationNix

            # common
            ./features/self-ide.nix
            ./features/takemessh
            ./features/caches
            ./features/current-location.nix
            ./features/passwordstore.nix
            ./features/protonvpn.nix
            ./features/server/harden.nix

            # home-manager configuration
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.srid = import ./home.nix {
                inherit inputs system bare;
                pkgs = import nixpkgs { inherit system; };
              };
            }
          ] ++ extraModules
        );
      };
    in
    {
      # The "name" in nixosConfigurations.${name} should match the `hostname`
      # 
      nixosConfigurations.p71 = mkHomeMachine
        false
        ./hosts/p71.nix
        [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p53
          ./features/desktopish
          #./features/gnome.nix
          ./features/desktopish/guiapps.nix
          ./features/server/devserver.nix
          ./features/ema/emanote.nix
          #./features/virtualbox.nix
          ./features/lxd.nix
          #./features/server-mode.nix
          # ./features/postgrest.nix
          ./features/server/devserver.nix
        ];
      nixosConfigurations.x1c7 = mkHomeMachine
        ./hosts/x1c7.nix
        [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
          ./features/distributed-build.nix
          ./features/gnome.nix
          ./features/desktopish/guiapps.nix
        ];
      nixosConfigurations.facade = mkHomeMachine
        true
        ./hosts/facade.nix
        [
        ];

      # non-NixOS systems
      homeConfigurations =
        let
          username = "srid";
        in
        {
          "${username}@P71" = home-manager.lib.homeManagerConfiguration {
            configuration = { pkgs, ... }: {
              programs.home-manager.enable = true;
              home.packages = [ pkgs.tig ];
            };

            inherit username;
            system = "x86_64-linux";
            homeDirectory = "/home/${username}";
            stateVersion = "21.05";
          };
        };
    };

}
