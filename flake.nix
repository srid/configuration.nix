{
  description = "Srid's NixOS configuration";

  inputs = {
    # Principle inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Supportive inputs
    flake-utils.url = "github:numtide/flake-utils";
    nixos-shell.url = "github:Mic92/nixos-shell";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Software inputs
    nixos-vscode-server.url = "github:msteen/nixos-vscode-server";
    nixos-vscode-server.flake = false;
    hercules-ci-agent.url = "github:hercules-ci/hercules-ci-agent/master";
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";
    emanote.url = "github:EmaApps/emanote";

    # Vim & its plugins (not in nixpkgs)
    zk-nvim.url = "github:mickael-menu/zk-nvim";
    zk-nvim.flake = false;
    coc-rust-analyzer.url = "github:fannheyward/coc-rust-analyzer";
    coc-rust-analyzer.flake = false;
  };

  outputs = inputs@{ self, home-manager, nixpkgs, darwin, ... }:
    let
      userName = "srid";
      platformIndependentModules = [
        ./nixos/caches
      ];
    in
    {
      # Configurations for Linux (NixOS) systems
      nixosConfigurations =
        let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
          # Configuration common to all Linux systems
          commonFeatures = platformIndependentModules ++ [
            ./nixos/self-ide.nix
            ./nixos/takemessh
            ./nixos/current-location.nix
          ];
          homeFeatures = [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit system inputs; };
              home-manager.users.${userName} = { pkgs, ... }: {
                imports = [
                  ./home/tmux.nix
                  (import ./home/git.nix {
                    userName = "Sridhar Ratnakumar";
                    userEmail = "srid@srid.ca";
                  })
                  ./home/neovim.nix
                  ./home/starship.nix
                  ./home/terminal.nix
                  ./home/direnv.nix
                  ./home/vscode-server.nix
                ];

                programs.bash = {
                  enable = true;
                } // (import ./home/shellcommon.nix { inherit pkgs; });
                home.stateVersion = "22.11";
              };
              home-manager.users."uday" = {
                imports = [
                  ./home/tmux.nix
                  (import ./home/git.nix {
                    userName = "Uday Kiran";
                    userEmail = "udaycruise2903@gmail.com";
                  })
                  ./home/neovim.nix
                  ./home/starship.nix
                  ./home/terminal.nix
                  ./home/direnv.nix
                  ./home/vscode-server.nix
                ];
                programs.bash.enable = true;
                home.stateVersion = "22.11";
              };
            }
          ];
          mkLinuxSystem = extraModules: nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            # Arguments to pass to all modules.
            specialArgs = { inherit system inputs; };
            modules =
              commonFeatures ++ homeFeatures ++ extraModules;
          };
        in
        {
          # My Linux development computer (on Hetzner)
          pinch = mkLinuxSystem
            [
              ./systems/hetzner/ax41.nix
              ./nixos/server/harden.nix
            ];

          # For downloading stuff off internet in VPN.
          #
          # This is run in qemu only, which is useful to keep the host machine
          # directly connected to the network (for acccess from outside).
          #
          # > nixos-shell --flake github:srid/nixos-config#corsair
          corsair = pkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            specialArgs = { inherit system inputs; };
            modules = [
              inputs.nixos-shell.nixosModules.nixos-shell
              {
                virtualisation = {
                  memorySize = 8 * 1024;
                  cores = 2;
                  diskSize = 20 * 1024;
                };
                environment.systemPackages = with pkgs; [
                  protonvpn-cli
                  aria2
                ];
                nixos-shell.mounts = {
                  mountHome = false;
                  mountNixProfile = false;
                  extraMounts."/Downloads" = {
                    target = "/home/${userName}/Downloads";
                    cache = "none";
                  };
                };
              }
            ];
          };
        };

      # Configurations for macOS systems (using nix-darwin)
      darwinConfigurations =
        let
          system = "aarch64-darwin";
          mkMacosSystem = darwin.lib.darwinSystem;
          defaultMacosSystem = mkMacosSystem {
            inherit system;
            specialArgs = {
              inherit inputs system;
              rosettaPkgs = import nixpkgs { system = "x86_64-darwin"; };
            };
            modules = platformIndependentModules ++ [
              ./systems/darwin.nix
              home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = { inherit system inputs; };
                home-manager.users.${userName} = { pkgs, ... }: {
                  imports = [
                    ./home/git.nix
                    ./home/tmux.nix
                    ./home/neovim.nix
                    ./home/email.nix
                    ./home/terminal.nix
                    ./home/emacs.nix
                    ./home/direnv.nix
                    ./home/starship.nix
                  ];
                  programs.zsh = {
                    enable = true;
                    initExtra = ''
                      export PATH=/etc/profiles/per-user/${userName}/bin:/run/current-system/sw/bin/:$PATH
                    '';
                  } // (import ./home/shellcommon.nix { inherit pkgs; });
                  home.stateVersion = "21.11";
                };
              }
            ];
          };
        in
        {
          default = defaultMacosSystem;
        };
    } //
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
            # To enable webhint to analyze source files
            nodejs
          ];
        };
        formatter = pkgs.nixpkgs-fmt;
        apps.default =
          let
            # Create a flake app that wraps the given bash CLI.
            bashCmdApp = name: cmd: {
              type = "app";
              program =
                (pkgs.writeShellApplication {
                  inherit name;
                  text = ''
                    set -x
                    ${cmd}
                  '';
                }) + "/bin/${name}";
            };
          in
          if system == "aarch64-darwin" then
            bashCmdApp "darwin" ''
              ${self.darwinConfigurations.default.system}/sw/bin/darwin-rebuild \
                 switch --flake ${self}#default
            ''
          else
            bashCmdApp "linux" ''
              nixos-rebuild --use-remote-sudo switch -j auto
            '';
      }
    );

}
