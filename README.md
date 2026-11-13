# pantheon-extras

An apt repository for elementary OS 8 (noble, amd64), served at
**https://arsfeld.github.io/pantheon-extras**. It carries the latest builds of:

- `io.elementary.dock-extras`, from [arsfeld/elementary-dock](https://github.com/arsfeld/elementary-dock)
  (branch `extras`): elementary's dock with folder stacks and zoom. Replaces `io.elementary.dock`.
- `pantheon-paper`, from [arsfeld/pantheon-paper](https://github.com/arsfeld/pantheon-paper):
  PaperWM-style scrolling tiling as a Gala plugin. Moves workspace switching to Ctrl+Super+Left/Right.
- `io.elementary.terminal-ghostty`, from [arsfeld/elementary-terminal](https://github.com/arsfeld/elementary-terminal)
  (branch `libghostty-gtk`): elementary Terminal on libghostty. Replaces `io.elementary.terminal`.
- `libghostty-gtk-1-0` and `libghostty-gtk-dev`, from [arsfeld/libghostty-gtk](https://github.com/arsfeld/libghostty-gtk):
  the GTK 4 terminal widget Terminal uses.

## Install

```sh
sudo curl -fsSLo /usr/share/keyrings/pantheon-extras.gpg https://arsfeld.github.io/pantheon-extras/pantheon-extras.gpg
echo "deb [signed-by=/usr/share/keyrings/pantheon-extras.gpg] https://arsfeld.github.io/pantheon-extras noble main" \
  | sudo tee /etc/apt/sources.list.d/pantheon-extras.list
sudo apt update
sudo apt install io.elementary.dock-extras pantheon-paper io.elementary.terminal-ghostty
```

The dock and tiling take effect at the next login.

Signing key: `arsfeld apt <alex@rosenfeld.one>`, RSA 4096,
fingerprint `4D10 1C42 0595 DC60 79F4 E577 0D5C 3479 3F4F 06A7`.

## How it works

Each source repo builds its `.deb`s in elementary's OS 8 container and publishes
them as a GitHub Release. `.github/workflows/publish.yml` runs hourly (or
`gh workflow run publish -R arsfeld/pantheon-extras`):

1. `publish.sh` downloads any `.deb` from those releases that the pool on
   `gh-pages` lacks, keeps the newest three versions of each package, and
   regenerates and signs the indexes with `apt-ftparchive` and the
   `APT_SIGNING_KEY` secret. The `.deb`s in the pool are the only state.
2. It pushes `gh-pages`, which GitHub Pages serves.
3. `verify` waits for Pages to serve the new `InRelease`, installs everything
   in a clean elementary OS 8 container with `apt-get update --error-on=any`,
   and checks that each package replaced or installed what it should.

Polling keeps every credential in this repo. Sources are listed in `sources`;
the page, screenshots and key are in `site/`. The page reads package versions
from the repo's `Packages` index, so it needs no edit for a new build.

Screenshots in `site/screenshots/` come from a private headless Gala with the
packaged dock and Terminal, using the dock's `DOCK_ZOOM_AT` and
`DOCK_STACKS_OPEN` test hooks. The tiling section has none yet.
Run the dock there with `GDK_DEBUG=no-portals`: otherwise GTK takes the icon
theme from the settings portal, which answers Adwaita, not the session's
`elementary`, and Terminal's `utilities-terminal` falls back to a white
symbolic outline.
