{ ... }: {

  imports = [
    ../common/global
    ../common/hardware/cm3588plus
    ../common/user/vivian
    ../common/user/root
    ./k3s.nix
  ];

  system.stateVersion = "25.05";
}
