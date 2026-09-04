{

  # hide raid volumes in nautilus
  services.udev.extraRules = ''
    ENV{ID_SERIAL}=="ST5000LM000-2U8170_WCJC4KQB", ENV{UDISKS_IGNORE}="1"
    ENV{ID_SERIAL}=="ST5000LM000-2U8170_WCJC3SG9", ENV{UDISKS_IGNORE}="1"
    ENV{ID_SERIAL}=="ST5000LM000-2AN170_WCJ1SKQJ", ENV{UDISKS_IGNORE}="1"
  '';

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9ba30658-dba5-40b6-8126-04220245fe91";
    fsType = "btrfs";
    options = [
      "subvol=root"
      "compress=zstd:1"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7D01-47E4";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/9ba30658-dba5-40b6-8126-04220245fe91";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/9ba30658-dba5-40b6-8126-04220245fe91";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/9ba30658-dba5-40b6-8126-04220245fe91";
    fsType = "btrfs";
    options = [ "subvol=swap" ];
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32 * 1024;
    }
  ];

  fileSystems."/home/vivian/Archive" = {
    device = "/dev/sdb";
    fsType = "btrfs";
    options = [
      "noatime"
      "compress-force=zstd:5"
    ];
  };
}
