{ ... }: {

  imports = [
    ../common/global
    ../common/hardware/cm3588plus
    ../common/user/vivian
    ./k3s.nix
  ];

  system.stateVersion = "25.05";
  boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ]; # mögliche fehlerbehebung bei n2... power states
}
