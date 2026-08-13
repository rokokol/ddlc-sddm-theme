# Evaluates the NixOS module inside a real nixpkgs module set, not against stubs. The stub test
# in module-test.nix answers "does the option reach the config"; this one answers "would nixpkgs
# accept the config at all" — a stub for services.displayManager.sddm.settings takes anything,
# while the real module writes that attrset out as an INI file and has opinions about its types.
#
# What gets forced is config.assertions, not system.build.toplevel: the assertions are the thing
# under test, and a check is realised rather than merely evaluated, so making the toplevel the
# check would build a whole system closure
{
  lib,
  nixpkgs,
  system,
  module,
}:

let
  # The smallest config nixpkgs will call a system: without a root filesystem and a bootloader
  # decision, evaluation stops before it reaches anything of ours
  base = {
    nixpkgs.hostPlatform = system;
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
    system.stateVersion = "25.11";
  };

  evalWith =
    user:
    (nixpkgs.lib.nixosSystem {
      modules = [
        module
        base
        user
      ];
    }).config;

  broken = config: map (a: a.message) (lib.filter (a: !a.assertion) config.assertions);

  # nixpkgs refuses an SDDM that greets on neither X nor Wayland, and this theme is drawn by
  # the Wayland greeter — layer-shell is what the module puts in GreeterEnvironment
  sddm = {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  withSddm = evalWith (sddm // { ddlc.sddm.enable = true; });

  # The case the assertion exists for: the theme without the display manager it themes
  withoutSddm = evalWith { ddlc.sddm.enable = true; };

  off = evalWith sddm;
in
{
  broken = broken withSddm;
  theme = withSddm.services.displayManager.sddm.theme;
  cursorSize = withSddm.services.displayManager.sddm.settings.Theme.CursorSize;

  # The real module renders settings into sddm.conf, so this is the first place a value of the
  # wrong type shows up as something other than an attrset that happened to evaluate
  renderedConf = builtins.readFile withSddm.environment.etc."sddm.conf.d/00-nixos.conf".source;

  withoutSddmBroken = broken withoutSddm;

  offBroken = broken off;
  offTheme = off.services.displayManager.sddm.theme;
}
