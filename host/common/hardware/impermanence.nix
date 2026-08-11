{ ... }:

{
  environment.persistence."/persist" = {
    hideMounts = true;
    
    # Einzelne persistente Dateien
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    
    # Persistente Ordner
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd/timers"
      "/var/log"
    ];
  };
}