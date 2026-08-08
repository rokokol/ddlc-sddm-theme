# NixOS module: point an already-enabled SDDM at the DDLC theme.
# Everything this project owns lives under `ddlc.*`; enabling SDDM itself, picking
# Wayland and choosing the compositor stay with the consumer, under their own options.
# Deliberately no `ddlc.enable` — a sibling flake declaring the same path would abort the eval
{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ddlc.sddm;
  sddm = config.services.displayManager.sddm;
in
{
  options.ddlc.sddm = {
    enable = lib.mkEnableOption "the Doki Doki Literature Club theme for SDDM";

    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.int
          lib.types.bool
        ]
      );
      default = { };
      example = {
        font = "Comfortaa";
        dotColor = "#E8D5FF";
      };
      description = ''
        Keys of the `[General]` block in `theme.conf` — see the README table.
        Ignored if `package` is set to something built elsewhere.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-ddlc-theme.override {
        inherit (cfg) settings;
      };
      defaultText = lib.literalExpression "ddlc-sddm-theme.packages.\${system}.sddm-ddlc-theme.override { inherit settings; }";
      description = "The theme package, built with `settings` applied";
    };

    cursors = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install the Sayori cursor theme and use it in the greeter";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.sayori-cursors;
        defaultText = lib.literalExpression "ddlc-sddm-theme.packages.\${system}.sayori-cursors";
        description = "The cursor theme package";
      };

      size = lib.mkOption {
        type = lib.types.ints.positive;
        default = 32;
        description = "Cursor size in the greeter";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = sddm.enable;
        message = "ddlc.sddm.enable needs services.displayManager.sddm.enable";
      }
    ];

    environment.systemPackages = [ cfg.package ] ++ lib.optional cfg.cursors.enable cfg.cursors.package;

    services.displayManager.sddm = {
      theme = "ddlc";

      settings = {
        # /nix/store mtime=1970 → Qt QML cache serves a stale theme; disable so the greeter
        # picks up changes. Wayland shell integration is set here too because SDDM takes
        # GreeterEnvironment as one string, so a consumer appending to it would fight this
        General.GreeterEnvironment = lib.mkDefault "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QML_DISABLE_DISK_CACHE=1";

        Theme = lib.mkIf cfg.cursors.enable {
          CursorTheme = "sayori-cursors";
          CursorSize = cfg.cursors.size;
        };
      };
    };
  };
}
