{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kicad
    kicadAddons.kikit-library
    kikit
    easyeda2kicad
  ];
}