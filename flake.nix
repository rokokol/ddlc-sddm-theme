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

      themeConf = import ./nix/theme-conf.nix {
        inherit (nixpkgs) lib;
        palette = ddlc-palette.lib.palette;
      };
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = sddm-ddlc-theme;
        sddm-ddlc-theme = pkgs.callPackage ./nix/theme.nix { };
        sayori-cursors = pkgs.callPackage ./nix/cursors.nix { };
      });

      nixosModules.default = import ./nix/module.nix { inherit self; };

      apps = forAllSystems (pkgs: {
        # nix run .#write-theme-conf — regenerate the committed theme.conf from the palette
        write-theme-conf = {
          type = "app";
          program = pkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "write-theme-conf";
              text = ''
                cp --no-preserve=mode ${pkgs.writeText "theme.conf" themeConf} theme/theme.conf
                echo "wrote theme/theme.conf"
              '';
            }
          );
        };

        # nix run .#preview — the greeter in a window, without logging out
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
      # theme.conf is a generated file that has to stay committed — this is what proves it current
      checks = forAllSystems (pkgs: {
        theme-conf-current = pkgs.runCommand "theme-conf-current" { } ''
          diff -u ${./theme/theme.conf} ${pkgs.writeText "theme.conf" themeConf} || {
            echo "theme/theme.conf is stale — run: nix run .#write-theme-conf"
            exit 1
          }
          touch $out
        '';
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
