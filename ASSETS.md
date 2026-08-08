# Assets and third-party content

`LICENSE` (MIT) covers the **code** in this repository — the QML, the shell scripts and the Nix expressions. It does **not** cover the artwork under `theme/assets/` and `cursors/assets/`, which belongs to its owner and is included as fan content

## Doki Doki Literature Club

Doki Doki Literature Club and Doki Doki Literature Club Plus are the property of [Team Salvato](https://teamsalvato.com/). This project is **unaffiliated with and not endorsed by Team Salvato**

The following are derived from or contain official DDLC assets:

| Path | What |
| --- | --- |
| `theme/assets/*-sticker-*.png` | character sprites — Sayori, Monika, Natsuki, Yuri, in calm, excited, cut and distorted variants |
| `theme/assets/just-monika-ok.png` | the in-game "Just Monika. OK" dialog, used by the easter egg |
| `cursors/assets/sayori-head.png`, `sayori-head-glitch.png` | two frames cut from DDLC's own sprites, turned into an X cursor by `cursors/build-cursors.sh` |

`theme/assets/noise.png` is a generated grey noise tile and is not a game asset — regenerate it with `magick -size 240x240 xc:gray50 +noise Random -colorspace Gray -depth 8 -strip theme/assets/noise.png`

The `Doki` font family that `theme.conf` asks for is Team Salvato's and is **not** shipped here. Without it Qt falls back to its default sans; see the README for how to point the theme at another font

Use here follows [Team Salvato's IP guidelines](https://teamsalvato.com/ip-guidelines): this is non-commercial fan content, nothing containing official assets is sold, and no claim of affiliation is made. If you reuse any of it, the same conditions apply to you

Team Salvato reserves the right to act on copyright or trademark infringement; nothing here grants a licence to their intellectual property
