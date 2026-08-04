{ pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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

  services.btrfs.autoScrub.enable = false;
  services.fstrim = {
    enable = true;
    interval = "weekly"; 
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = [
      "subvol=persist"
      "compress=zstd"
      "commit=120"
      "noatime"
      "nodiratime"
    ];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd"
      "commit=120"
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/root";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd"
      "commit=120"
      "noatime"
      "nodiratime"
      "ro"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" "noatime" ];
  };

  fileSystems."/var/lib/nixos" = {
    device = "/persist/var/lib/nixos";
    fsType = "none";
    options = [ "bind" ];
  };

  swapDevices = [ ];
}