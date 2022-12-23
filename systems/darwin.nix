{ config, pkgs, lib, inputs, system, flake, rosettaPkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    wget
    ripgrep
    sd
    gh
    pandoc
    nodejs # Required for VSCode's webhint extension
    nil
    nixpkgs-fmt
    emanote

    # We must install Agda globally so that Doom-Emacs' agda config can
    # recognize it. It doesn't matter that our projects use Nix/direnv.
    # 
    # Emacs configuration system assumes global state, and is thus shit. We just work with it.
    # https://github.com/hlissner/doom-emacs/blob/f458f9776049fd7e9523318582feed682e7d575c/modules/lang/agda/config.el#L3-L8
    (rosettaPkgs.agda.withPackages (p: [ p.standard-library ]))
    # rosettaPkgs.idris2
    #rosettaPkgs.coq
    # (rosettaPkgs.haskellPackages.callHackage "agda-language-server" "0.2.1" { })

    # Kill the process with the port open
    # Used only to kill stale ghc.
    (pkgs.writeShellApplication {
      name = "fuckport";
      runtimeInputs = [ jc jq ];
      text = ''
        lsof -i :"$1"
        THEPID=$(lsof -i :"$1" | jc --lsof 2> /dev/null | jq '.[].pid')
        echo "KILL $THEPID ?"
        read -r
        kill "$THEPID"
      '';
    })

  ];

  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; # Enables use of `nix-shell -p ...` etc
    registry.nixpkgs.flake = inputs.nixpkgs; # Make `nix shell` etc use pinned nixpkgs
    extraOptions = ''
      extra-platforms = aarch64-darwin x86_64-darwin
      experimental-features = nix-command flakes repl-flake
    '';
    # https://nixos.wiki/wiki/Distributed_build
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "88.198.33.237"; # pinch
        system = "x86_64-linux";
        maxJobs = 10;
      }
    ];
  };
  nixpkgs.config.allowBroken = true;

  security.pam.enableSudoTouchIdAuth = true;

  # For home-manager to work.
  users.users.${flake.config.people.myself} = {
    name = flake.config.people.myself;
    home = "/Users/${flake.config.people.myself}";
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # TODO: use agenix to manage 
  # - secrets
  # - ssh keys
  services.hercules-ci-agent = {
    enable = true;
    # cache push to ssh fix is in master branch only. --Dec 23, 2022
    package = inputs.hci.packages.${system}.hercules-ci-agent;
  };

  # Create /etc/bashrc that loads the nix-darwin environment.
  # programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
