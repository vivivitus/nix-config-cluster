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

    # hosts = {
    #   "127.0.0.1" = [ "localhost" hostName ];
    # };
  };

  services.resolved = {
    enable = true;
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

  services.fail2ban = {
    enable = true;
    bantime-increment = {
      enable = true;
      maxtime = "24h";
    };
    ignoreIP = [
      "10.0.1.1/24" "2a02:168:5bab:1::1/64"
      "10.0.10.1/24" "2a02:168:5bab:10::1/64"
    ];
  };
}