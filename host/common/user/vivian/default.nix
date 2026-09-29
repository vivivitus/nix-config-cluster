{
  pkgs,
  config,
  clusterTarget,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [ (import ../kubeconfig-service.nix { username = "vivian"; }) ];

  sops.secrets.password-vivian.neededForUsers = true;
  users.mutableUsers = false;

  users.users.vivian = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.password-vivian.path;
    extraGroups = [
      "wheel"
    ]
    ++ ifTheyExist [ ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPqON/KlzvnuEAi2DknZm1PL7ypcGAqC7q6Pwr8DJyI vivian@vividesk-2021-12-10"
    ];
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.alex = import ../../../../home/user/vivian/${clusterTarget}.nix;
}
