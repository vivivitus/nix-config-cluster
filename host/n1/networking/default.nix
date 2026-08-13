{ hostName, ipv4Address, ipv6Address, interface, ... }:

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
      address = "10.0.2.1";
      interface = interface;
    };
    defaultGateway6 = {
      address = "2a02:168:5bab:2::1"; 
      interface = interface;
    };

    nameservers = [ 
      "10.1.2.1"
      "2a02:168:5bab:2::1"
    ];
  };
}