# DDLC theme derivation for SDDM (Qt6, Theme-API 2.0).
# QML files are named in CamelCase — a QML requirement: the file name sets the type name
{
  stdenvNoCC,
  lib,
  # [General] overrides merged into theme.conf, e.g. { font = "Sans"; accentPink = "#FF80C0"; }.
  # theme.conf stays the single source of defaults — this only rewrites the keys given here
  settings ? { },
}:

stdenvNoCC.mkDerivation {
  pname = "sddm-ddlc-theme";
  version = "1.0";

  src = ../theme;

  # The theme is copy-installable as it stands: QML references its assets relatively,
  # so a build step would only get between the source tree and the greeter
  installPhase = ''
    runHook preInstall

    theme=$out/share/sddm/themes/ddlc
    mkdir -p $out/share/sddm/themes
    cp -r ./. "$theme"

    ${lib.concatLines (
      lib.mapAttrsToList (
        k: v:
        # INI booleans, not Nix ones — `toString true` is "1", which QML reads as false
        let
          val = lib.generators.mkValueStringDefault { } v;
        in
        ''
          grep -q '^${k}=' "$theme/theme.conf" \
            && sed -i 's|^${k}=.*|${k}=${val}|' "$theme/theme.conf" \
            || echo '${k}=${val}' >> "$theme/theme.conf"
        ''
      ) settings
    )}

    runHook postInstall
  '';

  meta = {
    description = "Doki Doki Literature Club theme for the SDDM login screen";
    homepage = "https://github.com/rokokol/ddlc-sddm-theme";
    # MIT covers the QML only — the sprites are Team Salvato's, see ASSETS.md
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
