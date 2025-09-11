{ ... }:

{
  programs.git = {
    enable = true;
    userName  = "vivivitus";
    userEmail = "vivi_vitus@hotmail.com";
  };

  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github.com-nix-config-cluster" = {
      hostname = "github.com";
      identityFile = "/home/vivian/.ssh/vivian@cluster-node";
    };
  };
}
