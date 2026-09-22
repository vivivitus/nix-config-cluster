{ pkgs, config, ... }:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  sops.secrets.password-alex.neededForUsers = true;
  users.mutableUsers = false;

  users.users.alex = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.password-alex.path;
    extraGroups = [
      "wheel"
    ]
    ++ ifTheyExist [ ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFQP/PnJSvUL/5R+yBvNQla6Xw68ThyQ+gXYpYjhwOXD alex@kubernold.ch"
    ];
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.alex = import ../../../../home/user/alex/${config.networking.hostName}.nix;
}
