{
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ./storage.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        installDeviceTree = true;
      };
    };

    # Auf einem Gerät (n2) führte der stromsparmodus zu problemen
    kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "nvme" ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  # Support für den onboard SPI-Chip auf der Rückseite des Boards (W25Q128JVSIQ)
  hardware.deviceTree = {
    enable = true;
    name = "rockchip/rk3588-friendlyelec-cm3588-nas.dtb";

    overlays = [
      {
        name = "enable-cm3588-spi-nor";

        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "friendlyarm,cm3588-nas";
          };

          &sfc {
            status = "okay";

            pinctrl-names = "default";
            pinctrl-0 = <&fspim1_pins>;

            flash@0 {
              compatible = "jedec,spi-nor";
              reg = <0>;
              spi-max-frequency = <50000000>;
            };
          };
        '';
      }
    ];
  };
}
