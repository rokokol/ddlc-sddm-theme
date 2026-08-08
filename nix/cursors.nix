# X cursor for the login screen: Sayori's head. The build itself lives in
# cursors/build-cursors.sh so that the Nix and the plain-install paths stay one implementation
{
  stdenvNoCC,
  lib,
  xcursorgen,
  imagemagick,
}:

stdenvNoCC.mkDerivation {
  pname = "sayori-cursors";
  version = "1.0";

  src = ../cursors;

  nativeBuildInputs = [
    xcursorgen
    imagemagick
  ];

  installPhase = ''
    runHook preInstall

    bash ./build-cursors.sh $out/share/icons/sayori-cursors

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
