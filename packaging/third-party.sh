#!/usr/bin/env bash
# Paket pihak ketiga untuk repo APT Kirana (tidak ada di arsip Ubuntu 24.04):
#   fastfetch - .deb resmi dari rilis GitHub (MIT)
#   starship  - dibungkus jadi .deb dari biner resmi (ISC)
# Versi dikunci; SHA256 dicek dari berkas checksum resmi bila tersedia.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${OUT:-$ROOT/dist}
WORK=${WORK:-$ROOT/build}/third-party
FASTFETCH_VER=2.71.0
STARSHIP_VER=1.27.0
mkdir -p "$OUT" "$WORK"

for a in amd64:amd64 arm64:aarch64; do
  deb=${a%%:*}; up=${a##*:}
  curl -fsSL -o "$OUT/fastfetch_${FASTFETCH_VER}_${deb}.deb" \
    "https://github.com/fastfetch-cli/fastfetch/releases/download/$FASTFETCH_VER/fastfetch-linux-$up.deb"
  echo "==> fastfetch $FASTFETCH_VER ($deb)"
done

for a in amd64:x86_64 arm64:aarch64; do
  deb=${a%%:*}; up=${a##*:}
  f=starship-$up-unknown-linux-musl.tar.gz
  base=https://github.com/starship/starship/releases/download/v$STARSHIP_VER
  curl -fsSL -o "$WORK/$f" "$base/$f"
  curl -fsSL -o "$WORK/$f.sha256" "$base/$f.sha256"
  echo "$(cat "$WORK/$f.sha256")  $WORK/$f" | sha256sum -c - >/dev/null
  D=$WORK/starship-$deb; rm -rf "$D"; mkdir -p "$D/DEBIAN" "$D/usr/bin" "$D/usr/share/doc/starship"
  tar -xzf "$WORK/$f" -C "$D/usr/bin" starship
  chmod 755 "$D/usr/bin/starship"
  printf 'Upstream: https://github.com/starship/starship\nLicense: ISC\nRepackaged for Kirana OS from the official v%s release binary.\n' "$STARSHIP_VER" > "$D/usr/share/doc/starship/copyright"
  cat > "$D/DEBIAN/control" <<EOF
Package: starship
Version: $STARSHIP_VER-1kirana1
Architecture: $deb
Maintainer: vianziro <vianziro@users.noreply.github.com>
Homepage: https://starship.rs
Section: shells
Priority: optional
Description: prompt shell minimal, cepat, dan bisa dikustomisasi
 Biner resmi Starship v$STARSHIP_VER, dibungkus untuk repositori Kirana OS.
EOF
  dpkg-deb --root-owner-group -Zxz --build "$D" "$OUT/" >/dev/null
  echo "==> starship $STARSHIP_VER ($deb)"
done
