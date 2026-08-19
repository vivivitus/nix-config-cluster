{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "vivivitus";
        email = "vivi_vitus@hotmail.com";
      };

      init.defaultBranch = "main";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com-nix-config-cluster" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "/home/vivian/.ssh/vivian@cluster-node";
        IdentitiesOnly = true;
      };
    };
  };
}