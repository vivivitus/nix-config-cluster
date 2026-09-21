{ ... }:

let
  bootstrapPublicKeyFile = builtins.getEnv "BOOTSTRAP_PUBLIC_KEY_FILE";

  bootstrapPublicKey =
    if bootstrapPublicKeyFile != "" then
      builtins.readFile bootstrapPublicKeyFile
    else
      throw ''
        BOOTSTRAP_PUBLIC_KEY_FILE is not set.
        This configuration is intended to be built by deploy scripts.
      '';
in
{
  services.openssh.enable = true;

  services.openssh.settings.PermitRootLogin = "prohibit-password";

  users.users.root.openssh.authorizedKeys.keys = [
    bootstrapPublicKey
  ];
}
