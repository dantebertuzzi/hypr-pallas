# Roadmap

What is worth doing next, and why. Nothing here is scheduled — this is a theme
for one desktop that happens to be published.

## Next

- **Show that authentication is happening.** `root.busy` is already tracked and
  guards double submits, but nothing on screen reflects it: after Enter the form
  looks exactly as it did before, and a slow PAM stack reads as a dead greeter.
  A spinner in the submit button, or dimming the fields, would cover it.
- **Make the avatar shape a `theme.conf` key** (`arch`, `circle`, `square`).
  The QML already masks against an arbitrary alpha channel, so this is a second
  pair of PNGs and a key, not a rewrite.
- **Expose the outline colour and opacity.** They are currently pinned to
  `subtext0` at `0.70` in the QML, while every other colour in the theme comes
  from `theme.conf`.

## Later

- **The strings are hard-coded in pt-BR** — `usuário`, `senha`, `Sessão`,
  `Suspender`, `Reiniciar`, `Desligar`, `Falha na autenticação`,
  `⇪ Caps Lock ativo`. Anyone else installing the theme gets a Portuguese
  greeter. They should move to `theme.conf` keys or Qt translations.
- **Keyboard layout indicator.** SDDM exposes `keyboard.layouts` and
  `keyboard.currentLayout`; the theme ignores both. On a machine with more than
  one layout there is no way to tell which one is active before typing a
  password blind.
- **A user list instead of a free-text field.** This machine already has two
  accounts, and `userModel` carries the names and pictures — the field could
  become a picker, with typing as the fallback.
- **Verify the software-renderer path on real hardware.** The `swRender` guards
  were reasoned through and never executed; one boot with
  `QT_QUICK_BACKEND=software` would confirm the greeter degrades instead of
  showing a black screen.
- **Tag the releases.** The repository has no tags: `v1.0.0` would be `e740c40`
  and `v1.1.0` the current `main`.

## Not planned

- **Bundling a wallpaper.** `theme.conf` takes any path, and shipping an image
  would put megabytes into every clone. The preview in the README uses the
  default gradient for the same reason.
