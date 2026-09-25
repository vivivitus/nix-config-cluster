{
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ./storage.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    #(modulesPath + "/virtualisation/virtualbox-image.nix")
  ];

  virtualisation.vmVariant.virtualisation.memorySize = 3072;
  virtualisation.diskSize = 10000;

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };

    kernelModules = [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
