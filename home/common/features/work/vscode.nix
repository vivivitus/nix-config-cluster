{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nixfmt
    statix
    deadnix
    nixd
  ];

  # programs.vscode.package = pkgs.vscode.fhsWithPackages (ps: with ps; [
  #   openocd
  #   gcc-arm-embedded
  # ]);

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      ms-python.python
      ms-vscode-remote.remote-ssh
    ];
  };
}
