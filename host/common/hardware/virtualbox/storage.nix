{ lib, ... }:

{
  disko.imageBuilder.extraRootModules = [
    "btrfs"
  ];

  disko.devices.disk.virtualbox = {
    type = "disk";
    device = "/dev/sda";
    imageSize = "16G";

    content = {
      type = "gpt";

      partitions = {
        esp = {
          size = "512M";
          type = "EF00";

          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "umask=0077"
            ];
          };
        };

        root = {
          size = "100%";

          content = {
            type = "btrfs";

            extraArgs = [
              "-L"
              "root"
            ];

            subvolumes = {
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
