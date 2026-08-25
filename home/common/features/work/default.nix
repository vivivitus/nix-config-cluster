{ pkgs, ... }:

{
  imports = [
    ./evolution.nix
    ./vscode.nix
    ./3d-printing.nix
    ./kicad.nix
  ];

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  home.packages = with pkgs; [
    #rpi-imager
    #rpiboot
    pdfarranger
    #gnucash
    gmsh
    darktable
    gimp
    inkscape
    mono
    picoscope
    picocom
    libredwg
    # gnucash
    stm32cubemx
    stlink-tool
    stlink-gui
    libreoffice
  ];
}