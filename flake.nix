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
        ddlc = ddlc-palette.lib;
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

      # For a consumer who reaches for pkgs rather than this flake's packages directly
      overlays.default = final: _prev: {
        inherit (self.packages.${final.stdenv.hostPlatform.system}) sddm-ddlc-theme sayori-cursors;
      };

      checks = forAllSystems (
        pkgs:
        let
          lib = nixpkgs.lib;
          inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) sddm-ddlc-theme sayori-cursors;
        in
        {
          # theme.conf is a generated file that has to stay committed — this proves it current
          theme-conf-current = pkgs.runCommand "theme-conf-current" { } ''
            diff -u ${./theme/theme.conf} ${pkgs.writeText "theme.conf" themeConf} || {
              echo "theme/theme.conf is stale — run: nix run .#write-theme-conf"
              exit 1
            }
            touch $out
          '';

          # The theme must stay copy-installable: everything the QML references has to be inside it
          theme-is-self-contained = pkgs.runCommand "theme-is-self-contained" { } ''
            theme=${sddm-ddlc-theme}/share/sddm/themes/ddlc
            for f in Main.qml theme.conf metadata.desktop assets/noise.png assets/just-monika-ok.png; do
              test -e "$theme/$f" || { echo "missing $f"; exit 1; }
            done
            test "$(ls "$theme"/assets/*-sticker-*.png | wc -l)" -eq 12
            touch $out
          '';

          # Cursors ship prebuilt; catch a checkout where they rotted or a symlink lost its target
          cursors-are-intact = pkgs.runCommand "cursors-are-intact" { } ''
            icons=${sayori-cursors}/share/icons/sayori-cursors
            test -e "$icons/index.theme"
            test "$(find "$icons/cursors" -type f | wc -l)" -eq 2
            find "$icons/cursors" -type l | while read -r l; do
              test -e "$l" || { echo "dangling: $l"; exit 1; }
            done
            touch $out
          '';

          # Enabling the module has to be enough to get the theme, the cursors and the greeter
          # environment the QML cache needs — and turning it off has to leave SDDM untouched
          module-wiring =
            let
              wiring = import ./nix/module-test.nix {
                inherit lib pkgs;
                nixosModule = self.nixosModules.default;
              };
            in
            pkgs.runCommand "module-wiring"
              {
                nativeBuildInputs = [ pkgs.jq ];
                dump = builtins.toJSON wiring;
                passAsFile = [ "dump" ];
              }
              ''
                want() { jq -e "$1" "$dumpPath" >/dev/null || { echo "module wiring: $2"; exit 1; }; }

                # The field names below are written a second time here, so a rename in
                # module-test.nix would otherwise surface as a stray failure in whichever
                # check read the key first — and jq answers true for "missing == empty"
                want 'keys == [
                  "broken", "cursorSize", "cursorTheme", "greeterEnv", "noCursorsPackages",
                  "noCursorsTheme", "noSddmBroken", "offPackages", "offSettings", "offTheme",
                  "overriddenEnv", "packages", "theme", "tunedCursorSize", "tunedPackage",
                  "tunedSettingsPackage"
                ]' "the dump no longer has the keys these checks read"

                want '.broken == []' "enabling the theme breaks the system"
                want '.theme == "ddlc"' "SDDM was never pointed at the theme"
                want '.packages | test("sddm-ddlc-theme")' "the theme is not installed"
                want '.packages | test("sayori-cursors")' "the cursors are not installed"

                # /nix/store mtime is 1970, so without this the greeter serves a cached theme
                want '.greeterEnv | test("QML_DISABLE_DISK_CACHE=1")' "the QML cache is not disabled"
                want '.cursorTheme == "sayori-cursors"' "the greeter does not use the cursors"
                want '.cursorSize == 32' "the cursor size never reached the greeter"

                # settings is what the package is overridden with, so it has to change the build
                want '.tunedSettingsPackage != .tunedPackage' "settings never reached the package"
                want '.tunedCursorSize == 24' "a custom cursor size did not reach the greeter"

                want '.noCursorsPackages | test("sddm-ddlc-theme")' "the theme went missing"
                want '.noCursorsPackages | test("sayori-cursors") | not' "cursors installed while off"
                want '.noCursorsTheme == {}' "a cursor setting survives turning cursors off"

                # mkDefault, so a consumer setting the same string wins outright
                want '.overriddenEnv == "MINE=1"' "the module overrode the consumer's own value"

                want '.noSddmBroken | length == 1' "the theme accepted a system without SDDM"
                want '.noSddmBroken[0] | test("sddm.enable")' "the assertion does not name what is missing"

                want '.offPackages == []' "a package is installed while disabled"
                want '.offTheme == ""' "the theme is set while disabled"
                want '.offSettings == {}' "an SDDM setting survives disabling"
                touch $out
              '';

          # The stub test above cannot see this: a stubbed option accepts anything, so a module
          # that writes to the wrong one, or writes a value the real module cannot render, still
          # passes it. Here the real module set gets to refuse
          nixos-eval =
            let
              real = import ./nix/nixos-eval.nix {
                inherit lib nixpkgs;
                system = pkgs.stdenv.hostPlatform.system;
                module = self.nixosModules.default;
              };
            in
            pkgs.runCommand "nixos-eval"
              {
                nativeBuildInputs = [ pkgs.jq ];
                dump = builtins.toJSON real;
                passAsFile = [ "dump" ];
              }
              ''
                want() { jq -e "$1" "$dumpPath" >/dev/null || { echo "nixos eval: $2"; exit 1; }; }

                want 'keys == [
                  "broken", "cursorSize", "offBroken", "offTheme", "renderedConf", "theme",
                  "withoutSddmBroken"
                ]' "the dump no longer has the keys these checks read"

                want '.broken == []' "a real system with the theme enabled does not evaluate"
                want '.theme == "ddlc"' "SDDM was never pointed at the theme"

                # The greeter INI is generated by nixpkgs, not by us — an int where it wants a
                # string is invisible until this file is written
                want '.renderedConf | test("Current=ddlc")' "the theme is missing from sddm.conf"
                want '.renderedConf | test("CursorSize=32")' "the cursor size is missing from sddm.conf"
                want '.cursorSize == 32' "the cursor size never reached the settings"

                want '.withoutSddmBroken | length == 1' "the theme accepted a system without SDDM"

                want '.offBroken == []' "a system without the theme does not evaluate"
                want '.offTheme != "ddlc"' "the theme is set while disabled"
                touch $out
              '';
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
