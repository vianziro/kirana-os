#!/bin/bash
# Kirana OS - 17: Alat & pengalaman distro
#   - perintah `kirana` (update, clean, doctor, theme, mac, ...)
#   - Firefox: beranda Kirana, tanpa telemetri/iklan/halaman sambutan
#   - folder Mac: shortcut ~/Mac + bookmark di Files
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"

echo "[1/3] Perintah kirana"
sudo install -m755 "$HERE/assets/bin/kirana" /usr/local/bin/kirana

echo "[2/3] Firefox: beranda Kirana + privasi"
sudo mkdir -p /usr/share/kirana/start /etc/firefox/policies
sudo cp "$HERE/assets/start/index.html" /usr/share/kirana/start/index.html
# README jadi halaman HTML sederhana untuk tautan "Panduan Kirana"
{ echo '<!doctype html><meta charset="utf-8"><title>Panduan Kirana OS</title>'
  echo '<style>body{font-family:Inter,sans-serif;max-width:860px;margin:40px auto;padding:0 20px;background:#0E1230;color:#E6E4FF;line-height:1.6}a{color:#2BC4B6}pre,code{background:#1B1D36;padding:2px 6px;border-radius:6px}table{border-collapse:collapse}td,th{border:1px solid #333;padding:6px}</style><pre style="white-space:pre-wrap">'
  sed 's/&/\&amp;/g; s/</\&lt;/g' "$HERE/README.md"; echo '</pre>'; } | sudo tee /usr/share/kirana/README.html >/dev/null
sudo tee /etc/firefox/policies/policies.json >/dev/null <<'EOF'
{
  "policies": {
    "Homepage": { "URL": "file:///usr/share/kirana/start/index.html", "StartPage": "homepage", "Locked": false },
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DontCheckDefaultBrowser": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "FirefoxHome": { "SponsoredTopSites": false, "SponsoredPocket": false, "Pocket": false, "Locked": false },
    "UserMessaging": { "WhatsNew": false, "ExtensionRecommendations": false, "FeatureRecommendations": false, "SkipOnboarding": true, "MoreFromMozilla": false }
  }
}
EOF

echo "[3/3] Folder Mac: ~/Mac + bookmark Files"
sudo usermod -aG vboxsf "$USER"
ln -sfn /media/mac ~/Mac
mkdir -p ~/.config/gtk-3.0
grep -q "file:///media/mac" ~/.config/gtk-3.0/bookmarks 2>/dev/null || echo "file:///media/mac Mac · PRAK-SO-2026" >> ~/.config/gtk-3.0/bookmarks
echo "Selesai. Coba: kirana help"
