# Kirana OS

**Distro ringan, keren, dan minimalis berbasis Ubuntu 24.04 LTS · built by vianziro**

Kirana OS mengubah Ubuntu 24.04 (GNOME) menjadi distro dengan identitasnya sendiri: tema GRUB, splash boot dan shutdown, layar login, desktop kaca dengan auto-tiling, lima tema yang bisa diganti dengan satu perintah, dan alat `kirana`. Semuanya dikirim sebagai **paket `.deb`** lewat repositori APT bertanda tangan yang di-host di GitHub Releases. Pembaruannya cukup lewat `apt`, dan semuanya bisa dicopot bersih.

> *Kirana* berarti "sinar" atau "indah". Rilis 1.0 bernama *Senja*.

## Pasang

Di Ubuntu 24.04 Desktop (GNOME), arsitektur amd64 atau arm64:

```bash
curl -fsSL https://github.com/vianziro/kirana-os/releases/latest/download/kirana-archive-keyring.gpg \
  | sudo tee /usr/share/keyrings/kirana-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/kirana-archive-keyring.gpg] https://github.com/vianziro/kirana-os/releases/latest/download/ ./" \
  | sudo tee /etc/apt/sources.list.d/kirana.list
sudo apt update
sudo apt install kirana-desktop
sudo reboot
```

Mencopot semua komponen dan mengembalikan identitas Ubuntu:

```bash
sudo apt purge kirana-desktop kirana-branding kirana-themes kirana-tools kirana-vm
```

## Paket

| Paket | Isi |
|---|---|
| `kirana-desktop` | Metapaket + pengaturan bawaan desktop (dconf), journald, sysctl untuk zram |
| `kirana-branding` | `os-release` (`ID=kirana`), logo, GRUB, Plymouth, layar login, About, beranda Firefox. File Ubuntu dialihkan dengan `dpkg-divert`, tidak ditimpa. |
| `kirana-themes` | Orchis (Senja/Nord/Catppuccin/Gruvbox/Tokyo Night), kursor Bibata, Tiling Shell, wallpaper dinamis |
| `kirana-tools` | `kirana`, `kirana-theme`, `kirana-keys`, widget desktop, prompt Starship + fastfetch |
| `kirana-vm` | Perbaikan khusus VirtualBox. Otomatis nonaktif di PC asli. |
| `fastfetch`, `starship` | Dari rilis resmi upstream (tidak ada di arsip Ubuntu 24.04) |

## Membangun sendiri

```bash
# di Ubuntu 24.04
sudo apt install dpkg-dev git curl unzip xz-utils python3 librsvg2-bin grub-common sassc fonts-inter
bash packaging/build.sh        # paket Kirana  -> dist/
bash packaging/third-party.sh  # fastfetch & starship -> dist/
SIGNING_KEY_ID=<fingerprint> bash repo/make-flat-repo.sh   # repo APT flat bertanda tangan di dist/
```

Setiap push dan pull request membangun paket lalu **menguji pemasangan dan pencopotan di container Ubuntu 24.04 yang bersih**. Tag `v*` menerbitkan repo APT bertanda tangan sebagai aset GitHub Release, dan alamat `releases/latest/download/` selalu menunjuk rilis terbaru.

Kunci penanda tangan repo: `E992 A3C9 A18C C101 F9D3  32A0 67A9 DA8E B9CE B90B`

## Struktur

```
packaging/   build.sh, third-party.sh, maintainer scripts tiap paket
assets/      logo, wallpaper, tema, konfigurasi, alat kirana-*
repo/        generator repositori APT (flat, untuk GitHub Releases)
scripts/     versi skrip 01–17 (bahan ajar: cara kerja tiap lapisan, langkah demi langkah)
docs/        PANDUAN.md: penjelasan lengkap untuk mahasiswa
```

## Lisensi

GPL-3.0-or-later. Komponen pihak ketiga memakai lisensinya masing-masing (Orchis & Bibata GPL-3.0, Tiling Shell GPL-2.0, fastfetch MIT, Starship ISC); rinciannya ada di `packaging/copyright`.
