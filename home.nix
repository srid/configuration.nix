# HACK: bare
{ bare ? false, pkgs, inputs, system, ... }:
let
  #himalayaSrc = inputs.himalaya;
  #himalaya = import ./features/email/himalaya.nix { inherit pkgs inputs system; };
  neovim-nightly = inputs.neovim-nightly-overlay.packages.${system}.neovim;
in
rec {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "srid";
  home.homeDirectory = "/home/srid";

  #imports = pkgs.lib.optional (!bare)
  #  inputs.nix-doom-emacs.hmModule;

  home.packages = with pkgs; lib.optionals (!bare) [
    gnumake
    cachix
    tig
    gh
    procs # no more: ps -ef | grep 
    tealdeer
    zellij
    unzip
    dust
    ripgrep
    htop
    bottom # htop alternative
    fzf
    aria2
    # ^ easy to forget these; write SRS?

    hledger
    hledger-web

    # latex
    # texlive.combined.scheme-full
  ];

  programs = {
    git = {
      # package = pkgs.gitAndTools.gitFull;
      enable = true;
      userName = "Sridhar Ratnakumar";
      userEmail = "srid@srid.ca";
      aliases = {
        co = "checkout";
        ci = "commit";
        cia = "commit --amend";
        s = "status";
        st = "status";
        b = "branch";
        p = "pull --rebase";
        pu = "push";
      };
      ignores = [ "*~" "*.swp" ];
      extraConfig = {
        init.defaultBranch = "master";
        #core.editor = "nvim";
        #protocol.keybase.allow = "always";
        credential.helper = "store --file ~/.git-credentials";
        pull.rebase = "false";
      };
    };

    tmux = {
      enable = true;
      shortcut = "a";
      aggressiveResize = true;
      baseIndex = 1;
      newSession = true;
      # Stop tmux+escape craziness.
      escapeTime = 0;
      # Force tmux to use /tmp for sockets (WSL2 compat)
      secureSocket = false;

      extraConfig = ''
        # Mouse works as expected
        set-option -g mouse on
        # easy-to-remember split pane commands
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"
      '';
    };

    #doom-emacs = {
    #  enable = false;
    #  doomPrivateDir = ./config/doom.d;
    #};

    neovim = {
      enable = !bare;
      package = neovim-nightly;
      viAlias = true;
      # withNodeJs = true;

      extraPackages = [
        # himalaya
      ];

      plugins = with pkgs.vimPlugins; [
        vim-airline
        papercolor-theme

        #(pkgs.vimUtils.buildVimPlugin {
        #  name = "himalaya";
        #  src = himalayaSrc + "/vim";
        #})
      ];

      extraConfig = ''
        " papercolor-theme
        " set t_Co=256   " This is may or may not needed.
        set background=light
        colorscheme PaperColor
      '';
    };

    bash = {
      enable = true;
      shellAliases = {
        g = "${pkgs.git}/bin/git";
        t = "${pkgs.tig}/bin/tig";
        l = "${pkgs.exa}/bin/exa";
        ll = "${pkgs.exa}/bin/exa -l";
        ls = "l";
        #h = "himalaya";
      };
      sessionVariables = { };
      bashrcExtra = ''
        . ~/.nix-profile/etc/profile.d/nix.sh
        export PATH=$HOME/.nix-profile/bin:$PATH
      '';
    };

    starship =
      {
        enable = true;
        settings = {
          username = {
            format = "[$user](bold blue) ";
            disabled = false;
            show_always = true;
          };
          hostname = {
            ssh_only = false;
            format = "on [$hostname](bold red) ";
            trim_at = ".companyname.com";
            disabled = false;
          };
        };
      };

    bat.enable = true;
    autojump.enable = false;
    zoxide.enable = true;
    fzf.enable = true;
    jq.enable = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      #"p71" = {
      #  hostname = "192.168.2.76";
      #};
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  # home.stateVersion = "21.03";
}
