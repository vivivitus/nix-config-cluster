{
  imports = [
    ../common/global
    ../common/features/gui
    ../common/features/social
    ../common/features/work/vscode.nix
  ];

  home.stateVersion = "26.05";

  programs.ssh.settings."github.com".IdentityFile = "/home/vivian/.ssh/vivian@sopinian";
}
