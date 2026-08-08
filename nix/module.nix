# NixOS module: point an already-enabled SDDM at the DDLC theme.
# Enabling SDDM itself, picking Wayland and choosing the compositor stay with the consumer
{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.displayManager.sddm.ddlc;
  sddm = config.services.displayManager.sddm;
in
{
  options.services.displayManager.sddm.ddlc = {
    enable = lib.mkEnableOption "the Doki Doki Literature Club theme for SDDM";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-ddlc-theme;
      defaultText = lib.literalExpression "ddlc-sddm-theme.packages.\${system}.sddm-ddlc-theme";
      description = "The theme package. Override it to change theme.conf: `package.override { settings = { font = \"Sans\"; }; }`";
    };

    cursors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the Sayori cursor theme and use it in the greeter";
    };

    cursorPackage = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.sayori-cursors;
      defaultText = lib.literalExpression "ddlc-sddm-theme.packages.\${system}.sayori-cursors";
      description = "The cursor theme package used when `cursors` is enabled";
    };

    cursorSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 32;
      description = "Cursor size in the greeter";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = sddm.enable;
        message = "services.displayManager.sddm.ddlc.enable needs services.displayManager.sddm.enable";
      }
    ];

    environment.systemPackages = [ cfg.package ] ++ lib.optional cfg.cursors cfg.cursorPackage;

    services.displayManager.sddm = {
      theme = "ddlc";

      settings = {
        # /nix/store mtime=1970 → Qt QML cache serves a stale theme; disable so the greeter
        # picks up changes. Wayland shell integration is set here too because SDDM takes
        # GreeterEnvironment as one string, so a consumer appending to it would fight this
        General.GreeterEnvironment = lib.mkDefault "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QML_DISABLE_DISK_CACHE=1";

        Theme = lib.mkIf cfg.cursors {
          CursorTheme = "sayori-cursors";
          CursorSize = cfg.cursorSize;
        };
      };
    };
  };
}
