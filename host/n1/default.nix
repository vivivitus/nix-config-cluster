{ ... }: {

  imports = [
    ./networking
    ../common/global
    ../common/hardware/cm3588plus.nix
    ../common/hardware/disko.nix
    ../common/hardware/impermanence.nix
    ../common/networking
    ../common/user/vivian
    ./k3s.nix
  ];

  system.stateVersion = "25.05";
}
