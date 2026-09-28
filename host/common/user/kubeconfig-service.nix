{ username }:
{ config, lib, pkgs, ... }:
let
  user = config.users.users.${username};
  kubeDirectory = "${user.home}/.kube";
  kubeConfig = "${kubeDirectory}/config";
in
{
  systemd.services."kubeconfig-${username}" = {
    description = "Install ${username}'s k3s kubeconfig";
    wantedBy = [ "multi-user.target" ];
    requires = [ "k3s.service" ];
    after = [ "k3s.service" ];
    partOf = [ "k3s.service" ];

    path = [ pkgs.coreutils ];
    serviceConfig.Type = "oneshot";
    script = ''
      install -d -o ${lib.escapeShellArg username} -g ${lib.escapeShellArg user.group} -m 0700 ${lib.escapeShellArg kubeDirectory}
      install -o ${lib.escapeShellArg username} -g ${lib.escapeShellArg user.group} -m 0600 \
        /etc/rancher/k3s/k3s.yaml ${lib.escapeShellArg kubeConfig}
    '';
  };
}
