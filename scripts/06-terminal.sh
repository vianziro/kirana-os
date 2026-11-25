#!/bin/bash
# Kirana OS - 06: Terminal -> warna Kirana, prompt Starship, fastfetch berlogo Kirana
set -e
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
TMP=$(mktemp -d)
ARCH=$(uname -m)   # aarch64 / x86_64

echo "[1/4] Pasang fastfetch dan starship (rilis resmi GitHub)"
DEBARCH=$([ "$ARCH" = aarch64 ] && echo aarch64 || echo amd64)
wget -qO "$TMP/ff.deb" "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-$DEBARCH.deb"
sudo apt-get -o DPkg::Lock::Timeout=600 -y -qq install "$TMP/ff.deb" >/dev/null 2>&1
wget -qO "$TMP/st.tgz" "https://github.com/starship/starship/releases/latest/download/starship-$ARCH-unknown-linux-musl.tar.gz"
sudo tar -xzf "$TMP/st.tgz" -C /usr/local/bin starship

echo "[2/4] Konfigurasi global (/etc/skel ikut diisi -> user baru langsung bergaya Kirana)"
sudo mkdir -p /etc/kirana
sudo tee /etc/kirana/starship.toml >/dev/null <<'EOF'
# Kirana OS - prompt minimalis
add_newline = true
format = "$directory$git_branch$git_status$python$cmd_duration$line_break$character"

[directory]
style = "bold #2BC4B6"
truncation_length = 3
read_only = " ro"

[git_branch]
symbol = "⎇ "
style = "#B9A4FF"
format = "[$symbol$branch]($style) "

[git_status]
style = "#FF9A5A"

[python]
symbol = "py "
style = "#FFD27A"

[cmd_duration]
min_time = 2000
style = "#8C88B5"
format = "[⏱ $duration]($style) "

[character]
success_symbol = "[❯](bold #2BC4B6)"
error_symbol = "[❯](bold #FF5C7A)"
EOF

sudo tee /etc/kirana/logo.txt >/dev/null <<'EOF'
$1  ███   ███
$1  ███  ███
$1  ███████     $2●
$1  ███  ███
$1  ███   ███

$3  kirana os
EOF
sudo tee /etc/kirana/fastfetch.jsonc >/dev/null <<'EOF'
{
  "logo": { "source": "/etc/kirana/logo.txt", "type": "file",
            "color": { "1": "38;2;43;196;182", "2": "38;2;255;154;90", "3": "38;2;140;136;181" },
            "padding": { "top": 1, "right": 4 } },
  "display": { "separator": "  ", "color": { "keys": "38;2;43;196;182" } },
  "modules": [
    { "type": "title", "color": { "user": "38;2;255;255;255", "at": "38;2;140;136;181", "host": "38;2;43;196;182" } },
    { "type": "separator", "string": "─", "outputColor": "38;2;140;136;181" },
    { "type": "os",       "key": "os    " },
    { "type": "kernel",   "key": "kernel" },
    { "type": "uptime",   "key": "uptime" },
    { "type": "packages", "key": "pkgs  " },
    { "type": "de",       "key": "de    " },
    { "type": "theme",    "key": "theme " },
    { "type": "icons",    "key": "icons " },
    { "type": "cpu",      "key": "cpu   " },
    { "type": "memory",   "key": "ram   " },
    { "type": "disk",     "key": "disk  ", "folders": "/" },
    { "type": "custom",   "key": "build ", "format": "vianziro · 2026.11" },
    "break",
    { "type": "colors", "symbol": "circle" }
  ]
}
EOF

BASHRC_SNIPPET='
# ---- Kirana OS ----
export STARSHIP_CONFIG=/etc/kirana/starship.toml
command -v starship >/dev/null && eval "$(starship init bash)"
[[ $- == *i* ]] && command -v fastfetch >/dev/null && fastfetch -c /etc/kirana/fastfetch.jsonc
alias ff="fastfetch -c /etc/kirana/fastfetch.jsonc"
alias ll="ls -lh --color=auto --group-directories-first"
# ---- /Kirana OS ----'
for rc in ~/.bashrc /etc/skel/.bashrc; do
  if ! grep -q "Kirana OS ----" $rc 2>/dev/null; then
    if [ -w "$rc" ]; then echo "$BASHRC_SNIPPET" >> $rc; else echo "$BASHRC_SNIPPET" | sudo tee -a $rc >/dev/null; fi
  fi
done

echo "[3/4] Profil warna GNOME Terminal 'Kirana'"
PID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
P=/org/gnome/terminal/legacy/profiles:/:$PID/
dconf write ${P}visible-name "'Kirana'"
dconf write ${P}use-theme-colors false
dconf write ${P}background-color "'#11132A'"
dconf write ${P}foreground-color "'#DCDCF0'"
dconf write ${P}bold-color-same-as-fg true
dconf write ${P}cursor-colors-set true
dconf write ${P}cursor-background-color "'#2BC4B6'"
dconf write ${P}cursor-foreground-color "'#11132A'"
dconf write ${P}palette "['#1B1D36','#FF5C7A','#2BC4B6','#FFD27A','#6C8CFF','#B9A4FF','#4FD6E0','#DCDCF0','#4A4870','#FF7A95','#5FE0D2','#FFE29A','#8CA6FF','#D0C2FF','#7FE6EE','#FFFFFF']"
dconf write ${P}use-system-font false
dconf write ${P}font "'JetBrains Mono 11'"
dconf write ${P}scrollbar-policy "'never'"
dconf write ${P}use-transparent-background false
dconf write ${P}background-transparency-percent 6
dconf write ${P}default-size-columns 100
dconf write ${P}default-size-rows 28
dconf write /org/gnome/terminal/legacy/headerbar false 2>/dev/null || true

echo "[4/4] Uji"
fastfetch -c /etc/kirana/fastfetch.jsonc --pipe false | head -3 >/dev/null && echo "fastfetch OK"
starship --version | head -1
rm -rf "$TMP"
echo "Terminal selesai."
