{ ... }: {

  imports = [
    ../n1/networking
    ../common/global
    ../common/hardware/cm3588plus.nix
    ../common/hardware/disko-fallback.nix
    ../common/hardware/impermanence.nix
    ../common/networking
    ../common/user/vivian
  ];

  system.stateVersion = "25.05";
}
