{ pkgs, ... }: {
  imports = [
    ./bash.nix
    ./git.nix
  ];
  home.packages = with pkgs; [
    ncdu
    tree
    usbutils
    libusb1
    pciutils
    pmbootstrap
    appimage-run
    gnumake
    rkdeveloptool
    libusb1
    fido2-manage
    #exfat
    exfatprogs
    nix-tree
    kubectl
    sops
    age
  ];
}