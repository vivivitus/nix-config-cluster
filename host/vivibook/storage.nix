{
  # imports =
  #   [ (modulesPath + "/installer/scan/not-detected.nix")
  #   ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1fadc7e9-a139-4580-b358-729ecf16d071";
    fsType = "btrfs";
    options = [
      "subvol=root"
      "compress=zstd:1"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/1fadc7e9-a139-4580-b358-729ecf16d071";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/1fadc7e9-a139-4580-b358-729ecf16d071";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/1fadc7e9-a139-4580-b358-729ecf16d071";
    fsType = "btrfs";
    options = [ "subvol=swap" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3D92-08C9";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/swap/swapfile"; } ];
}
