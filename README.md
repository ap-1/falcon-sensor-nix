# falcon-sensor-nix

NixOS and nix-darwin modules for the CrowdStrike Falcon sensor.

## NixOS

```nix
{
  inputs.falcon-sensor.url = "github:ap-1/falcon-sensor-nix";
}
```

```nix
{ inputs, lib, ... }:
{
  imports = [ inputs.falcon-sensor.nixosModules.default ];

  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "falcon-sensor";

  services.falcon-sensor = {
    enable = true;
    srcs = {
      x86_64-linux = ./falcon-sensor_7.34.0-18708_amd64.deb;
      aarch64-linux = ./falcon-sensor_7.34.0-18708_arm64.deb;
    };
    # FALCONCTL_OPT_CID=<CID>
    environmentFile = "/run/secrets/falcon-sensor.env";
  };
}
```

## nix-darwin

```nix
{ inputs, ... }:
{
  imports = [ inputs.falcon-sensor.darwinModules.default ];

  services.falcon-sensor = {
    enable = true;
    src = ./FalconSensorMacOS.pkg;
    environmentFile = "/run/secrets/falcon-sensor.env";
  };
}
```

macOS still requires approving the system extension, network filter, and Full Disk Access.

> [!NOTE]
> The sensor can update itself unless sensor version updates are off in the Falcon console's sensor update policy. NixOS links the packaged build back into `/opt/CrowdStrike` at boot and on every switch, and nix-darwin runs the installer again when `src` changes.
