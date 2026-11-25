# Kirana OS - shell interaktif (dibaca login shell; GNOME Terminal Kirana memakai login shell)
# Prompt Starship + fastfetch. Konfigurasi user (~/.config/kirana) dipakai bila ada (hasil kirana-theme).
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac
[ -n "$KIRANA_SHELL_INIT" ] && return 0
export KIRANA_SHELL_INIT=1

_kirana_cfg() { [ -f "$HOME/.config/kirana/$1" ] && echo "$HOME/.config/kirana/$1" || echo "/etc/kirana/$1"; }
export STARSHIP_CONFIG="$(_kirana_cfg starship.toml)"

if [ -n "$BASH_VERSION" ] && command -v starship >/dev/null 2>&1; then
  # dijalankan tepat sebelum prompt pertama, SETELAH ~/.bashrc, agar PS1 bawaan tidak menimpanya
  _kirana_prompt_init() {
    PROMPT_COMMAND="${PROMPT_COMMAND#_kirana_prompt_init;}"
    [ -z "$STARSHIP_SHELL" ] && eval "$(starship init bash)"
    unset -f _kirana_prompt_init
  }
  PROMPT_COMMAND="_kirana_prompt_init;${PROMPT_COMMAND}"
fi

if [ -z "$SSH_CONNECTION" ] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch -c "$(_kirana_cfg fastfetch.jsonc)" 2>/dev/null
fi
alias ff='fastfetch -c "$(_kirana_cfg fastfetch.jsonc)"'
alias ll='ls -lh --color=auto --group-directories-first'
