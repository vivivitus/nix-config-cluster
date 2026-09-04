{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.resolved = {
    enable = true;
    dnssec = "false";
    settings.Resolve.DNSOverTLS = false;
  };

  services.openssh = {
    enable = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "vivibook";
  };

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openvpn ];
  };

  networking.firewall.checkReversePath = "loose";

  networking.firewall.trustedInterfaces = [ "viviland" ];
  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.allowedTCPPorts = [ 22 ];

  networking.firewall = {
    # if packets are still dropped, they will show up in dmesg
    logReversePathDrops = true;
    # wireguard trips rpfilter up
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    '';
  };
}
