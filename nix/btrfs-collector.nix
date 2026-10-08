{
  lib,
  stdenvNoCC,
  makeWrapper,
  nodejs,
  btrfs-progs,
  util-linux,
  coreutils,
}:
let
  # JSON subvolume output is upstream's experimental interface. Enable it only
  # in this private tool build so arbitrary path characters remain lossless.
  btrfsJson = btrfs-progs.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [ "--enable-experimental" ];
  });
in
stdenvNoCC.mkDerivation {
  pname = "couch-shell-btrfs";
  version = "1";
  src = ../tools/btrfs;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p "$out/libexec/couch-shell-btrfs"
    cp *.mjs "$out/libexec/couch-shell-btrfs/"
    substituteInPlace "$out/libexec/couch-shell-btrfs/collector.mjs" \
      --replace-fail '@findmnt@' '${lib.getExe' util-linux "findmnt"}' \
      --replace-fail '@btrfs@' '${lib.getExe btrfsJson}' \
      --replace-fail '@df@' '${lib.getExe' coreutils "df"}'
    makeWrapper ${lib.getExe nodejs} "$out/bin/couch-shell-btrfs-server" \
      --add-flags "$out/libexec/couch-shell-btrfs/server.mjs"
    makeWrapper ${lib.getExe nodejs} "$out/bin/couch-shell-btrfs-client" \
      --add-flags "$out/libexec/couch-shell-btrfs/client.mjs"
  '';
}
