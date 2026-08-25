{
  imports = [
    ../common/global
    ../common/features/gui
    ../common/features/social
    ../common/features/work
  ];

  home.stateVersion = "24.05";

  programs.ssh.settings."github.com".IdentityFile = "/home/vivian/.ssh/vivian@crapbook";
}