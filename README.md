# arsfeld apt

The apt repository at **https://arsfeld.github.io/apt**, for elementary OS 8
(noble, amd64). It carries the latest builds of:

- [arsfeld/libghostty-gtk](https://github.com/arsfeld/libghostty-gtk):
  `libghostty-gtk-1-0`, `libghostty-gtk-dev`
- [arsfeld/elementary-terminal](https://github.com/arsfeld/elementary-terminal)
  (branch `libghostty-gtk`): `io.elementary.terminal-ghostty`, which replaces
  elementary's `io.elementary.terminal`

## Install

```sh
sudo curl -fsSLo /usr/share/keyrings/arsfeld.gpg https://arsfeld.github.io/apt/arsfeld.gpg
echo "deb [signed-by=/usr/share/keyrings/arsfeld.gpg] https://arsfeld.github.io/apt noble main" \
  | sudo tee /etc/apt/sources.list.d/arsfeld.list
sudo apt update
sudo apt install io.elementary.terminal-ghostty
```

Signing key: `arsfeld apt <alex@rosenfeld.one>`, RSA 4096,
fingerprint `4D10 1C42 0595 DC60 79F4 E577 0D5C 3479 3F4F 06A7`.

## How it works

The two source repos build their `.deb`s in elementary's OS 8 container and
publish each build as a GitHub Release. `.github/workflows/publish.yml` runs
hourly (and on demand: `gh workflow run publish -R arsfeld/apt`):

1. `publish.sh` downloads any `.deb` from those releases that the pool on
   `gh-pages` lacks, keeps the newest three versions of each package, and
   regenerates and signs the indexes with `apt-ftparchive` and the
   `APT_SIGNING_KEY` secret. The `.deb`s in the pool are the only state.
2. It pushes `gh-pages`, which GitHub Pages serves.
3. `verify` waits for Pages to serve the new `InRelease`, then installs from
   the repo in a clean elementary OS 8 container exactly as above, with
   `apt-get update --error-on=any`, and checks that the Terminal replaced
   elementary's and finds its library.

Polling, rather than a trigger from each source repo, keeps every credential
in this repo. Sources are listed in `sources`; the page and key are in
`site/`.
