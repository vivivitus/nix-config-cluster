{
  networking = {
    hostName = "n2";
    useDHCP = false;

    interfaces.enP4p65s0 = {
      ipv4.addresses = [{
        address = "10.0.2.51";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "2a02:168:5bab:1::51"; 
        prefixLength = 64;
      }];
    };

    defaultGateway = {
      address = "10.0.2.1";
      interface = "enP4p65s0";
    };
    defaultGateway6 = {
      address = "2a02:168:5bab:1::1"; 
      interface = "enP4p65s0";
    };

    nameservers = [ 
      "10.1.2.1"
      "2a02:168:5bab:1::1"
    ];
  };
}
