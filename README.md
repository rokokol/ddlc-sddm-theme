<div align="center">

# DDLC theme for SDDM

**A Doki Doki Literature Club login screen — and it does not take a wrong password well** ٩(◕‿◕)۶

![SDDM](https://img.shields.io/badge/SDDM-Theme_API_2.0-1D99F3?style=flat)
![Qt](https://img.shields.io/badge/Qt-6-41CD52?style=flat&logo=qt&logoColor=white)
![Nix](https://img.shields.io/badge/Nix-flake-7EBAE4?style=flat&logo=nixos&logoColor=white)
[![license](https://img.shields.io/badge/code-MIT-3DA639?style=flat)](LICENSE)
[![assets](https://img.shields.io/badge/assets-Team_Salvato-FF80C0?style=flat)](ASSETS.md)

<img src="docs/screenshot-normal.png" alt="the login screen" width="720"/>

[Русский](README.ru.md)

</div>

Pink dots crawl diagonally across a white background, the login panel is styled after the game's menu, four doki drift along the bottom edge and hop when the cursor comes near. Type the wrong password and the screen starts falling apart

Pure QML and INI — no Nix interpolation anywhere in the theme, so it installs on any distribution with a plain `cp`. The flake is a convenience, not a requirement

> Unaffiliated with and not endorsed by Team Salvato. The sprites and the cursor are theirs — see [ASSETS.md](ASSETS.md)

## Wrong passwords accumulate

Every failure runs a glitch of about a second — the panel shakes, RGB-split through `QtQuick.Effects`, random scanlines, flickering corrupted text — and then leaves a mark that stays

| | what changes |
| --- | --- |
| **1st** | film grain over the background, Sayori leaves, Yuri switches to the cut sprites, the background darkens a little |
| **2nd** | the even dot outlines break into ragged spikes, JPEG-style compression blocks appear, Yuri turns distorted — a wrong face at rest, datamosh on hover |
| **3rd** | Just Monika |

<div align="center">
<img src="docs/screenshot-corrupted.png" alt="after two failures" width="420"/>
<img src="docs/screenshot-just-monika.png" alt="Just Monika" width="420"/>
</div>

In the easter egg only Monika remains, sliding to the centre while everyone else fades out. The background goes black, the dots turn red, and their drift comes to a smooth stop before accelerating the other way. "Just Monika" windows open across the screen one after another — each closes on click. A successful login clears it, and so does a minute of silence

## Install

### NixOS

```nix
{
  inputs.ddlc-sddm-theme.url = "github:rokokol/ddlc-sddm-theme";

  # in your configuration
  imports = [ inputs.ddlc-sddm-theme.nixosModules.default ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    ddlc.enable = true;
  };
}
```

The module installs the theme and the cursors, selects them in the greeter, and sets `QML_DISABLE_DISK_CACHE=1` — under `/nix/store` every file has mtime 1970, so Qt's QML cache happily serves the previous version of the theme forever without it

Options live under `services.displayManager.sddm.ddlc`: `cursors` (default `true`), `cursorSize`, `package` and `cursorPackage`. Enabling SDDM itself, Wayland and the compositor stay yours

### Any other distribution

```sh
git clone https://github.com/rokokol/ddlc-sddm-theme
cd ddlc-sddm-theme
sudo ./install.sh --configure
```

`install.sh` copies `theme/` into `/usr/share/sddm/themes/ddlc`, builds the cursors into `/usr/share/icons/sayori-cursors` and — with `--configure` — writes `/etc/sddm.conf.d/10-ddlc.conf`. Without that flag it changes nothing outside the two directories and tells you which key to set. `--prefix` and `--no-cursors` are there too

The theme itself is a directory copy and needs nothing but SDDM with Qt6. The cursors need ImageMagick and `xcursorgen` at install time

## Fonts

`theme.conf` asks for two families that are **not** shipped:

- `font=Doki` — the game's font, Team Salvato's. Qt falls back to its default sans, which looks fine but not right. Any rounded font gets you closer
- `iconFont=DepartureMono Nerd Font` — only the three power glyphs in the bottom right corner come from it. Without a Nerd Font they render as boxes, so point this at whichever one you have

## Configuration

Everything lives in the `[General]` block of `theme/theme.conf`, read from QML as `config.<key>`:

| key | default | what it does |
| --- | --- | --- |
| `font` | `Doki` | main font family |
| `iconFont` | `DepartureMono Nerd Font` | glyphs on the power buttons |
| `bgColor` | `#FFFCFE` | background |
| `accentPink` / `deepPink` | `#FF80C0` / `#D667A0` | borders and accents |
| `dotColor` | `#FFDCEE` | the dots |
| `corruptDot` | `#FF1030` | the dots in easter-egg mode |
| `dotSpacing` / `dotRadius` | `200` / `50` | grid step and dot radius |
| `scrollDuration` | `14000` | drift period of the background, ms |
| `panelColor` / `panelBorder` | `#FFEBF4` / `#FFBDE1` | login panel |
| `okOutline` | `#BA5297` | outline of the OK button |
| `textDark` / `errorRed` | `#4A2B3A` / `#D6244A` | text and errors |
| `glitchRgbSplit` | `true` | turn off if RGB-split misbehaves on your hardware |

On NixOS, edit these through the package instead of the file:

```nix
services.displayManager.sddm.ddlc.package =
  inputs.ddlc-sddm-theme.packages.${system}.sddm-ddlc-theme.override {
    settings = {
      font = "Comfortaa";
      dotColor = "#E8D5FF";
    };
  };
```

## Preview without logging out

```sh
nix develop   # then: preview
```

or, by hand on any distribution:

```sh
env -u QML2_IMPORT_PATH -u QML_IMPORT_PATH -u QT_PLUGIN_PATH \
  sddm-greeter-qt6 --test-mode --theme ./theme
```

Unsetting those three matters: the QML and plugin paths of your running session shadow the greeter's own Qt and it fails to start

Test-mode has no SDDM daemon, so a real `loginFailed` never arrives — **press F8** to fake a wrong password. Three presses reach the easter egg

## Layout

```
theme/          Main.qml, theme.conf, metadata.desktop, components/, assets/
                — self-contained, copy it anywhere
cursors/        source frames + build-cursors.sh, the one implementation both
                install.sh and the Nix derivation call
nix/            theme.nix, cursors.nix, module.nix
```

QML file names are CamelCase because in QML the file name *is* the type name

## Credits

Doki Doki Literature Club is by [Team Salvato](https://teamsalvato.com/). This is non-commercial fan content, and the licensing of every bundled image is spelled out in [ASSETS.md](ASSETS.md). The code is MIT

Extracted from [rokokol/huix](https://github.com/rokokol/huix), where it grew up
