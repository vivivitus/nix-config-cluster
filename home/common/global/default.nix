{
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [
    ./cli.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  programs = {
    bash.enable = true;
    home-manager.enable = true;
  };

  manual.manpages.enable = false;

  home = {
    username = lib.mkDefault "vivian";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "25.05";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      KUBECONFIG = "${config.home.homeDirectory}/.kube/config";
    };
  };
}
