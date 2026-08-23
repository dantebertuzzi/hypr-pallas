# Changelog

All notable changes to this theme are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The version is also declared in `metadata.desktop`.

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

[1.1.0]: https://github.com/dantebertuzzi/hypr-pallas/compare/e740c40...main
[1.0.0]: https://github.com/dantebertuzzi/hypr-pallas/commit/e740c40
