{ inputs, outputs, config, ... }:

{
  sops.secrets = {
    cluster-token = {
      owner = config.users.users.root.name;
      group = config.users.users.root.name;
    };
  };

  services.k3s = {
    enable = true;
    role = "server";
    token = config.sops.secrets.cluster-token.path;
    clusterInit = true;
  };
}