<div align="center">

# Тема DDLC для SDDM

**Экран логина в стиле Doki Doki Literature Club — и неверный пароль он воспринимает плохо** ٩(◕‿◕)۶

![SDDM](https://img.shields.io/badge/SDDM-Theme_API_2.0-1D99F3?style=flat)
![Qt](https://img.shields.io/badge/Qt-6-41CD52?style=flat&logo=qt&logoColor=white)
![Nix](https://img.shields.io/badge/Nix-flake-7EBAE4?style=flat&logo=nixos&logoColor=white)
[![license](https://img.shields.io/badge/code-MIT-3DA639?style=flat)](LICENSE)
[![assets](https://img.shields.io/badge/assets-Team_Salvato-FF80C0?style=flat)](ASSETS.md)

<img src="docs/screenshot-normal.png" alt="экран логина" width="720"/>

[English](README.md)

</div>

По белому фону диагонально ползут розовые кружочки, панель логина сделана в духе меню игры, внизу дрейфуют четыре doki и подпрыгивают, когда к ним подводишь курсор. Ошибись паролем — и экран начнёт разваливаться

Чистый QML и INI, никакой Nix-интерполяции внутри темы, так что она ставится на любой дистрибутив обычным `cp`. Флейк тут удобство, а не требование

> Проект не аффилирован с Team Salvato и ими не одобрен. Спрайты и курсор принадлежат им — см. [ASSETS.md](ASSETS.md)

## Неудачи копятся

Каждая ошибка запускает глитч примерно на секунду — тряска панели, RGB-split через `QtQuick.Effects`, случайные сканлайны и мигающий искажённый текст — и оставляет след, который уже не уходит

| | что меняется |
| --- | --- |
| **1-я** | появляется зернистость, уходит Сайори, Юри переключается на обрезанные спрайты, фон слегка темнеет |
| **2-я** | ровная граница кружков расходится в колючий контур, включаются JPEG-артефакты, Юри становится искажённой — жуткое лицо в покое, датамош при наведении |
| **3-я** | Just Monika |

<div align="center">
<img src="docs/screenshot-corrupted.png" alt="после двух неудач" width="420"/>
<img src="docs/screenshot-just-monika.png" alt="Just Monika" width="420"/>
</div>

В пасхалке остаётся одна Моника, она съезжается в центр, остальные растворяются. Фон чернеет, кружки становятся красными, их движение плавно замирает и затем так же плавно разгоняется в обратную сторону. По экрану одно за другим открываются окошки "Just Monika", каждое закрывается кликом. Сбрасывается успешным входом или минутой тишины

## Установка

### NixOS

```nix
{
  inputs.ddlc-sddm-theme.url = "github:rokokol/ddlc-sddm-theme";

  # в конфигурации
  imports = [ inputs.ddlc-sddm-theme.nixosModules.default ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    ddlc.enable = true;
  };
}
```

Модуль ставит тему и курсоры, выбирает их в greeter и выставляет `QML_DISABLE_DISK_CACHE=1` — в `/nix/store` у всех файлов mtime 1970, и без этого QML-кэш Qt вечно отдаёт предыдущую версию темы

Опции лежат в `services.displayManager.sddm.ddlc`: `cursors` (по умолчанию `true`), `cursorSize`, `package` и `cursorPackage`. Включение самого SDDM, Wayland и выбор композитора остаются за тобой

### Любой другой дистрибутив

```sh
git clone https://github.com/rokokol/ddlc-sddm-theme
cd ddlc-sddm-theme
sudo ./install.sh --configure
```

`install.sh` копирует `theme/` в `/usr/share/sddm/themes/ddlc`, собирает курсоры в `/usr/share/icons/sayori-cursors` и с `--configure` пишет `/etc/sddm.conf.d/10-ddlc.conf`. Без этого флага он не трогает ничего за пределами двух директорий и просто говорит, какой ключ выставить. Есть ещё `--prefix` и `--no-cursors`

Самой теме не нужно ничего, кроме SDDM с Qt6 — это копирование директории. Курсорам на этапе установки нужны ImageMagick и `xcursorgen`

## Шрифты

`theme.conf` просит два семейства, которых в репозитории **нет**:

- `font=Doki` — шрифт из игры, принадлежит Team Salvato. Qt откатывается на дефолтный sans: выглядит нормально, но не так. Любой округлый шрифт ближе к оригиналу
- `iconFont=DepartureMono Nerd Font` — из него берутся только три глифа кнопок питания в правом нижнем углу. Без Nerd Font они превратятся в квадратики, так что укажи тот, который у тебя есть

## Настройка

Всё лежит в блоке `[General]` файла `theme/theme.conf` и читается из QML как `config.<ключ>`:

| ключ | дефолт | что делает |
| --- | --- | --- |
| `font` | `Doki` | основной шрифт |
| `iconFont` | `DepartureMono Nerd Font` | глифы кнопок питания |
| `bgColor` | `#FFFCFE` | цвет фона |
| `accentPink` / `deepPink` | `#FF80C0` / `#D667A0` | рамки и акценты |
| `dotColor` | `#FFDCEE` | цвет кружочков |
| `corruptDot` | `#FF1030` | цвет кружочков в пасхалке |
| `dotSpacing` / `dotRadius` | `200` / `50` | шаг решётки и радиус кружка |
| `scrollDuration` | `14000` | период дрейфа фона, мс |
| `panelColor` / `panelBorder` | `#FFEBF4` / `#FFBDE1` | панель логина |
| `okOutline` | `#BA5297` | обводка кнопки OK |
| `textDark` / `errorRed` | `#4A2B3A` / `#D6244A` | текст и ошибки |
| `glitchRgbSplit` | `true` | выключить, если RGB-split глючит на конкретном железе |

На NixOS это правится через пакет, а не через файл:

```nix
services.displayManager.sddm.ddlc.package =
  inputs.ddlc-sddm-theme.packages.${system}.sddm-ddlc-theme.override {
    settings = {
      font = "Comfortaa";
      dotColor = "#E8D5FF";
    };
  };
```

## Оконный тест без выхода из сессии

```sh
nix develop   # дальше: preview
```

или руками на любом дистрибутиве:

```sh
env -u QML2_IMPORT_PATH -u QML_IMPORT_PATH -u QT_PLUGIN_PATH \
  sddm-greeter-qt6 --test-mode --theme ./theme
```

Сбросить эти три переменные обязательно: QML- и plugin-пути текущей сессии перекрывают собственный Qt greeter'а, и он просто не стартует

В test-mode нет демона SDDM, поэтому настоящий `loginFailed` не приходит — **жми F8**, чтобы подделать неверный пароль. Три нажатия включают пасхалку

## Что где

```
theme/          Main.qml, theme.conf, metadata.desktop, components/, assets/
                — самодостаточно, копируется куда угодно
cursors/        исходные кадры + build-cursors.sh, единственная реализация,
                которую зовут и install.sh, и деривация
nix/            theme.nix, cursors.nix, module.nix
```

Имена QML-файлов в CamelCase, потому что в QML имя файла и есть имя типа

## Благодарности

Doki Doki Literature Club сделана [Team Salvato](https://teamsalvato.com/). Это некоммерческий фанатский контент, лицензии всех вложенных картинок расписаны в [ASSETS.md](ASSETS.md). Код под MIT

Выделено из [rokokol/huix](https://github.com/rokokol/huix), где всё это выросло
