{
  description = "Doki Doki Literature Club theme for the SDDM login screen";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = sddm-ddlc-theme;
        sddm-ddlc-theme = pkgs.callPackage ./nix/theme.nix { };
        sayori-cursors = pkgs.callPackage ./nix/cursors.nix { };
      });

      nixosModules.default = import ./nix/module.nix { inherit self; };

      # A greeter you can run inside your session: sddm-greeter-qt6 --test-mode.
      # The QML_* / QT_PLUGIN_PATH of the running session would shadow the greeter's own Qt
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.sddm ];
          shellHook = ''
            preview() {
              nix build .#sddm-ddlc-theme --out-link result-theme \
                && env -u QML2_IMPORT_PATH -u QML_IMPORT_PATH -u QT_PLUGIN_PATH \
                     sddm-greeter-qt6 --test-mode --theme ./result-theme/share/sddm/themes/ddlc
            }
            echo "run 'preview' to open the greeter in a window (F8 fakes a wrong password)"
          '';
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
