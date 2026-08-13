{ pkgs, modulesPath, ... }:

{
  imports = [
    ./storage.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    loader = {
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 5;
        efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "nvme" ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  hardware = {
    deviceTree = {
        enable = true;
        name = "rockchip/rk3588-friendlyelec-cm3588-nas.dtb";
    };
  };
}