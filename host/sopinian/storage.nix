{
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6a3b3fb5-d4e3-4e77-99da-35f51579e28d";
    fsType = "btrfs";
    options = [
      "subvol=root"
      "compress=zstd:1"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/6a3b3fb5-d4e3-4e77-99da-35f51579e28d";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/6a3b3fb5-d4e3-4e77-99da-35f51579e28d";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3D63-BC06";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];
}
