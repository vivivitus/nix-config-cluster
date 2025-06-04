{ ... }: {

  imports = [
    ./hardware-configuration.nix
    ./networking
    ../common/global
    ../common/user/vivian
  ];

  services.k3s.serverAddr = "https://192.168.1.190:6443";
  system.stateVersion = "25.05";
}
