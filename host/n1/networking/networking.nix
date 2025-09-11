{lib, ...}:

{
  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "n1";
    domain = "lan";
    resolvconf.dnsExtensionMechanism = false;
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      UseDns = true;
    };
  };

  services.resolved = {
    enable = true;
    dnssec = "false";
    extraConfig = "DNSOverTLS=no";
  };
}