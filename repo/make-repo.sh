#!/usr/bin/env bash
# Susun repositori APT bertanda tangan dari dist/*.deb ke folder situs (GitHub Pages).
#   SIGNING_KEY_ID  : ID kunci GPG yang sudah diimpor (opsional; tanpa ini repo tidak ditandatangani)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIST=${DIST:-$ROOT/dist}
SITE=${SITE:-$ROOT/site}
SUITE=stable
ARCHS="amd64 arm64"

rm -rf "$SITE"; mkdir -p "$SITE/pool/main"
cp "$DIST"/*.deb "$SITE/pool/main/"
cd "$SITE"
for a in $ARCHS; do
  d=dists/$SUITE/main/binary-$a; mkdir -p "$d"
  apt-ftparchive --arch "$a" packages pool > "$d/Packages"
  gzip -9kf "$d/Packages"
done
apt-ftparchive \
  -o "APT::FTPArchive::Release::Origin=Kirana OS" \
  -o "APT::FTPArchive::Release::Label=Kirana OS" \
  -o "APT::FTPArchive::Release::Suite=$SUITE" \
  -o "APT::FTPArchive::Release::Codename=$SUITE" \
  -o "APT::FTPArchive::Release::Architectures=$ARCHS" \
  -o "APT::FTPArchive::Release::Components=main" \
  -o "APT::FTPArchive::Release::Description=Repositori paket Kirana OS (built by vianziro)" \
  release "dists/$SUITE" > "dists/$SUITE/Release"

if [ -n "${SIGNING_KEY_ID:-}" ]; then
  gpg --batch --yes -u "$SIGNING_KEY_ID" --clearsign -o "dists/$SUITE/InRelease" "dists/$SUITE/Release"
  gpg --batch --yes -u "$SIGNING_KEY_ID" -abs -o "dists/$SUITE/Release.gpg" "dists/$SUITE/Release"
  gpg --batch --export "$SIGNING_KEY_ID" > kirana-archive-keyring.gpg
  gpg --batch --armor --export "$SIGNING_KEY_ID" > kirana-archive-keyring.asc
fi
cp "$ROOT/repo/index.html" index.html
touch .nojekyll
echo "Repo siap di $SITE"
