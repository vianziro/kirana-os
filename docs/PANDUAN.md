# Kirana OS 1.0 "Senja"

**Built by vianziro** · 2026.11

Kirana OS adalah hasil kustomisasi (remaster) **Ubuntu 24.04 LTS + GNOME 46**. Tujuannya bahan ajar mata kuliah kustomisasi sistem operasi. Setiap lapisan OS, mulai dari boot sampai shutdown, punya skrip sendiri supaya mahasiswa bisa membaca, mengubah, dan menjalankannya satu per satu.

> *Kirana* (bahasa Indonesia/Sanskerta) berarti "sinar" atau "indah". Kode rilis *Senja* sesuai dengan wallpaper matahari terbenam.

## Alur boot sampai shutdown

| Tahap | Yang diubah | Skrip | Berkas penting |
|---|---|---|---|
| 1. Bootloader | Tema GRUB, menu tampil 5 detik, nama "Kirana OS" | `04-boot.sh` | `/boot/grub/themes/kirana/theme.txt`, `/etc/default/grub` |
| 2. Splash boot | Plymouth: logo, "MEMULAI SISTEM", titik berdenyut | `04-boot.sh` | `/usr/share/plymouth/themes/kirana/kirana.script` |
| 3. Login | GDM: wallpaper buram, logo, aksen teal | `05-login.sh` | `gdm-theme.gresource`, `/etc/dconf/db/gdm.d/01-kirana` |
| 4. Desktop | Orchis Teal Dark, Papirus, Bibata, Inter, dock mengambang | `02-desktop-theme.sh` | `gsettings` / `dconf` |
| 5. Identitas | Nama OS, versi, logo & "built by vianziro" di About (`BUILD_ID`), hostname | `03-branding.sh` | `/usr/lib/os-release`, `/etc/lsb-release`, `/etc/issue` |
| 4b. Tampilan khas | Tema shell "Kirana": panel kaca mengambang, logo K di pojok kiri, dock kaca, widget jam besar + sapaan + statistik | `07-signature-look.sh` | `/usr/share/themes/Kirana`, `/etc/kirana/conky.conf` |
| 6. Terminal | Warna Kirana, prompt Starship, fastfetch berlogo K | `06-terminal.sh` | `/etc/kirana/*`, `~/.bashrc` |
| 7. Splash shutdown | Plymouth yang sama, teks "SAMPAI JUMPA" | `04-boot.sh` | `Plymouth.GetMode()` di `kirana.script` |
| Performa | Layanan & paket tak terpakai dimatikan | `01-debloat.sh` | `systemctl`, `apt purge` |
| Kencang | zram (swap terkompresi), snap dibuang total, Firefox `.deb` resmi Mozilla | `08-speed.sh` | `/etc/default/zramswap`, `/etc/apt/preferences.d/` |
| Wallpaper dinamis | Pagi 05:00 → siang 10:00 → senja 16:00 → malam 18:00, transisi 30 menit, tanpa daemon | `09-dynamic-wallpaper.sh` | `/usr/share/backgrounds/kirana/kirana-dinamis.xml` |
| Ganti tema | `kirana-theme senja/nord/catppuccin/gruvbox/tokyo-night` (atau Super+Shift+T): panel, dock, aplikasi, terminal, prompt, widget, wallpaper, border jendela | `11-theme-switcher.sh` | `/usr/share/kirana/themes/*.theme`, `~/.config/kirana/` |
| Keyboard & tiling | Super+Enter/B/F/Q/Space, Super+1..4 workspace, auto-tiling master+stack (Tiling Shell), contekan Super+/ | `12-keyboard-tiling.sh` | `/usr/local/bin/kirana-keys`, `gsettings` |
| Identitas distro | `ID=kirana` (ID_LIKE ubuntu debian), `lsb_release` = Kirana, sesi login "Kirana", Settings "Kirana Desktop", entri UEFI "Kirana OS", splash teks, pesan legal, tanpa iklan Ubuntu Pro, suara non-Yaru | `13-deep-rebrand.sh` | `dpkg-divert --list`, `/usr/share/kirana/diverted/` |
| Sesi X11 | Login & desktop memakai X11 karena di VirtualBox perpindahan login→desktop di Wayland bisa membeku | `14-x11-session.sh` | `/etc/gdm3/custom.conf` |
| Layar beku setelah login | Hook PAM: begitu sesi dibuka, layar dipaksa digambar ulang (pindah konsol sebentar) | `15-display-refresh.sh` | `/usr/local/sbin/kirana-display-refresh`, `/etc/pam.d/gdm-password` |
| Optimasi lanjutan | Sisa snap dibersihkan, RDP/rsyslog/PackageKit/wait-online dimatikan, log maks 100 MB, TRIM mingguan | `16-optimize.sh` | `/etc/systemd/journald.conf.d/kirana.conf` |
| Alat distro | Perintah `kirana` (update/clean/doctor/theme/mac/info), beranda Firefox Kirana tanpa telemetri, shortcut `~/Mac` | `17-distro-tools.sh` | `/usr/local/bin/kirana`, `/etc/firefox/policies/policies.json` |
| Folder Mac | Shared folder VirtualBox `prak` → `PRAK-SO-2026` di Mac, ter-mount di `/media/mac` | (VirtualBox, sisi Mac) | `VBoxManage sharedfolder` |
| Integrasi VM | Guest Additions 7.2: clipboard, drag & drop, resize layar otomatis | `10-guest-additions.sh` | `/opt/VBoxGuestAdditions-*` |

## Cara pakai

```bash
bash install.sh      # semua langkah, berurutan
sudo reboot
```

Skrip juga bisa dijalankan satu per satu, misalnya `bash scripts/04-boot.sh`. Semua skrip aman dijalankan ulang.

## Shortcut penting

| Tombol | Aksi |
|---|---|
| Super + / | Contekan semua shortcut |
| Super + Enter / B / F | Terminal / Browser / File |
| Super + Space | Cari aplikasi |
| Super + Q | Tutup jendela |
| Super + 1…4 · Super + Shift + 1…4 | Pindah workspace · kirim jendela |
| Super + Shift + T | Ganti tema |

Membuat tema sendiri: salin `/usr/share/kirana/themes/senja.theme` jadi `namaku.theme`, ubah warnanya, lalu jalankan `kirana-theme namaku`.

## Jejak Ubuntu yang sengaja dibiarkan (dan alasannya)

| Jejak | Alasan |
|---|---|
| `uname -v` berisi `-Ubuntu` | String bawaan kernel saat dikompilasi. Menggantinya berarti membangun kernel sendiri. |
| Mirror `ports.ubuntu.com` di apt | Kirana memakai repositori Ubuntu, sama seperti Linux Mint dan Pop!_OS. |
| Nama paket/ekstensi (`ubuntu-dock`, `ubuntu.desktop`) | Nama internal. Mengganti namanya akan memutus update. |
| Folder `/boot/efi/EFI/ubuntu` | Dipakai shim/GRUB saat update. Label di menu UEFI sudah "Kirana OS". |
| `add-apt-repository ppa:...` | Bisa menolak karena ID bukan `ubuntu`. Tambahkan PPA manual lewat `/etc/apt/sources.list.d/`. |

## Bahan diskusi untuk mahasiswa

- **Mengapa `ID=ubuntu` tidak diganti?** `apt`, `snap`, dan `ubuntu-drivers` membaca `ID`/`VERSION_CODENAME`. Yang diganti cukup `NAME`/`PRETTY_NAME`/`LOGO`, sehingga OS tetap kompatibel dengan repositori Ubuntu.
- **`dpkg-divert`**: berkas `/usr/lib/os-release` milik paket `base-files`. Divert mencegah update menimpa branding.
- **`update-alternatives`**: cara Debian/Ubuntu memilih "tema aktif" untuk Plymouth dan GDM.
- **gresource**: tema GNOME Shell untuk GDM dikemas biner. Isinya diekstrak, CSS-nya diubah, lalu dikompilasi ulang.
- **Mengganti logo About Ubuntu**: Settings di Ubuntu memakai `/usr/share/pixmaps/ubuntu-logo-text*.png` secara hardcode, sehingga berkas itu di-*divert* lalu diganti.
- **Plymouth script**: satu tema dipakai untuk boot dan shutdown. Mode yang sedang berjalan dibedakan lewat `Plymouth.GetMode()`.

## Mengembalikan ke Ubuntu asli (ringkas)

```bash
sudo update-alternatives --auto default.plymouth && sudo update-initramfs -u
sudo update-alternatives --auto gdm-theme.gresource
sudo rm /usr/lib/os-release && sudo dpkg-divert --rename --remove /usr/lib/os-release
for f in /usr/share/pixmaps/ubuntu-logo-text{,-dark}.png; do sudo rm $f; sudo dpkg-divert --rename --remove $f; done
gsettings set org.gnome.shell.extensions.user-theme name ''; sudo rm -f /etc/xdg/autostart/kirana-widget.desktop
sudo sed -i '/GRUB_THEME=/d' /etc/default/grub && sudo update-grub
gsettings reset-recursively org.gnome.desktop.interface
```

## Catatan keamanan (lab)

Selama proses setup, user `vianziro` diberi `sudo` tanpa password lewat `/etc/sudoers.d/99-claude-temp`. Hapus setelah selesai:

```bash
sudo rm /etc/sudoers.d/99-claude-temp
```
