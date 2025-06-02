{ pkgs, config, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.alex = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ] ++ ifTheyExist [ ];

    openssh.authorizedKeys.keys = [  ];
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.alex = import ../../../../home/alex/${config.networking.hostName}.nix;
}