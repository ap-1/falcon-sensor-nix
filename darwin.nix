{
  config,
  lib,
  ...
}:

let
  cfg = config.services.falcon-sensor;
  falconctl = "/Applications/Falcon.app/Contents/Resources/falconctl";
  license = "/Library/Application Support/CrowdStrike/Falcon/License.bin";
  marker = "/var/db/falcon-sensor-nix";
in
{
  options.services.falcon-sensor = {
    enable = lib.mkEnableOption "the CrowdStrike Falcon sensor";

    src = lib.mkOption {
      type = lib.types.path;
      description = "Falcon sensor installer, such as `FalconSensorMacOS.pkg`.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      example = "/run/secrets/falcon-sensor.env";
      description = "Environment file setting `FALCONCTL_OPT_CID` to the CID.";
    };
  };

  config = lib.mkIf cfg.enable {
    # macOS still requires approving the system extension, network filter, and
    # Full Disk Access
    system.activationScripts.postActivation.text = ''
      if [ "$(cat ${marker} 2>/dev/null || true)" != ${cfg.src} ]; then
        echo "installing the Falcon sensor..." >&2
        /usr/sbin/installer -pkg ${cfg.src} -target /
        printf '%s' ${cfg.src} > ${marker}
      fi

      if [ ! -e ${lib.escapeShellArg license} ]; then
        (
          . ${lib.escapeShellArg cfg.environmentFile}
          ${falconctl} license "$FALCONCTL_OPT_CID"
        )
      fi
    '';
  };
}
