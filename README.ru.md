<div align="center">

# Тема DDLC для SDDM

**Экран логина в стиле Doki Doki Literature Club** o(^▽^)o

<img src="theme/assets/sayori-sticker-calm.png" alt="Сайори" width="110"/>
<img src="theme/assets/monika-sticker-calm.png" alt="Моника" width="110"/>
<img src="theme/assets/natsuki-sticker-calm.png" alt="Нацуки" width="110"/>
<img src="theme/assets/yuri-sticker-calm.png" alt="Юри" width="110"/>

![SDDM](https://img.shields.io/badge/SDDM-Theme_API_2.0-1D99F3?style=flat)
![Qt](https://img.shields.io/badge/Qt-6-41CD52?style=flat&logo=qt&logoColor=white)
![Nix](https://img.shields.io/badge/Nix-flake-7EBAE4?style=flat&logo=nixos&logoColor=white)
[![license](https://img.shields.io/badge/code-MIT-3DA639?style=flat)](LICENSE)
[![assets](https://img.shields.io/badge/assets-Team_Salvato-FF80C0?style=flat)](ASSETS.md)
[![build](https://github.com/rokokol/ddlc-sddm-theme/actions/workflows/build.yml/badge.svg)](https://github.com/rokokol/ddlc-sddm-theme/actions/workflows/build.yml)

<img src="docs/screenshot-normal.png" alt="экран логина" width="720"/>

<img src="docs/demo.webp" alt="три неверных пароля подряд" width="720"/>

*три неверных пароля подряд — [запись целиком](docs/demo.mp4)*

[English](README.md)

</div>

Чистый QML и INI, никакой Nix-интерполяции внутри темы, так что она ставится на любой дистрибутив обычным `cp`. Но перекачевала из **моего райса [rokokol/huix](https://github.com/rokokol/huix)**

> Проект не аффилирован с Team Salvato и ими не одобрен. Спрайты и курсор принадлежат им — см. [ASSETS.md](ASSETS.md)

## Неудачи копятся

Каждая ошибка запускает глитч примерно на секунду — тряска панели, RGB-split через `QtQuick.Effects`, случайные сканлайны и мигающий искажённый текст — и оставляет след, который уже не уходит

<div align="center">
<img src="docs/screenshot-glitch.png" alt="глитч при неверном пароле" width="720"/>
</div>

| | что меняется |
| --- | --- |
| **1-я** | появляется зернистость, уходит Сайори, Юри режет руи, фон слегка темнеет |
| **2-я** | ровная граница кружков расходится в колючий контур, включаются JPEG-артефакты, Юри становится искажённой |
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
  };

  ddlc.sddm.enable = true;
}
```

Модуль ставит тему и курсоры, выбирает их в greeter и выставляет `QML_DISABLE_DISK_CACHE=1` — в `/nix/store` у всех файлов mtime 1970, и без этого QML-кэш Qt вечно отдаёт предыдущую версию темы

Всё, чем владеет этот проект, живёт в `ddlc.sddm`: `settings`, `package` и `cursors.{enable,package,size}`. Включение самого SDDM, Wayland и выбор композитора — не наши настройки, они остаются там, куда их положил NixOS

### Любой другой дистрибутив

```sh
git clone https://github.com/rokokol/ddlc-sddm-theme
cd ddlc-sddm-theme
sudo ./install.sh
```

Без флагов он делает всё: копирует `theme/` в `/usr/share/sddm/themes/ddlc`, собирает курсоры в `/usr/share/icons/sayori-cursors` и пишет `/etc/sddm.conf.d/10-ddlc.conf`, где выбирает тему и курсор. Отговорить можно флагами `--no-configure` (не трогать `/etc`), `--no-cursors` и `--prefix`

Собранного ничего не требуется: и тема, и курсоры лежат в репе готовыми, установка — это `cp`. ImageMagick и `xcursorgen` нужны только если менять исходные кадры курсора и пересобирать их через `cursors/build-cursors.sh`

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
| `bgColor` | `#FFFFFF` | цвет фона |
| `accentPink` / `deepPink` | `#DD77BB` / `#BB5599` | рамки и акценты |
| `dotColor` | `#FFDBF0` | цвет кружочков |
| `corruptDot` | `#8C1132` | цвет кружочков в пасхалке |
| `dotSpacing` / `dotRadius` | `200` / `40` | шаг решётки и радиус кружка |
| `scrollDuration` | `14000` | период дрейфа фона, мс |
| `panelColor` / `panelBorder` | `#FFFFFF` / `#FFBDE1` | панель логина |
| `okOutline` | `#BB5599` | обводка кнопки OK |
| `textDark` / `textLight` | `#222222` / `#FFFFFF` | текст на светлом и на розовом фоне |
| `errorRed` | `#CC0C29` | строка о неверном пароле |
| `placeholderColor` | `#B59CA1` | подсказка в пустом поле пароля |
| `rowHighlight` | `#FFDBF0` | выбранная строка списка сессий |
| `splitWarm` / `splitCool` | `#CC0C29` / `#72D0FA` | два канала, которые разводит RGB-split |
| `glitchPink` / `glitchCyan` / `glitchDark` | `#DD77BB` / `#72D0FA` / `#361B39` | полосы поперёк глитча |
| `corruptOutline` | `#40000000` | тень под искажённым текстом — единственный ключ с альфой |
| `glitchRgbSplit` | `true` | выключить, если RGB-split глючит на конкретном железе |

`theme.conf` **генерируется**, а не пишется руками: `nix/theme-conf.nix` берёт цвета из [**ddlc-palette**](https://github.com/rokokol/ddlc-palette), который снимает их с [ddlc.moe](https://ddlc.moe/) (решётка кружков — фоновый тайл 200×200 с самого сайта, вплоть до радиуса), и добавляет ключи, о которых палитре нечего сказать. Результат коммитится, так что установка без Nix — по-прежнему `cp`

Чтобы поменять цвет, меняешь палитру и запускаешь `nix run .#write-theme-conf`. CI пересобирает файл и сравнивает с закоммиченным, так что правка руками роняет сборку, а не форкает палитру втихую

На NixOS это задаётся опциями, а не правкой файла — модуль пересоберёт тему, подмешав их в `theme.conf`:

```nix
ddlc.sddm.settings = {
  font = "Comfortaa";
  dotColor = "#E8D5FF";
  glitchRgbSplit = false;
};
```

## Оконный тест без выхода из сессии

```sh
nix run github:rokokol/ddlc-sddm-theme#preview
```

Откроется окно с greeter'ом в `--test-mode`, тема берётся собранная. Или руками на любом дистрибутиве:

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
cursors/        готовая XCursor-тема, её исходные кадры и скрипт,
                который пересобирает первое из второго
nix/            theme.nix, cursors.nix, module.nix
```

Имена QML-файлов в CamelCase, потому что в QML имя файла и есть имя типа

## Благодарности

Doki Doki Literature Club сделана [Team Salvato](https://teamsalvato.com/). Это некоммерческий фанатский контент, лицензии всех вложенных картинок расписаны в [ASSETS.md](ASSETS.md). Код под MIT

