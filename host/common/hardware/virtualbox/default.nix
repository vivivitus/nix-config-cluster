{
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ./storage.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/virtualisation/virtualbox-image.nix")
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };
}
