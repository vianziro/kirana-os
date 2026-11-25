#!/bin/bash
# Kirana OS - 13: Hapus jejak "Ubuntu" yang terlihat pengguna
# Prinsip: file milik paket TIDAK diedit langsung, tapi dialihkan (dpkg-divert) ke
# /usr/share/kirana/diverted lalu diganti versi Kirana -> aman saat update & bisa dikembalikan.
set -e
export DEBIAN_FRONTEND=noninteractive
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
DV=/usr/share/kirana/diverted
divert() { # divert <file> : pindahkan file asli paket, kembalikan path aslinya di $DV
  local f=$1 d=$DV$1
  sudo mkdir -p "$(dirname "$d")"
  dpkg-divert --list "$f" | grep -q . || sudo dpkg-divert --quiet --local --rename --divert "$d" --add "$f"
  echo "$d"
}

echo "[1/8] Nama sesi login: Ubuntu -> Kirana"
for f in /usr/share/wayland-sessions/ubuntu.desktop /usr/share/wayland-sessions/ubuntu-wayland.desktop \
         /usr/share/xsessions/ubuntu.desktop /usr/share/xsessions/ubuntu-xorg.desktop; do
  [ -e "$f" ] || [ -e "$DV$f" ] || continue
  o=$(divert "$f")
  sed -e 's/^Name=Ubuntu on Xorg/Name=Kirana (Xorg)/' -e 's/^Name=Ubuntu on Wayland/Name=Kirana (Wayland)/' \
      -e 's/^Name=Ubuntu$/Name=Kirana/' -e '/^Name\[/d' -e '/^Comment\[/d' \
      -e 's/^Comment=.*/Comment=Sesi desktop Kirana OS/' "$o" | sudo tee "$f" >/dev/null
done

echo "[2/8] Settings: panel 'Ubuntu Desktop' -> 'Kirana Desktop'"
f=/usr/share/applications/gnome-ubuntu-panel.desktop
o=$(divert $f)
sed -e 's/^Name=Ubuntu Desktop/Name=Kirana Desktop/' -e '/^Name\[/d' -e '/^Comment\[/d' \
    -e 's/^Comment=.*/Comment=Dock, ikon desktop, dan tiling Kirana/' "$o" | sudo tee $f >/dev/null

echo "[3/8] Pesan legal & motd terminal"
o=$(divert /etc/legal)
printf '\nKirana OS 1.0 (Senja) - built by vianziro\nPerangkat lunak di sistem ini adalah perangkat lunak bebas;\nlisensi tiap program ada di /usr/share/doc/*/copyright.\n\n' | sudo tee /etc/legal >/dev/null
for m in 10-help-text 50-motd-news 91-contract-ua-esm-status 91-release-upgrade 92-unattended-upgrades; do
  sudo chmod -x /etc/update-motd.d/$m 2>/dev/null || true
done

echo "[4/8] Ubuntu Pro: iklan apt, layanan, aplikasi GUI"
o=$(divert /etc/apt/apt.conf.d/20apt-esm-hook.conf)
sudo systemctl disable --now ua-timer.timer ua-timer.service esm-cache.service ubuntu-advantage.service \
  ua-reboot-cmds.service 2>/dev/null || true
sudo apt-get -o DPkg::Lock::Timeout=600 -y -qq purge ubuntu-advantage-desktop-daemon gnome-initial-setup \
  software-properties-gtk ubuntu-docs gnome-user-docs >/dev/null 2>&1

echo "[5/8] Wallpaper Ubuntu disembunyikan dari Settings, suara Yaru diganti"
for f in /usr/share/gnome-background-properties/noble-wallpapers.xml /usr/share/gnome-background-properties/ubuntu-wallpapers.xml; do
  [ -e "$f" ] && divert "$f" >/dev/null
done
gsettings set org.gnome.desktop.sound theme-name 'freedesktop'
grep -q "desktop/sound" /etc/dconf/db/gdm.d/01-kirana || \
  printf "\n[org/gnome/desktop/sound]\ntheme-name='freedesktop'\n" | sudo tee -a /etc/dconf/db/gdm.d/01-kirana >/dev/null
sudo dconf update
# Help (yelp) berisi panduan Ubuntu -> sembunyikan dari menu
sudo mkdir -p /usr/local/share/applications
sed '/^\[Desktop Entry\]/a NoDisplay=true' /usr/share/applications/yelp.desktop | sudo tee /usr/local/share/applications/yelp.desktop >/dev/null

echo "[6/8] Splash mode teks (fallback) -> Kirana"
P=/usr/share/plymouth/themes/kirana-text
sudo mkdir -p $P
sudo tee $P/kirana-text.plymouth >/dev/null <<'EOF'
[Plymouth Theme]
Name=Kirana Text
Description=Splash mode teks Kirana OS
ModuleName=ubuntu-text

[ubuntu-text]
title=Kirana OS 1.0 Senja
black=0x0e1230
white=0xffffff
brown=0x2bc4b6
blue=0x8c88b5
EOF
sudo update-alternatives --quiet --install /usr/share/plymouth/themes/text.plymouth text.plymouth $P/kirana-text.plymouth 200
sudo update-alternatives --quiet --set text.plymouth $P/kirana-text.plymouth
sudo update-initramfs -u >/dev/null 2>&1

echo "[7/8] Entri boot UEFI bernama 'Kirana OS'"
if command -v efibootmgr >/dev/null && [ -d /sys/firmware/efi ]; then
  DISK=$(lsblk -no PKNAME "$(findmnt -no SOURCE /boot/efi)")
  PART=$(lsblk -no PARTN "$(findmnt -no SOURCE /boot/efi)")
  LOADER=$(ls /boot/efi/EFI/ubuntu/shim*.efi 2>/dev/null | head -1 | xargs -r basename)
  if [ -n "$LOADER" ] && ! sudo efibootmgr | grep -q "Kirana OS"; then
    sudo efibootmgr -q -c -d /dev/$DISK -p $PART -L "Kirana OS" -l "\\EFI\\ubuntu\\$LOADER"
  fi
  for n in $(sudo efibootmgr | grep -E '^Boot[0-9A-F]{4}\* Ubuntu' | cut -c5-8); do sudo efibootmgr -q -b $n -B; done
fi

echo "[8/8] Terapkan ulang identitas OS (ID=kirana)"
bash "$(dirname "$0")/03-branding.sh" | tail -1
echo "Selesai: $(lsb_release -ds) / ID=$(. /etc/os-release; echo $ID)"
