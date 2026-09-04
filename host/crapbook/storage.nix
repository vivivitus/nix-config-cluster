{ ... }:

{
  # imports =
  #   [ (modulesPath + "/installer/scan/not-detected.nix")
  #   ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a2aa52a9-13ef-45a3-8711-8e0755772aa9";
    fsType = "btrfs";
    options = [
      "subvol=root"
      "compress=zstd:1"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a2aa52a9-13ef-45a3-8711-8e0755772aa9";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/a2aa52a9-13ef-45a3-8711-8e0755772aa9";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd:1"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/a2aa52a9-13ef-45a3-8711-8e0755772aa9";
    fsType = "btrfs";
    options = [ "subvol=swap" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9F35-B859";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/swap/swapfile"; } ];
}
