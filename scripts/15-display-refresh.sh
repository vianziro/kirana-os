#!/bin/bash
# Kirana OS - 15: Perbaikan layar membeku setelah login (VirtualBox, driver vmwgfx)
# Gejala: login berhasil, tapi layar tetap menampilkan gambar layar login / hitam.
# Perbaikan: sesaat setelah sesi grafis dibuka, pindah ke konsol lain lalu kembali
# (sama seperti menekan Ctrl+Alt+F3 lalu Ctrl+Alt+F2) agar layar digambar ulang.
# Dipasang lewat PAM (pam_exec, "optional": kalau gagal, login tetap jalan).
set -e

sudo tee /usr/local/sbin/kirana-display-refresh >/dev/null <<'EOF'
#!/bin/sh
# dipanggil pam_exec saat sesi GDM dibuka (sebagai root)
[ "$PAM_TYPE" = "open_session" ] || exit 0
(
  sleep 4
  V=$(sed 's/tty//' /sys/class/tty/tty0/active 2>/dev/null)
  [ -n "$V" ] || exit 0
  chvt 63; sleep 0.4; chvt "$V"
) </dev/null >/dev/null 2>&1 &
exit 0
EOF
sudo chmod 755 /usr/local/sbin/kirana-display-refresh

for f in /etc/pam.d/gdm-password /etc/pam.d/gdm-autologin; do
  [ -f "$f" ] || continue
  grep -q kirana-display-refresh "$f" || \
    echo "session optional pam_exec.so quiet /usr/local/sbin/kirana-display-refresh" | sudo tee -a "$f" >/dev/null
done
grep -H kirana-display-refresh /etc/pam.d/gdm-*
echo "Aktif pada login berikutnya. Hapus: baris kirana-display-refresh di /etc/pam.d/gdm-password"
