{ hostName, ipv4Address, ipv6Address, ipv4Gateway, ipv6Gateway, ipv4Nameserver, ipv6Nameserver, interface, ... }:

{
  networking = {
    inherit hostName;
    useDHCP = false;

    interfaces.${interface} = {
      ipv4.addresses = [{
        address = ipv4Address;
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = ipv6Address; 
        prefixLength = 64;
      }];
    };

    defaultGateway = {
      address = ipv4Gateway;
      interface = interface;
    };
    defaultGateway6 = {
      address = ipv6Gateway; 
      interface = interface;
    };

    nameservers = [ 
      ipv4Nameserver
      ipv6Nameserver
    ];
  };

  services.openssh = {
    enable = true;
    generateHostKeys = false;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      UseDns = true;
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  services.resolved = {
    enable = true;
  };
}