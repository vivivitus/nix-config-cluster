{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user  = {
        name = "vivivitus";
    	  email = "vivi_vitus@hotmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.matchBlocks = {
    "github.com-nix-config-cluster" = {
      hostname = "github.com";
      identityFile = "/home/vivian/.ssh/vivian@cluster-node";
    };
  };
}
