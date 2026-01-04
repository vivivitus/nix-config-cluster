{ ... }: {

  imports = [
    ./hardware-configuration.nix
    ./networking
    ../common/global
    ../common/user/vivian
  ];

  system.stateVersion = "25.05";
}
