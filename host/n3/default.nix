{ ... }: {

  imports = [
    ./hardware-configuration.nix
    ./networking
    ../common/global
    ../common/networking
    ../common/user/vivian

    ./k3s.nix
  ];

  system.stateVersion = "25.05";
}
