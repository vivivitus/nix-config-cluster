{ pkgs, ... }:

{
  programs.wireshark = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    wireshark
    linssid
    nmap
    traceroute
    wavemon
  ];
}
