{ pkgs, ... }: {
  imports = [
    ./hidpi.nix
    ./swap-caps-ctrl.nix
    ./light-terminal.nix
    ./screencapture.nix
  ];
}
