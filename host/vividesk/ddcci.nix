{ config, pkgs, ... }:

{
  hardware.i2c.enable = true;

  boot.extraModulePackages = [
    (config.boot.kernelPackages.ddcci-driver.overrideAttrs (oldAttrs: {
      src = pkgs.fetchFromGitLab {
        domain = "gitlab.com";
        owner = "ddcci-driver-linux";
        repo = "ddcci-driver-linux";
        rev = "master";
        sha256 = "sha256-fQjsDjbtFKhs0bUCFfKRgCg516TXdwIkhKEbIISjgs0=";
      };
      postPatch = (oldAttrs.postPatch or "") + ''
        sed -i '1i #include <string.h>' ddcci/ddcci.c
      '';
    }))
  ];

  # boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.kernelModules = [
    "i2c-dev"
  ];

  #environment.systemPackages = [ pkgs.ddcutil ];

  # systemd.services.ddcci-bind = {
  #   description = "Bind DDCCI to I2C buses for Acer monitors";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "systemd-modules-load.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     sleep 2
  #     if [ -e /sys/bus/i2c/devices/i2c-2/new_device ]; then
  #       echo "ddcci 0x37" > /sys/bus/i2c/devices/i2c-2/new_device || true
  #     fi
  #     if [ -e /sys/bus/i2c/devices/i2c-3/new_device ]; then
  #       echo "ddcci 0x37" > /sys/bus/i2c/devices/i2c-3/new_device || true
  #     fi
  #   '';
  # };
}
