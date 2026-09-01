# Sayori's head as an XCursor theme. The theme is committed prebuilt (cursors/theme), so this
# is a copy — regenerate it from the source frames with cursors/build-cursors.sh
{ stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  pname = "sayori-cursors";
  # The one source of version: VERSION at the repo root, asserted against CHANGELOG by CI
  version = lib.fileContents (
    builtins.path {
      name = "VERSION";
      path = ../VERSION;
    }
  );

  src = ../cursors/theme;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    cp -a ./. $out/share/icons/sayori-cursors

    runHook postInstall
  '';

  meta = {
    description = "Sayori's head (DDLC) as an XCursor theme";
    homepage = "https://github.com/rokokol/ddlc-sddm-theme";
    # MIT covers the xcursorgen recipe only — the sprites are Team Salvato's, see ASSETS.md
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
