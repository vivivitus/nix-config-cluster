{ lib, config, ... }:

let
  cfg = config.cluster.longhorn;
in
{
  options.cluster.longhorn.storagePaths = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Local directories that are prepared for use as Longhorn storage.
    '';
  };

  config = {
    systemd.tmpfiles.rules = map (path: "d ${path} 0750 root root -") cfg.storagePaths;
  };
}
