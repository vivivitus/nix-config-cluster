{ lib, pkgs, config, ... }:

{
  imports = [
    ./cli.nix
    ./git.nix
    ./vscode.nix
  ];

  home.file.".kube/config".source = config.lib.file.mkOutOfStoreSymlink "/etc/rancher/k3s/k3s.yaml";

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  programs = {
    home-manager.enable = true;
  };

  manual.manpages.enable = false;

  home = {
    username = lib.mkDefault "vivian";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "25.05";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      FLAKE = "$HOME/nix-config-cluster";
    };
  };
}
