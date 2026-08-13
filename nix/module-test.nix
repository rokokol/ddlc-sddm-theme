# Evaluates the NixOS module against stubs for the option paths it writes to, so the wiring is
# checked without pulling nixpkgs' module set in. Produces the values it would emit; flake.nix
# turns them into assertions
{
  lib,
  pkgs,
  nixosModule,
}:

let
  stubs =
    { lib, ... }:
    {
      options = {
        assertions = lib.mkOption {
          type = lib.types.listOf lib.types.anything;
          default = [ ];
        };
        environment.systemPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
        };
        services.displayManager.sddm = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          theme = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          settings = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
            default = { };
          };
        };
      };
    };

  eval =
    user:
    (lib.evalModules {
      modules = [
        stubs
        nixosModule
        user
      ];
      specialArgs = { inherit pkgs lib; };
    }).config;

  # Joined rather than indexed, so "installed nothing" fails the assertion instead of
  # blowing up during evaluation with an unhelpful list error
  names = packages: lib.concatMapStringsSep " " toString packages;
  broken = config: map (a: a.message) (lib.filter (a: !a.assertion) config.assertions);

  sddmOn = {
    services.displayManager.sddm.enable = true;
  };

  wiredUp = eval (sddmOn // { ddlc.sddm.enable = true; });

  tuned = eval (
    sddmOn
    // {
      ddlc.sddm = {
        enable = true;
        settings.font = "Comfortaa";
        cursors.size = 24;
      };
    }
  );

  noCursors = eval (
    sddmOn
    // {
      ddlc.sddm = {
        enable = true;
        cursors.enable = false;
      };
    }
  );

  # The greeter environment is one string SDDM takes whole, so it is handed out with mkDefault:
  # a consumer setting their own has to win outright rather than merge
  overridden = eval (
    sddmOn
    // {
      ddlc.sddm.enable = true;
      services.displayManager.sddm.settings.General.GreeterEnvironment = "MINE=1";
    }
  );

  # Enabled without SDDM itself — the one thing the module refuses to do
  noSddm = eval { ddlc.sddm.enable = true; };

  off = eval sddmOn;
in
{
  packages = names wiredUp.environment.systemPackages;
  theme = wiredUp.services.displayManager.sddm.theme;
  greeterEnv = wiredUp.services.displayManager.sddm.settings.General.GreeterEnvironment;
  cursorTheme = wiredUp.services.displayManager.sddm.settings.Theme.CursorTheme or null;
  cursorSize = wiredUp.services.displayManager.sddm.settings.Theme.CursorSize or null;
  broken = broken wiredUp;

  tunedPackage = toString wiredUp.ddlc.sddm.package;
  tunedSettingsPackage = toString tuned.ddlc.sddm.package;
  tunedCursorSize = tuned.services.displayManager.sddm.settings.Theme.CursorSize or null;

  noCursorsPackages = names noCursors.environment.systemPackages;
  noCursorsTheme = noCursors.services.displayManager.sddm.settings.Theme or { };

  overriddenEnv = overridden.services.displayManager.sddm.settings.General.GreeterEnvironment;

  noSddmBroken = broken noSddm;

  offPackages = off.environment.systemPackages;
  offTheme = off.services.displayManager.sddm.theme;
  offSettings = off.services.displayManager.sddm.settings;
}
