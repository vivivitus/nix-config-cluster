{
  networking.hostName = "seniorbook";
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
