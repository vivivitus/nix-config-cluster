{ lib, config, ... }:

let
  isFallback = config._module.args.isFallback or false;
  deviceName = if isFallback then "/dev/mmcblk0" else "/dev/nvme0n1";
  diskKey = if isFallback then "emmc" else "nvme0";
  rootLabel = if isFallback then "root_fallback" else "root";
in
{
  disko.devices.disk.${diskKey} = {
    type = "disk";
    device = deviceName;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            extraArgs = [
              "-n"
              "BOOT"
            ];
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
              "noatime"
            ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-L"
              rootLabel
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
            }
            // lib.optionalAttrs (!isFallback) {
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

  fileSystems."/" = {
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

  services.btrfs.autoScrub.enable = true;
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
