{ pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    loader = {
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 5;
        efi.canTouchEfiVariables = true;
    };

    tmp.useTmpfs = true;
    tmp.tmpfsSize = "25%";

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

  services.btrfs.autoScrub = {
    enable = true;
    interval = "daily";
    fileSystems = [ "/" ];
  };

  services.fstrim.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "nodiratime"
      "commit=120"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
}