#!/usr/bin/env python3
"""Kirana OS - buat 4 varian wallpaper (pagi, siang, senja, malam) dari wallpaper.svg.
Cara pakai: python3 make_variants.py <wallpaper.svg> <folder-output>
Semua varian berbagi bentuk gunung yang sama; yang berubah hanya warna langit,
posisi & warna matahari/bulan, dan warna gunung."""
import sys, os

src, out = sys.argv[1], sys.argv[2]
base = open(src).read()
os.makedirs(out, exist_ok=True)

SKY = ['#0E1230', '#3A2A6B', '#C2477A', '#FF9A5A']
SUN = ['#FFE29A', '#FF7A45']
MTN = ['#6B2F7A', '#3B2260', '#21194A', '#120F2E']

V = {
  'pagi':  dict(sky=['#2B3A67', '#6E7FB8', '#F2A7A0', '#FFD9A8'], sun=['#FFF4D6', '#FFC98A'],
                glow='#FFE3B0', mtn=['#7A7FC0', '#565C9E', '#393E78', '#23264F'],
                dy=180, stripes=0.6, stars=0.25),
  'siang': dict(sky=['#2E8FD9', '#5BB4EC', '#A6DBF5', '#E4F6FC'], sun=['#FFFFFF', '#FFF0B3'],
                glow='#FFFFFF', mtn=['#5BB7B3', '#33918F', '#1F6E73', '#134B55'],
                dy=-560, stripes=0, stars=0),
  'senja': dict(sky=SKY, sun=SUN, glow='#FFB36B', mtn=MTN, dy=0, stripes=1, stars=0.7),
  'malam': dict(sky=['#04050D', '#0A0D22', '#151838', '#24224F'], sun=['#F4F2FF', '#BFC3EE'],
                glow='#9FA8FF', mtn=['#2A2560', '#1C1847', '#120F33', '#09081E'],
                dy=-420, stripes=0, stars=1),
}

for name, v in V.items():
    s = base
    for a, b in zip(SKY, v['sky']): s = s.replace(f'stop-color="{a}"', f'stop-color="{b}"', 1)
    for a, b in zip(SUN, v['sun']): s = s.replace(f'stop-color="{a}"', f'stop-color="{b}"', 1)
    s = s.replace('stop-color="#FFB36B"', f'stop-color="{v["glow"]}"')
    for a, b in zip(MTN, v['mtn']): s = s.replace(f'fill="{a}"', f'fill="{b}"', 1)
    s = s.replace('<g fill="#C2477A">', f'<g fill="{v["sky"][2]}" opacity="{v["stripes"]}">')
    s = s.replace('<g fill="#FFFFFF" opacity="0.7">', f'<g fill="#FFFFFF" opacity="{v["stars"]}">')
    # geser matahari/bulan (glow + piringan) secara vertikal
    s = s.replace('<circle cx="2560" cy="1180" r="900"', f'<g transform="translate(0,{v["dy"]})"><circle cx="2560" cy="1180" r="900"', 1)
    s = s.replace('<!-- pegunungan berlapis -->', '</g>\n  <!-- pegunungan berlapis -->', 1)
    open(os.path.join(out, f'{name}.svg'), 'w').write(s)
    print('ok', name)
