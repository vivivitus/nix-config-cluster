{ modulesPath, ... }:

{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/28d7c556-9a6e-447a-bd22-bf284320b217";
    fsType = "btrfs";
    options = [ "subvol=root" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/28d7c556-9a6e-447a-bd22-bf284320b217";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd:1"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/28d7c556-9a6e-447a-bd22-bf284320b217";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/28d7c556-9a6e-447a-bd22-bf284320b217";
    fsType = "btrfs";
    options = [ "subvol=swap" ];
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 2 * 1024;
    }
  ];
}
