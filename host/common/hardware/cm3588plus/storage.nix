{ lib, isFallback ? false, ... }:

let
  deviceName = if isFallback then "/dev/mmcblk0" else "/dev/nvme0n1";
  diskKey    = if isFallback then "emmc" else "nvme0";
  rootLabel  = if isFallback then "root_fallback" else "root";
in {
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
            extraArgs = [ "-n" "BOOT" ];
            mountOptions = [ "fmask=0077" "dmask=0077" "noatime" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-L" rootLabel ];
            subvolumes = {
              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [ "compress=zstd" "commit=120" "noatime" "nodiratime" ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "commit=120" "noatime" "nodiratime" ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "commit=120" "noatime" "nodiratime" ];
              };
            }
              # data storage mounten wenn es kein Fallback-System ist
              // lib.optionalAttrs (!isFallback) {
              "/storage0" = {
                mountpoint = "/var/lib/storage0";
                mountOptions = [ "noatime" "nodiratime" ];
              };
            };
          };
        };
      };
    };
  };
}