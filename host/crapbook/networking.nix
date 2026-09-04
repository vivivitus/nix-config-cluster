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
    extraConfig = "DNSOverTLS=no";
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "crapbook";
  };

  networking.firewall.allowedUDPPorts = [
    53
    51821
  ];
  networking.firewall.allowedTCPPorts = [
    53
    51821
  ];

  networking.firewall = {
    # if packets are still dropped, they will show up in dmesg
    logReversePathDrops = true;

    checkReversePath = "loose";
    # wireguard trips rpfilter up
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51821 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51821 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51821 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51821 -j RETURN || true
    '';
  };
}
