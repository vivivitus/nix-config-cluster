{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [ brlaser ];
  };

  environment.systemPackages = with pkgs; [
    brlaser
    foomatic-db
    foomatic-db-ppds-withNonfreeDb
    foomatic-db-ppds
  ];

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_DCP-7065DN_IPP";
        location = "Home";
        deviceUri = "ipp://10.0.1.30";
        model = "drv:///brlaser.drv/br7065d.ppd";
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
        };
      }
      {
        name = "Brother_DCP-7065DN_DNSSD";
        location = "Home";
        deviceUri = "dnssd://Brother%20DCP-7065DN._pdl-datastream._tcp.local/";
        model = "drv:///brlaser.drv/br7065d.ppd";
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
        };
      }
      {
        name = "Brother_DCP-7065DN_LPD";
        location = "Home";
        deviceUri = "lpd://10.0.1.30//BINARY_P1";
        model = "drv:///brlaser.drv/br7065d.ppd";
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
        };
      }
    ];
  };

  hardware = {
    sane = {
      enable = true;
      brscan4 = {
        enable = true;
        netDevices = {
          DCP-7065DN = {
            model = "DCP-7065DN";
            ip = "10.0.1.30";
          };
        };
      };
    };
  };
}
