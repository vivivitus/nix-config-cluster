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
      admins.vivian.sshAuthorizedKey
    ];
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.vivian = import ../../../../home/user/vivian/${clusterTarget}.nix;
}
