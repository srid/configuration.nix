{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    # This must be envExtra (rather than initExtra), because doom-emacs requires it
    # https://github.com/doomemacs/doomemacs/issues/687#issuecomment-409889275
    #
    # But also see: 'doom env', which is what works.
    envExtra = ''
      export PATH=/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin/:/usr/local/bin:$PATH
      # For 1Password CLI. This requires `pkgs.gh` to be installed.
      source $HOME/.config/op/plugins.sh
      # Because, adding it in .ssh/config is not enough.
      # cf. https://developer.1password.com/docs/ssh/get-started#step-4-configure-your-ssh-or-git-client
      export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
    '';

    initExtra = ''
      # Show random quote: https://github.com/srid/actual
      ${lib.getExe pkgs.actual}
    '';

    initExtraBeforeCompInit = ''
      # Fix broken autocompletion. See https://github.com/nix-community/home-manager/issues/2562.
      fpath+=("${config.home.profileDirectory}"/share/zsh/site-functions "${config.home.profileDirectory}"/share/zsh/$ZSH_VERSION/functions "${config.home.profileDirectory}"/share/zsh/vendor-completions)
    '';
  };
}
