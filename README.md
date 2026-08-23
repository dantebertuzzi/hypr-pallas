# Hypr Pallas

A minimal [SDDM](https://github.com/sddm/sddm) theme in
[Catppuccin Mocha](https://github.com/catppuccin/catppuccin), built to sit
visually next to [Hyprland](https://hyprland.org/).

![preview](assets/preview.png)

No login button, no icon bar — just a clock, the user's picture cropped to the
Arch silhouette, two fields, and a quiet session selector in the corner.

## Design

Geometry mirrors Hyprland's own window decoration, so the greeter reads as part
of the same desktop:

| Theme | Hyprland |
|---|---|
| `radius: 12` | `decoration:rounding = 12` |
| `borderW: 2` | `general:border_size = 2` |
| focused border `#89b4fa` | `general:col.active_border` |
| idle border `#45475a` | `general:col.inactive_border` |

## Requirements

- `sddm` 0.21+
- `qt6-declarative` (provides `QtQuick` and `QtQuick.Effects`)

That is all. The theme imports only `QtQuick` and `QtQuick.Effects` and ships no
binaries — the only bundled assets are the six small PNG masks used by the
avatar, one pair per shape.

## Install

```sh
git clone https://github.com/dantebertuzzi/hypr-pallas.git
cd hypr-pallas
./install.sh
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=hypr-pallas\n' | sudo tee /etc/sddm.conf.d/10-theme.conf
```

`install.sh` copies the tracked theme files and asks for `sudo` once, at
the point it actually needs it. **Run it again after every `git pull`**: the
greeter reads from `/usr/share/sddm/themes/`, never from your clone, so a theme
that is current in Git can still be the old one on screen.

It leaves an existing `theme.conf` alone and installs the repo's default only
when there is none. That is deliberate — the tracked `theme.conf` ships with
`background=` empty, so copying it over a live install would silently drop your
wallpaper. The wallpaper itself is never touched: it is gitignored and exists
only in the theme folder. `DESTDIR` is honoured, for packaging.

Preview it without rebooting:

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/hypr-pallas
```

## Configuration

Edit `theme.conf` — no QML changes needed:

| Key | Default | Meaning |
|---|---|---|
| `background` | *(empty)* | Image path, relative to the theme folder. Empty falls back to a Mocha gradient. |
| `blurRadius` | `24` | Wallpaper blur. `0` disables. |
| `dimOpacity` | `0.62` | Darkening over the wallpaper, `0.0`–`1.0`. |
| `accent` | `#89b4fa` | Focused border, submit arrow, active session. |
| `avatarShape` | `arch` | Avatar crop: `arch`, `circle` or `square`. Anything else falls back to `arch`. |
| `outlineColor` | `#a6adc8` | Ring around the avatar. |
| `outlineOpacity` | `0.70` | Ring opacity, `0.0`–`1.0`. |

### Language

The theme was written in pt-BR and stays there when the keys are absent, so an
existing install keeps the screen it had. Every string is a key:

| Key | Default |
|---|---|
| `locale` | `pt_BR` |
| `timeFormat` | `HH:mm` |
| `dateFormat` | `dddd, d 'de' MMMM` |
| `userPlaceholder` | `usuário` |
| `passwordPlaceholder` | `senha` |
| `sessionLabel` | `Sessão` |
| `suspendLabel` | `Suspender` |
| `rebootLabel` | `Reiniciar` |
| `shutdownLabel` | `Desligar` |
| `loginFailedMessage` | `Falha na autenticação` |
| `capsLockWarning` | `⇪ Caps Lock ativo` |

`locale` picks the language of the day and month names; `timeFormat` and
`dateFormat` take [QDateTime](https://doc.qt.io/qt-6/qdatetime.html#toString)
patterns. An English screen is eleven lines:

```ini
locale=en_US
dateFormat=dddd, d MMMM
userPlaceholder=username
passwordPlaceholder=password
sessionLabel=Session
suspendLabel=Suspend
rebootLabel=Restart
shutdownLabel=Shut down
loginFailedMessage=Authentication failed
capsLockWarning=⇪ Caps Lock is on
```

One quirk to know about: SDDM splits a value on commas and trims each piece, so
`dateFormat=dddd, d MMMM` reaches the theme as a two-item list. The theme joins
it back with `", "`, which is why the pattern above works — but it also means a
comma in any value always comes back followed by exactly one space.

### Using your own wallpaper

Drop the image into the theme folder and point `background` at it:

```ini
[General]
background=background.png
```

Put the file **inside the theme folder**, not in your home directory. The
greeter runs as the unprivileged `sddm` user, which usually cannot read a home
directory with `700` permissions.

## Note on `QtVersion`

`metadata.desktop` declares:

```ini
QtVersion=6
```

This matters more than it looks. SDDM ships two greeter binaries, and the daemon
picks one based on that key — [`ThemeMetadata.cpp`](https://github.com/sddm/sddm/blob/v0.21.0/src/common/ThemeMetadata.cpp):

```cpp
d->qtVersion = settings.value(QStringLiteral("SddmGreeterTheme/QtVersion"), 5).toInt();
```

**When the key is absent it defaults to 5**, and the daemon launches
`/usr/bin/sddm-greeter` (Qt5). On a Qt6-only system that binary fails to load
its libraries, `sddm-helper` exits with code `127`, and you get a black screen
at boot with no greeter at all.

If you adapt this theme, keep the key.

## Avatar

The user's picture is cropped to the Arch logo silhouette instead of the usual
circle. `avatarShape` switches that for `circle` or `square`; each shape is a
pair of PNGs, and all three pairs ship with the theme:

| File | Role |
|---|---|
| `<shape>-mask.png` | Filled shape. Doubles as the `MultiEffect` mask (only its alpha channel matters) and as the placeholder behind the picture. |
| `<shape>-outline.png` | Ring around the shape. Tinted at runtime with `outlineColor` and `outlineOpacity`, so no colour is baked into the file. |

All six are 288×288 with a 6px ring, so the three shapes sit at the same weight
next to each other. Adding a fourth is a pair of PNGs and a name — the QML masks
against whatever alpha channel it is given.

Where the picture comes from, in order:

1. `/var/lib/AccountsService/icons/<user>` — what GNOME Settings writes when you
   set a profile picture
2. `/usr/share/sddm/faces/<user>.face.icon` — SDDM's own convention

SDDM's generic `.face.icon` is deliberately *not* in that list: cropped to the
silhouette it reads as a smudge. When no picture is found, the silhouette stays
filled and shows the first letter of the typed name instead.

The field reacts to typing, so the picture follows whichever user is entered.
At the login screen the field already comes filled with `userModel.lastUser`.

Under the software renderer `MultiEffect` draws nothing, so the crop and the
outline are skipped and the filled shape with the initial is shown instead —
verified by running the greeter with `QT_QUICK_BACKEND=software`, not just
reasoned about.

## Choosing an account

With more than one account on the machine the username field grows a `▾` that
opens a list of them, each with its picture and full name. Picking one fills the
field and jumps to the password.

The field stays a text field: system accounts, and any account hidden by SDDM's
`HideUsers`, are still reachable by typing the name. With a single account the
arrow does not appear at all.

## Keyboard layout

When more than one layout is installed, the footer shows the active one next to
the session selector; clicking cycles through them and hovering names the layout
in full. With a single layout there is nothing to choose, so nothing is shown.

## Signing in

While PAM decides, the fields dim and stop taking input, and the submit arrow
becomes a spinner — a slow PAM stack used to leave the screen looking exactly as
it did before Enter, which reads as a dead greeter.

## Session selector

The corner dropdown lists every session in `/usr/share/wayland-sessions` and
`/usr/share/xsessions`, and remembers the last one used via
`sessionModel.lastIndex`.

Worth checking after switching to any SDDM theme: many rice themes hide or omit
the session selector entirely, because their authors run a single desktop.

## Changelog and roadmap

Release notes live in [CHANGELOG.md](CHANGELOG.md); what is worth doing next,
and what deliberately is not, in [ROADMAP.md](ROADMAP.md).

## License

MIT — see [LICENSE](LICENSE).

The preview image shows the theme's default gradient. No wallpaper is bundled,
and the picture in it is the empty-field placeholder, not a real avatar.
