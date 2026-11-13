# pantheon-apt

The apt repository at **https://arsfeld.github.io/pantheon-apt**, for elementary OS 8
(noble, amd64): Pantheon with extras. It carries the latest builds of:

- [arsfeld/elementary-dock](https://github.com/arsfeld/elementary-dock)
  (branch `extras`): `io.elementary.dock-extras`, elementary's dock with
  folder stacks, zoom and sharp icons, which replaces `io.elementary.dock`
- [arsfeld/elementary-terminal](https://github.com/arsfeld/elementary-terminal)
  (branch `libghostty-gtk`): `io.elementary.terminal-ghostty`, elementary
  Terminal on Ghostty's terminal engine, which replaces `io.elementary.terminal`
- [arsfeld/libghostty-gtk](https://github.com/arsfeld/libghostty-gtk):
  `libghostty-gtk-1-0`, `libghostty-gtk-dev`, the GTK 4 terminal widget the
  Terminal runs on

The landing page, with screenshots of each, is `site/index.html`.

## Install

```sh
sudo curl -fsSLo /usr/share/keyrings/pantheon-apt.gpg https://arsfeld.github.io/pantheon-apt/pantheon-apt.gpg
echo "deb [signed-by=/usr/share/keyrings/pantheon-apt.gpg] https://arsfeld.github.io/pantheon-apt noble main" \
  | sudo tee /etc/apt/sources.list.d/pantheon-apt.list
sudo apt update
sudo apt install io.elementary.dock-extras         # then log out and back in; and/or
sudo apt install io.elementary.terminal-ghostty
```

This repository used to be `arsfeld/apt`, served at `arsfeld.github.io/apt`.
GitHub Pages does not redirect a renamed repository, so a machine set up from
the old address fails `apt update` with a 404: remove
`/etc/apt/sources.list.d/arsfeld.list` and `/usr/share/keyrings/arsfeld.gpg`
and add the repository again as above. The signing key is the same one.

Signing key: `arsfeld apt <alex@rosenfeld.one>`, RSA 4096,
fingerprint `4D10 1C42 0595 DC60 79F4 E577 0D5C 3479 3F4F 06A7`.

## How it works

The source repos build their `.deb`s in elementary's OS 8 container and
publish each build as a GitHub Release. `.github/workflows/publish.yml` runs
hourly (and on demand: `gh workflow run publish -R arsfeld/pantheon-apt`):

1. `publish.sh` downloads any `.deb` from those releases that the pool on
   `gh-pages` lacks, keeps the newest three versions of each package, and
   regenerates and signs the indexes with `apt-ftparchive` and the
   `APT_SIGNING_KEY` secret. The `.deb`s in the pool are the only state.
2. It pushes `gh-pages`, which GitHub Pages serves.
3. `verify` waits for Pages to serve the new `InRelease`, then installs from
   the repo in a clean elementary OS 8 container exactly as above, with
   `apt-get update --error-on=any`, and checks that the Terminal replaced
   elementary's and finds its library, and that the dock replaced
   elementary's and carries its extra settings.

Polling, rather than a trigger from each source repo, keeps every credential
in this repo. Sources are listed in `sources`; the page, its screenshots and
the key are in `site/`. The page reads each package's version from the
repo's own `Packages` index, so it never needs editing for a new build.

## Screenshots

`site/screenshots/` were taken in a private headless Gala (never a live
session) with the packaged dock and Terminal, a curated app list and a demo
Downloads folder, using the dock's `DOCK_ZOOM_AT` and `DOCK_STACKS_OPEN` test
hooks to hold the zoom and open a stack. Retake them when a feature's look
changes.
