{ ... }:

{
  networking = {
    dhcpcd.wait = "both";
    nameservers = [ "10.0.1.1" "2a02:168:5bab:1::1" ];
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