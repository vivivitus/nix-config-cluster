{
  imports = [
    ../common/global
    ../common/features/gui
  ];

  home.stateVersion = "26.05";

  programs.ssh.settings."github.com".IdentityFile = "/home/vivian/.ssh/vivian@seniorbook";
}