#!/bin/bash
h=$(date +%H); n=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1); n=${n:-$USER}
if   [ $h -lt 11 ]; then s="Selamat pagi"
elif [ $h -lt 15 ]; then s="Selamat siang"
elif [ $h -lt 18 ]; then s="Selamat sore"
else s="Selamat malam"; fi
echo "$s, $n"
