{ pkgs, ... }: {

  programs.bash = {
    enable = true;
    initExtra = "cd $HOME/nix-config-cluster";
  };

  home.packages = with pkgs; [
    ncdu
    git
    nano
    wget
    age
    sops
    lm_sensors
  ];
}
