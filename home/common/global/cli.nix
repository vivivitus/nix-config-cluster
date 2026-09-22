{ pkgs, ... }: {

  programs = {
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
  ];
}
