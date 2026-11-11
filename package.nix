{
  lib,
  stdenv,
  dpkg,
  autoPatchelfHook,
  zlib,
  openssl,
  libnl,
  srcs,
}:

let
  inherit (stdenv.hostPlatform) system;
  arch =
    {
      x86_64-linux = "amd64";
      aarch64-linux = "arm64";
    }
    .${system} or (throw "falcon-sensor: unsupported system ${system}");
  src = srcs.${system} or (throw "falcon-sensor: no .deb given for ${system}");
in
stdenv.mkDerivation {
  pname = "falcon-sensor";
  version = lib.removeSuffix "_${arch}.deb" (lib.removePrefix "falcon-sensor_" (baseNameOf src));
  inherit src;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];
  buildInputs = [ zlib ];
  # loaded with dlopen
  runtimeDependencies = [
    (lib.getLib openssl)
    (lib.getLib libnl)
  ];

  sourceRoot = "root";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/lib/systemd/system $out/lib/tmpfiles.d
    cp -r opt/CrowdStrike $out/opt/
    cp lib/systemd/system/falcon-sensor.service $out/lib/systemd/system/

    # the sensor only runs from /opt/CrowdStrike and keeps its state there
    {
      echo "d /opt/CrowdStrike 0750 root root -"
      cd $out/opt/CrowdStrike
      find . -mindepth 1 -type d -printf 'd /opt/CrowdStrike/%P 0750 root root -\n'
      find . -mindepth 1 -maxdepth 1 ! -type d -printf "L+ /opt/CrowdStrike/%P - - - - $out/opt/CrowdStrike/%P\n"
    } > $out/lib/tmpfiles.d/falcon-sensor.conf

    runHook postInstall
  '';

  meta = {
    description = "CrowdStrike Falcon sensor";
    homepage = "https://www.crowdstrike.com";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
