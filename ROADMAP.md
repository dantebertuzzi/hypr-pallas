# Roadmap

What is worth doing next, and why. Nothing here is scheduled — this is a theme
for one desktop that happens to be published.

Everything that stood here through 1.1 shipped in 1.2: the busy indicator, the
avatar shape and outline keys, the pt-BR strings, the keyboard layout
indicator, the account picker, and the software-renderer check — which turned
out to be the one that mattered, since running it found the fallback broken.
What is left is what building those turned up.

## Next

- **The account picker is mouse-only.** The `▾` opens with a click and each row
  answers to `MouseArea`; there is no way to open the list, walk it or pick from
  it with the keyboard, which is the odd gap in a screen whose whole point is
  that your hands are already on the keys. Arrow keys and Enter over a
  `currentIndex`, plus a focus ring on the row, would close it.

## Later

- **The layout indicator has only been seen against a fake model.**
  `sddm-greeter-qt6 --test-mode` reports `keyboard.layouts.length === 0`, so the
  button was verified by substituting a two-entry stand-in: it renders, the
  short name follows `currentLayout`, and the guards hold at zero layouts. What
  a real two-layout machine does when the click writes back to
  `keyboard.currentLayout` is still untested.
- **A comma in a `theme.conf` value always returns followed by one space.**
  SDDM splits values on commas and trims the pieces, and the theme rejoins them
  with `", "` — which is right for `dateFormat=dddd, d 'de' MMMM` and wrong for
  anyone who wants `a,b`. Escaping (`\,`) does not survive the split either: the
  comma disappears entirely. Fixing it properly means not going through SDDM's
  parser for these keys.
- **A user list instead of a field, all the way.** The picker fills the text
  field rather than replacing it, because typing has to stay for accounts that
  `HideUsers` keeps out of `userModel`. A theme that knew it had every account
  could drop the field and show faces.

## Not planned

- **Bundling a wallpaper.** `theme.conf` takes any path, and shipping an image
  would put megabytes into every clone. The preview in the README uses the
  default gradient for the same reason.
- **Translating through Qt's `.qm` files.** The strings are `theme.conf` keys
  now, which is the same edit-one-file workflow as the rest of the theme and
  needs no build step. A greeter with eight strings does not need `lupdate`.
