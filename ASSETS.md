# Assets and third-party content

`LICENSE` (MIT) covers the **code** in this repository — the QML, the shell scripts and the Nix expressions. It does **not** cover the artwork under `theme/assets/` and `cursors/assets/`, which belongs to its owner and is included as fan content

## Doki Doki Literature Club

Doki Doki Literature Club and Doki Doki Literature Club Plus are the property of [Team Salvato](https://teamsalvato.com/). This project is **unaffiliated with and not endorsed by Team Salvato**

The following are derived from or contain official DDLC assets:

| Path | What |
| --- | --- |
| `theme/assets/*-sticker-*.png` | character sprites — Sayori, Monika, Natsuki, Yuri, in calm, excited, cut and distorted variants. The four calm ones are `sticker_?.png` from [ddlc.moe](https://ddlc.moe/) at native size, padded onto one canvas |
| `theme/assets/just-monika-ok.png` | the in-game "Just Monika. OK" dialog, used by the easter egg |
| `cursors/assets/sayori-head.png`, `sayori-head-glitch.png` | two frames cut from DDLC's own sprites, turned into an X cursor by `cursors/build-cursors.sh` |

`theme/assets/noise.png` is a generated grey noise tile and is not a game asset — regenerate it with `magick -size 240x240 xc:gray50 +noise Random -colorspace Gray -depth 8 -strip theme/assets/noise.png`

The `Doki` font family that `theme.conf` asks for is a font by 538Fonts from 2015, which is not part of the game. It is free for personal use only and is **not** shipped here. Without it the theme sets the same text in the bundled Nunito; see the README for how to point the theme at another font

## Nunito

`theme/fonts/Nunito-wght.ttf` is the variable Nunito font from [googlefonts/nunito](https://github.com/googlefonts/nunito), copyright The Nunito Project Authors, under the SIL Open Font License 1.1 — the licence text is `theme/fonts/Nunito-LICENSE.txt`. It is not covered by the MIT licence of the code. The OFL lets a font travel with a program, so it is bundled: a login screen runs before the user's session, and cannot rely on the fonts installed for it. Both files are copied unchanged by `vendor-sync.sh`, and `.github/vendor.lock` names the commit they come from

Use here follows [Team Salvato's IP guidelines](https://teamsalvato.com/ip-guidelines): this is non-commercial fan content, nothing containing official assets is sold, and no claim of affiliation is made. If you reuse any of it, the same conditions apply to you

Team Salvato reserves the right to act on copyright or trademark infringement; nothing here grants a licence to their intellectual property
