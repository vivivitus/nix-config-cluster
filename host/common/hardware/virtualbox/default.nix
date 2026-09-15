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
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };
}
