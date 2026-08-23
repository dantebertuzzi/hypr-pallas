# Changelog

All notable changes to this theme are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The version is also declared in `metadata.desktop`.

## [Unreleased]

## [1.2.0] - 2026-08-23

### Added

- **Every roadmap item that was open.** The three under *Next* and the four
  under *Later* all landed here; `ROADMAP.md` now only carries what came out of
  building them.
- **Authentication is visible.** `root.busy` was tracked and guarded double
  submits, but nothing on screen reflected it. The fields now dim and stop
  taking input, and the submit arrow becomes a spinning ring — drawn with
  `Canvas`, so it survives the software renderer.
- **`avatarShape`**: `arch`, `circle` or `square`, with `circle-*.png` and
  `square-*.png` added next to the Arch pair. All six masks are 288×288 with a
  6px ring, so the shapes carry the same weight. An unknown value falls back to
  `arch`.
- **`outlineColor` and `outlineOpacity`**, which were pinned to `subtext0` at
  `0.70` inside the QML while every other colour came from `theme.conf`.
- **Every string is a `theme.conf` key**, along with `locale`, `timeFormat` and
  `dateFormat`. The defaults are the pt-BR strings the theme already had, so an
  existing install keeps its screen; the README shows an English `theme.conf`.
- **Keyboard layout indicator** in the footer, shown only when more than one
  layout exists. Clicking cycles `keyboard.currentLayout`, hovering gives the
  long name.
- **Account picker.** With more than one account the username field grows a `▾`
  listing `userModel`, each row with the account's picture and full name. The
  field stays typable, so accounts hidden from the model are still reachable.
- `install.sh`, which copies the tracked theme files into
  `/usr/share/sddm/themes/hypr-pallas` and asks for `sudo` only when the
  destination requires it, so `DESTDIR` builds run unprivileged. An existing
  `theme.conf` is left alone and the repo's default installed only when there is
  none: the tracked file ships with `background=` empty, so copying it over a
  live install dropped the wallpaper. It also warns when `theme.conf` points at
  a wallpaper that is not in the folder — the greeter says nothing and quietly
  falls back to the gradient.

### Fixed

- **The software renderer never actually worked**, which the 1.1 fallbacks could
  not have shown because they were never run. One boot with
  `QT_QUICK_BACKEND=software` put the avatar's initial alone in the middle of
  the screen: `layer.enabled: true` on the shape means the item is composed
  through a layer, and the software backend does not compose layers, so the
  shape itself vanished. The layer is now tied to `!swRender` — it only ever
  existed to feed `MultiEffect` a mask, which is off in that path anyway. With a
  picture found, the initial now also takes its place rather than leaving a
  filled shape with nothing in it.
- **`loginFailed` erased its own message.** The handler set `msgText` and then
  cleared the password field, and the field's `onTextChanged` clears `msgText`
  whenever it has content — so "Falha na autenticação" was wiped in the same
  tick it appeared. The clearing now hangs off `onTextEdited`, which only fires
  for typing.
- Values are read through `cfgStr`/`cfgNum`, so a key present but empty
  (`dimOpacity=`) falls back instead of reaching the item as `NaN`.

### Changed

- README installs with `./install.sh` instead of `sudo cp -r`, which copied
  `.git`, the Markdown files and `assets/` into the theme folder along the way.
  The section now says to rerun it after every `git pull`: the greeter reads
  from `/usr/share/sddm/themes/`, never from the clone, so a theme current in
  Git can still be the old one on screen.
- The preview in the README was regenerated, and now shows the account picker's
  arrow in the username field.

## [1.1.0] - 2026-08-23

### Added

- **Avatar.** The user's picture sits above the fields, cropped to the Arch logo
  silhouette. `arch-mask.png` carries the filled shape (used both as the
  `MultiEffect` mask and as the placeholder behind the picture) and
  `arch-outline.png` the surrounding ring, tinted at runtime instead of having a
  colour baked in. The picture is looked up in
  `/var/lib/AccountsService/icons/<user>`, then
  `/usr/share/sddm/faces/<user>.face.icon`; with neither, the silhouette stays
  filled and shows the first letter of the typed name.
- Tooltips on the power buttons, shifted back when they would cross the screen
  edge — the power-off button sits flush against it.
- Caps Lock indicator, plus the message from `loginFailed` and
  `informationMessage` under the fields.
- A fallback path for the software renderer, where `MultiEffect` draws nothing:
  the wallpaper, the clock shadow, the avatar crop and its outline degrade
  instead of vanishing.

### Changed

- Power buttons no longer rely on the glyphs `⏻ ⏾ ↻` resolving in the installed
  font; the icons are drawn with `Canvas`.
- The session name is filled in by the delegates instead of reaching into the
  model with `Qt.UserRole + 4`, a magic number that breaks if SDDM reorders its
  roles.
- The form no longer sits 40px below centre — the avatar takes that space.
- README: an avatar section, a note that the theme now ships two PNG masks, and
  a preview regenerated from the current greeter.

### Fixed

- `dimOpacity=0` and `blurRadius=0` were silently ignored: both were read with a
  truthiness check, so zero fell through to the default. They are now tested
  with `!== undefined`.
- An empty username field resolved to `/usr/share/sddm/faces/.face.icon` —
  SDDM's generic silhouette — because the path was assembled by concatenation.
  With no name typed there is now no lookup at all.

## [1.0.0] - 2026-08-23

### Added

- Initial theme: clock, username and password fields, session selector that
  remembers the last session, power actions, Catppuccin Mocha palette, and
  `theme.conf` keys for wallpaper, blur, dimming and accent colour.
- `QtVersion=6` in `metadata.desktop` — without it SDDM defaults to 5 and
  launches a Qt5 greeter that cannot start on a Qt6-only system.

[Unreleased]: https://github.com/dantebertuzzi/hypr-pallas/compare/v1.2.0...main
[1.2.0]: https://github.com/dantebertuzzi/hypr-pallas/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/dantebertuzzi/hypr-pallas/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/dantebertuzzi/hypr-pallas/releases/tag/v1.0.0
