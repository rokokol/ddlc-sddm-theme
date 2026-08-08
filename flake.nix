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

      # nix run .#preview — the greeter in a window, without logging out
      apps = forAllSystems (pkgs: {
        preview = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "preview";
              runtimeInputs = [ pkgs.kdePackages.sddm ];
              text = ''
                echo "F8 fakes a wrong password — three presses reach the easter egg"
                # The session's own QML/plugin paths shadow the greeter's Qt and it fails to start
                exec env -u QML2_IMPORT_PATH -u QML_IMPORT_PATH -u QT_PLUGIN_PATH \
                  sddm-greeter-qt6 --test-mode \
                  --theme ${self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-ddlc-theme}/share/sddm/themes/ddlc
              '';
            }
          );
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
