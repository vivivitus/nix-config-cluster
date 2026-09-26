{ config, pkgs, ... }:

{
  hardware.i2c.enable = true;

  boot.extraModulePackages = [
    config.boot.kernelPackages.ddcci-driver
  ];

  boot.kernelModules = [
    "i2c-dev"
    "ddcci"
    "ddcci_backlight"
  ];

  environment.systemPackages = [
    pkgs.ddcutil
    pkgs.brightnessctl
  ];

  systemd.services.ddcci-bind = {
    description = "Bind DDCCI to I2C buses";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      sleep 5
      echo "ddcci 0x37" > /sys/bus/i2c/devices/i2c-2/new_device || true
      echo "ddcci 0x37" > /sys/bus/i2c/devices/i2c-3/new_device || true
    '';
  };
}
