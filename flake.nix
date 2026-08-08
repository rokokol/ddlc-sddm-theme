{
  description = "Doki Doki Literature Club theme for the SDDM login screen";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Only the checks read it — theme.conf keeps literal hex so the theme installs without Nix
    ddlc-palette.url = "github:rokokol/ddlc-palette";
    ddlc-palette.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      ddlc-palette,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # theme.conf key -> palette name
      fromPalette = {
        bgColor = "paper";
        panelColor = "paper";
        dotColor = "dot";
        panelBorder = "blush";
        accentPink = "pink";
        deepPink = "plum";
        okOutline = "plum";
        textDark = "ink";
        errorRed = "error";
        corruptDot = "corrupt";
      };
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

      # theme.conf and the palette repo hold the same hex twice; this is what keeps them equal
      checks = forAllSystems (pkgs: {
        palette-in-sync =
          let
            palette = ddlc-palette.lib.palette;
            expected = nixpkgs.lib.mapAttrsToList (key: name: "${key}=${palette.${name}}") fromPalette;
          in
          pkgs.runCommand "palette-in-sync" { } ''
            fail=0
            while read -r line; do
              grep -qxF "$line" ${./theme/theme.conf} || { echo "theme.conf: expected $line"; fail=1; }
            done <<'LINES'
            ${builtins.concatStringsSep "\n" expected}
            LINES
            [ $fail -eq 0 ] || { echo "run generate.sh in ddlc-palette, or update theme.conf"; exit 1; }
            touch $out
          '';
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
