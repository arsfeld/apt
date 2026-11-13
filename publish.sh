#!/bin/sh
# Rebuilds the apt repo in $1 (a gh-pages checkout) from the latest release
# of every repo in ./sources, and signs it with the key in $GNUPGHOME.
#
# The .debs under pool/ are the repo's only state: every index is
# regenerated from them (apt-ftparchive), so there is no database to keep.
# Exits 0 with nothing changed when no release has a .deb the pool lacks,
# unless FORCE=1.
set -eu

site=$1
here=$(cd "$(dirname "$0")" && pwd)
keep=3 # versions of each package kept, for `apt install pkg=<version>`
changed=${FORCE:-0}

grep -v '^#' "$here/sources" | while read -r repo; do
  [ -n "$repo" ] || continue
  dir="$site/pool/main/${repo#*/}"
  mkdir -p "$dir"
  # A repo with no release yet contributes nothing, rather than failing.
  debs=$(gh release view --repo "$repo" --json assets \
    --jq '.assets[] | select(.name | endswith(".deb")) | .name' 2>/dev/null) ||
    { echo "no release yet: $repo"; continue; }
  printf '%s\n' "$debs" | while read -r deb; do
    [ -n "$deb" ] || continue
    [ -e "$dir/$deb" ] && continue
    echo "new: $repo $deb"
    gh release download --repo "$repo" --pattern "$deb" --dir "$dir"
  done
done

# Newest $keep versions of each package; older ones leave the pool.
for deb in "$site"/pool/main/*/*.deb; do
  [ -e "$deb" ] || continue
  printf '%s %s %s\n' "$(dpkg-deb -f "$deb" Package)" "$(dpkg-deb -f "$deb" Version)" "$deb"
done | sort -k1,1 -k2,2V | awk -v keep=$keep '
  { pkg[NR] = $1; file[NR] = $3; count[$1]++ }
  END { for (i = 1; i <= NR; i++) if (seen[pkg[i]]++ < count[pkg[i]] - keep) print file[i] }
' | while read -r old; do echo "drop: $old"; rm "$old"; done

# Changed if the pool differs from what the current index lists.
listed=$(sed -n 's/^Filename: //p' "$site/dists/noble/main/binary-amd64/Packages" 2>/dev/null | sort)
present=$(cd "$site" && ls pool/main/*/*.deb 2>/dev/null | sort)
if [ -z "$present" ]; then
  echo "no packages yet" >&2
  exit 1
fi
[ "$listed" = "$present" ] || changed=1
if [ "$changed" = 0 ]; then
  echo "nothing new"
  exit 0
fi

cd "$site"
mkdir -p dists/noble/main/binary-amd64
apt-ftparchive packages pool/main > dists/noble/main/binary-amd64/Packages
gzip -9nkf dists/noble/main/binary-amd64/Packages
xz -9kf dists/noble/main/binary-amd64/Packages
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin=arsfeld \
  -o APT::FTPArchive::Release::Label=pantheon-apt \
  -o APT::FTPArchive::Release::Suite=noble \
  -o APT::FTPArchive::Release::Codename=noble \
  -o APT::FTPArchive::Release::Architectures=amd64 \
  -o APT::FTPArchive::Release::Components=main \
  -o "APT::FTPArchive::Release::Description=elementary Terminal on libghostty-gtk and the elementary dock with extras, for elementary OS 8" \
  release dists/noble > dists/noble/Release.new
mv dists/noble/Release.new dists/noble/Release
rm -f dists/noble/InRelease dists/noble/Release.gpg
gpg --batch --yes --digest-algo SHA512 --clearsign -o dists/noble/InRelease dists/noble/Release
gpg --batch --yes --digest-algo SHA512 -abs -o dists/noble/Release.gpg dists/noble/Release
