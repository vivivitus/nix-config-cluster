{ ... }: {

  imports = [
    ./networking
    ../common/global
    ../common/global/hardware/cm3588plus.nix
    ../common/networking
    ../common/user/vivian
    ./k3s.nix
  ];
  system.stateVersion = "25.05";
}
