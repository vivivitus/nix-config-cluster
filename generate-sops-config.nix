{
  lib,
  admins,
  hosts,
}:

let
  adminEntries = lib.mapAttrsToList (name: value: {
    inherit name value;
  }) admins;

  hostEntries = lib.mapAttrsToList (name: value: {
    inherit name value;
  }) hosts;

  adminRecipients = map (admin: admin.value.ageRecipient) adminEntries;

  allHostRecipients = map (host: host.value.ageRecipient) hostEntries;

  clusterHosts =
    clusterTarget: builtins.filter (host: host.value.clusterTarget == clusterTarget) hostEntries;

  clusterRecipients =
    clusterTarget:
    adminRecipients
    ++ map (host: host.value.ageRecipient) (
      builtins.filter (
        host: host.value.clusterTarget == clusterTarget && (host.value.clusterBootstrap or false)
      ) hostEntries
    );

  recipientsYaml =
    recipients: builtins.concatStringsSep "\n" (map (recipient: "          - ${recipient}") recipients);

  rule = pathRegex: recipients: ''
      - path_regex: ${pathRegex}
        key_groups:
          - age:
    ${recipientsYaml recipients}
  '';

  hostRules =
    clusterTarget:
    builtins.concatStringsSep "\n" (
      map (
        host:
        rule "secrets/${clusterTarget}/hosts/${host.name}\\.yaml$" (
          adminRecipients ++ [ host.value.ageRecipient ]
        )
      ) (clusterHosts clusterTarget)
    );
in
''
  keys:
    users:
  ${builtins.concatStringsSep "\n" (map (recipient: "    - ${recipient}") adminRecipients)}

    hosts:
  ${builtins.concatStringsSep "\n" (map (recipient: "    - ${recipient}") allHostRecipients)}

  creation_rules:
  ${rule "secrets/common/admins\\.yaml$" (adminRecipients ++ allHostRecipients)}

  ${rule "secrets/production/cluster\\.yaml$" (clusterRecipients "production")}

  ${rule "secrets/staging/cluster\\.yaml$" (clusterRecipients "staging")}

  ${hostRules "production"}

  ${hostRules "staging"}
''
