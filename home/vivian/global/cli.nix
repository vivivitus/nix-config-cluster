{ pkgs, ... }: {

  programs = {
    bash = {
      enable = true;
      initExtra = "cd $HOME/nix-config-cluster";
    };
    k9s = {
      enable = true;
      };
  };

  home.packages = with pkgs; [
    ncdu
    git
    nano
    wget
    age
    sops
    lm_sensors
    vulnix
  ];
}
