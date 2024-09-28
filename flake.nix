{
  description = "Srid's NixOS / nix-darwin configuration";

  inputs = {
    # Principle inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-flake.url = "github:srid/nixos-flake";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    ragenix.url = "github:yaxitech/ragenix";
    nuenv.url = "github:hallettj/nuenv/writeShellApplication";

    # Software inputs
    github-nix-ci.url = "github:juspay/github-nix-ci";
    nixos-vscode-server.flake = false;
    nixos-vscode-server.url = "github:nix-community/nixos-vscode-server";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    actualism-app.url = "github:srid/actualism-app";
    omnix.url = "github:juspay/omnix";

    # Neovim
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # Devshell
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.nixos-flake.flakeModule
        inputs.nixos-flake.flakeModule
        ./users
        ./home
        ./nixos
        ./nix-darwin
        ./flake-parts
      ];


      perSystem = { self', inputs', pkgs, system, config, ... }: {
        # My Ubuntu VM
        legacyPackages.homeConfigurations."srid@ubuntu" =
          self.nixos-flake.lib.mkHomeConfiguration pkgs {
            imports = [
              self.homeModules.common-linux
            ];
            home.username = "srid";
            home.homeDirectory = "/home/srid";
          };

        # Flake inputs we want to update periodically
        # Run: `nix run .#update`.
        nixos-flake = {
          primary-inputs = [
            "nixpkgs"
            "home-manager"
            "nix-darwin"
            "nixos-flake"
            "nix-index-database"
            "nixvim"
            "omnix"
          ];
        };

        treefmt.config = {
          projectRootFile = "flake.nix";
          programs.nixpkgs-fmt.enable = true;
        };

        packages.default = self'.packages.activate;

        devShells.default = pkgs.mkShell {
          name = "nixos-config-shell";
          meta.description = "Dev environment for nixos-config";
          inputsFrom = [ config.treefmt.build.devShell ];
          packages = with pkgs; [
            just
            colmena
            nixd
            inputs'.ragenix.packages.default
          ];
        };
        # Make our overlay available to the devShell
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.nuenv.overlays.default
            (import ./packages/overlay.nix { inherit system; flake = { inherit inputs; }; })
          ];
        };
      };
    };
}
