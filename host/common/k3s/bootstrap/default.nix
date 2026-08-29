{
  imports = [
    ./k3s-bootstrap-phase1.nix
    ./k3s-bootstrap-phase2.nix
  ];

  sops.secrets = {
    cluster-deploy-key = {
      path = "/etc/ssh/cluster-deploy-key";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    gitlab-vault-token = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    gitlab-argocd-token = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
