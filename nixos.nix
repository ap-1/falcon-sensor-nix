{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.falcon-sensor;
  falconctl = "/opt/CrowdStrike/falconctl";
in
{
  options.services.falcon-sensor = {
    enable = lib.mkEnableOption "the CrowdStrike Falcon sensor";

    srcs = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      example = lib.literalExpression ''
        {
          x86_64-linux = ./falcon-sensor_7.34.0-18708_amd64.deb;
          aarch64-linux = ./falcon-sensor_7.34.0-18708_arm64.deb;
        }
      '';
      description = "Falcon sensor `.deb` for each system.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { inherit (cfg) srcs; };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { inherit (config.services.falcon-sensor) srcs; }";
      description = "Falcon sensor package.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      example = "/run/secrets/falcon-sensor.env";
      description = "Environment file setting `FALCONCTL_OPT_CID` to the CID.";
    };

    backend = lib.mkOption {
      type = lib.types.enum [
        "auto"
        "bpf"
        "kernel"
      ];
      default = "bpf";
      description = "Sensor backend.";
    };

    tags = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "[A-Za-z0-9/_@.-]+");
      default = [ ];
      example = [ "servers" ];
      description = "Sensor grouping tags.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.packages = [ cfg.package ];
    systemd.tmpfiles.packages = [ cfg.package ];

    systemd.services.falcon-sensor = {
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      restartTriggers = [ cfg.package ];
      serviceConfig = {
        EnvironmentFile = cfg.environmentFile;
        ExecStartPre = [
          # replace the packaged check, which has to run after the CID is set
          ""
          "${falconctl} -s -f --cid=\${FALCONCTL_OPT_CID} --backend=${cfg.backend}${
            lib.optionalString (cfg.tags != [ ]) " --tags=${lib.concatStringsSep "," cfg.tags}"
          }"
          "${falconctl} -g --cid"
        ];
      };
    };
  };
}
