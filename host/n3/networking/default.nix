{
  networking = {
    hostName = "n3";
    useDHCP = false;

    interfaces.eth0 = {
      ipv4.addresses = [{
        address = "10.0.2.52";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "2a02:168:5bab:1::52"; 
        prefixLength = 64;
      }];
    };

    defaultGateway = {
      address = "10.0.2.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2a02:168:5bab:1::1"; 
      interface = "eth0";
    };

    nameservers = [ 
      "10.1.2.1"
      "2a02:168:5bab:1::1"
    ];
  };
}
