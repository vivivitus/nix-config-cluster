{ pkgs, ... }:

{
  imports = [
    ./firefox.nix
    ./gnome.nix
  ];

  home.packages = with pkgs; [
    easyeffects
    gparted
    spotify
    vlc
    #exodus #can not be automatically installed
  ];
}
