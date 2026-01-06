{lib, ...}:

{
  networking = {
    dhcpcd.wait = "both";
    #useDHCP = lib.mkDefault true;
    #domain = "lan";
    nameservers = [ "10.0.1.1" "2a02:168:5bab:1::1" ];
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
  };
}