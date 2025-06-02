{ pkgs, config, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.vivian = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ] ++ ifTheyExist [ ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPqON/KlzvnuEAi2DknZm1PL7ypcGAqC7q6Pwr8DJyI vivian@vividesk-2021-12-10"
    ];
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.vivian = import ../../../../home/vivian/${config.networking.hostName}.nix;
}