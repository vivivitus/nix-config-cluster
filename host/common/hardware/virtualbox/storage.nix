{ lib, ... }:

{
  disko.imageBuilder.extraRootModules = [ "btrfs" ];
  disko.devices.disk.virtualbox = {
    type = "disk";
    device = "/dev/sda";
    imageSize = "16G";

    content = {
      type = "gpt";

      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };

        root = {
          size = "100%";
          priority = 2;

          content = {
            type = "btrfs";
            extraArgs = [
              "-L"
              "root"
            ];

            subvolumes = {
              "/boot" = {
                mountpoint = "/boot";
              };

              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "compress=zstd"
                  "commit=120"
                  "noatime"
                  "nodiratime"
                ];
              };

              "/home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "commit=120"
                  "noatime"
                  "nodiratime"
                ];
              };

              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "commit=120"
                  "noatime"
                  "nodiratime"
                ];
              };

              "/k3s" = {
                mountpoint = "/var/lib/rancher/k3s";
                mountOptions = [
                  "compress=zstd"
                  "commit=120"
                  "noatime"
                  "nodiratime"
                ];
              };

              "/storage0" = {
                mountpoint = "/var/lib/storage0";
                mountOptions = [
                  "noatime"
                  "nodiratime"
                ];
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/" = lib.mkForce {
    device = "none";
    fsType = "tmpfs";

    options = [
      "defaults"
      "size=2G"
      "mode=755"
    ];
  };

  fileSystems."/persist".neededForBoot = true;

  swapDevices = [ ];

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  services.btrfs.autoScrub.enable = true;

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
