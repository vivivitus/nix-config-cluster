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

  virtualisation.vmVariant.virtualisation.memorySize = 3072;
  virtualisation.diskSize = 10000;

  boot = {
    # ohne das failed der build mit efi
    bootspec.enable = false;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        installDeviceTree = true;
      };

      efi = {
        canTouchEfiVariables = false;
      };
    };

    # kernelParams = [
    #   "console=ttyS0,115200"
    #   "rd.systemd.log_level=debug"
    #   "rd.systemd.log_target=console"
    # ];

    kernelModules = [ "btrfs" ];
    initrd.kernelModules = [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
