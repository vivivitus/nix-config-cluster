{ pkgs, ... }:

{
  #programs.thunderbird.enable = true;
  home.packages = with pkgs; [
    evolutionWithPlugins
    birdtray
  ];
}