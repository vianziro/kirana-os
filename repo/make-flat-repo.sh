#!/usr/bin/env bash
# Repo APT "flat" bertanda tangan di dist/, untuk diunggah sebagai aset GitHub Release.
# apt memakainya lewat:  deb [signed-by=...] https://github.com/vianziro/kirana-os/releases/latest/download/ ./
#   SIGNING_KEY_ID : ID/fingerprint kunci GPG (wajib untuk rilis)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIST=${DIST:-$ROOT/dist}
cd "$DIST"
rm -f Packages Packages.gz Release InRelease Release.gpg kirana-archive-keyring.*
apt-ftparchive packages . > Packages
gzip -9kf Packages
apt-ftparchive \
  -o "APT::FTPArchive::Release::Origin=Kirana OS" \
  -o "APT::FTPArchive::Release::Label=Kirana OS" \
  -o "APT::FTPArchive::Release::Suite=stable" \
  -o "APT::FTPArchive::Release::Architectures=amd64 arm64 all" \
  -o "APT::FTPArchive::Release::Description=Repositori paket Kirana OS (built by vianziro)" \
  release . > Release
: "${SIGNING_KEY_ID:?SIGNING_KEY_ID belum diset}"
gpg --batch --yes -u "$SIGNING_KEY_ID" --clearsign -o InRelease Release
gpg --batch --yes -u "$SIGNING_KEY_ID" -abs -o Release.gpg Release
gpg --batch --export "$SIGNING_KEY_ID" > kirana-archive-keyring.gpg
gpg --batch --armor --export "$SIGNING_KEY_ID" > kirana-archive-keyring.asc
echo "Repo flat siap di $DIST ($(grep -c '^Package:' Packages) paket)"
