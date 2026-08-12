{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1";
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
                extraArgs = [ "-L" "root0" ];
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
    };
  };
}