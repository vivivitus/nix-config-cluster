{
  imports = [
    ../common/global
    ../common/features/gui
    ../common/features/work
    ../common/features/social
    ../common/features/virtualisation/virt-manager.nix
    ../common/features/cli/ssh/rothstrasse.nix
  ];

  home.stateVersion = "24.05";

  programs.ssh.settings."github.com".IdentityFile = "/home/vivian/.ssh/vivian@vividesk";
}
