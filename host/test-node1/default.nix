{ ... }: {

  imports = [
    ./hardware-configuration.nix
    ./networking
    ../common/global
    ../common/user/vivian
  ];

  services.k3s.clusterInit = true;
  system.stateVersion = "25.05";
}
