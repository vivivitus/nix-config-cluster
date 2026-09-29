{
  pkgs,
  config,
  admins,
  clusterTarget,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [ (import ../kubeconfig-service.nix { username = "alex"; }) ];

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
      admins.alex.sshAuthorizedKey
    ];
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.alex = import ../../../../home/user/alex/${clusterTarget}.nix;
}
