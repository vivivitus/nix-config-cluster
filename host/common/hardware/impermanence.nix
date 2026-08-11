{ ... }:

{
  environment.persistence."/persist" = {
    hideMounts = true;
    
    # Einzelne persistente Dateien
    files = [
      "/etc/machine-id"
    ];
    
    # Persistente Ordner
    directories = [
      "/etc/ssh"
      "/var/lib/nixos"
      "/var/lib/systemd/timers"
      "/var/log"
    ];
  };
}