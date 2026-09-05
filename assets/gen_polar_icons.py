#!/usr/bin/env python3
"""Ikonice kapija polarnog sveta (256×256).

Dve su složene od kupljenih crteža (pingvin na nagibu, štap sa ribom), dve su
SVG u stilu ostalih ikonica (šal i kapa, polarna svetlost) — isti obrub
#4A3F3A debljine 10 kao icon-egg / icon-stone-stack.
"""
from PIL import Image, ImageDraw
import os

ROOT = os.path.join(os.path.dirname(__file__), '..', 'game', 'art')
POLAR = os.path.join(ROOT, 'polar')
SVG = os.path.join(ROOT, 'svg')
INK = (74, 63, 58, 255)
S = 256
SS = 4   # crta se 4× veće pa smanjuje — glatke ivice


def canvas():
    return Image.new('RGBA', (S * SS, S * SS), (0, 0, 0, 0))


def finish(im, name):
    im = im.resize((S, S), Image.LANCZOS)
    im.save(os.path.join(POLAR, name + '.png'), optimize=True)
    print(name, im.size)


def fit(im, h):
    return im.resize((round(im.width * h / im.height), h), Image.LANCZOS)


# --- klizanje: pingvin raširenih krila juri niz ledeni breg -------------------
im = canvas()
d = ImageDraw.Draw(im)
k = SS
# breg: ledena padina sa snegom na vrhu, od gore-levo ka dole-desno
slope = [(20 * k, 120 * k), (150 * k, 205 * k), (240 * k, 236 * k), (240 * k, 246 * k), (16 * k, 246 * k)]
d.polygon(slope, fill=(190, 236, 248, 255), outline=INK, width=10 * k)
d.line([(20 * k, 120 * k), (150 * k, 205 * k), (240 * k, 236 * k)], fill=(255, 255, 255, 255), width=18 * k)
# tragovi brzine iza pingvina
for i, (x, y) in enumerate([(40, 58), (30, 82), (48, 104)]):
    d.line([(x * k, y * k), ((x + 34) * k, (y + 10) * k)], fill=INK, width=8 * k)
p = Image.open(os.path.join(POLAR, 'penguin-jump-5.png')).convert('RGBA')
p = fit(p, 178 * k).rotate(-28, resample=Image.BICUBIC, expand=True)
im.alpha_composite(p, (112 * k - p.width // 2 + 10 * k, 108 * k - p.height // 2))
finish(im, 'icon-slide')

# --- pecanje: štap, rupa u ledu i riba na udici ---------------------------------
im = canvas()
d = ImageDraw.Draw(im)
# ledena ploča sa rupom
d.rounded_rectangle((16 * k, 150 * k, 240 * k, 240 * k), radius=30 * k, fill=(222, 243, 250, 255), outline=INK, width=10 * k)
d.ellipse((92 * k, 170 * k, 176 * k, 212 * k), fill=(84, 196, 232, 255), outline=INK, width=8 * k)
rod = Image.open(os.path.expanduser('~/Downloads/Fishinggameassetpack--1m5e09809q6k1o0889/rod/keyframes/rod_04.png')).convert('RGBA')
rod = rod.crop(rod.getbbox())
rod = rod.resize((round(rod.width * 230 * k / rod.width), round(rod.height * 230 * k / rod.width)), Image.LANCZOS)
rod = rod.rotate(-42, resample=Image.BICUBIC, expand=True)
im.alpha_composite(rod, (0, 0))
# strunа od vrha štapa do ribe
d = ImageDraw.Draw(im)
d.line([(198 * k, 36 * k), (134 * k, 150 * k)], fill=INK, width=4 * k)
fish = Image.open(os.path.join(ROOT, 'ocean', 'fc-orange-1.png')).convert('RGBA')
fish = fish.crop(fish.getbbox())
fish = fit(fish, 74 * k).rotate(70, resample=Image.BICUBIC, expand=True)
im.alpha_composite(fish, (134 * k - fish.width // 2, 152 * k - fish.height // 2))
finish(im, 'icon-fishing')

# --- šal i kapa (SVG) -------------------------------------------------------------
clothes = '''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
<g stroke="#4A3F3A" stroke-width="10" stroke-linejoin="round" stroke-linecap="round">
  <!-- kapa: crvena sa belim obodom i ćubom -->
  <path d="M62,118 C62,52 194,52 194,118 Z" fill="#E2574C"></path>
  <rect x="48" y="104" width="160" height="34" rx="17" fill="#FDFBF6"></rect>
  <circle cx="128" cy="52" r="20" fill="#FDFBF6"></circle>
  <!-- šal: plav sa prugama, jedan kraj pada -->
  <path d="M52,158 L204,158 L204,196 L52,196 Z" fill="#4C9BD6"></path>
  <path d="M140,196 L196,196 L184,244 L128,244 Z" fill="#4C9BD6"></path>
</g>
<g fill="#FDFBF6">
  <rect x="76" y="158" width="18" height="38"></rect>
  <rect x="118" y="158" width="18" height="38"></rect>
  <rect x="160" y="158" width="18" height="38"></rect>
  <rect x="146" y="200" width="16" height="40" transform="skewX(-14) translate(50 0)"></rect>
</g>
<g stroke="#4A3F3A" stroke-width="8" stroke-linecap="round">
  <line x1="136" y1="232" x2="136" y2="246"></line>
  <line x1="154" y1="232" x2="154" y2="246"></line>
  <line x1="172" y1="232" x2="172" y2="246"></line>
</g>
</svg>
'''
with open(os.path.join(SVG, 'icon-clothes.svg'), 'w') as f:
    f.write(clothes)
print('icon-clothes.svg')

# --- polarna svetlost (SVG): noćno nebo u krugu, zelene i roze trake, zvezde ------
aurora = '''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
<defs>
  <clipPath id="c"><circle cx="128" cy="128" r="98"></circle></clipPath>
</defs>
<circle cx="128" cy="128" r="98" fill="#2B3A6B" stroke="#4A3F3A" stroke-width="10"></circle>
<g clip-path="url(#c)" stroke-linecap="round" fill="none" opacity="0.95">
  <path d="M20,150 C60,90 100,170 140,110 C170,70 200,120 240,80" stroke="#7BE495" stroke-width="30"></path>
  <path d="M10,180 C50,130 90,200 130,140 C160,100 200,150 250,110" stroke="#F49AC2" stroke-width="22"></path>
  <path d="M30,120 C70,70 110,140 150,90 C180,55 210,100 240,60" stroke="#B9F0FF" stroke-width="12"></path>
</g>
<g fill="#FDFBF6">
  <circle cx="60" cy="70" r="5"></circle>
  <circle cx="190" cy="52" r="4"></circle>
  <circle cx="86" cy="196" r="4"></circle>
  <circle cx="176" cy="188" r="6"></circle>
  <circle cx="128" cy="204" r="3"></circle>
</g>
<circle cx="128" cy="128" r="98" fill="none" stroke="#4A3F3A" stroke-width="10"></circle>
</svg>
'''
with open(os.path.join(SVG, 'icon-aurora.svg'), 'w') as f:
    f.write(aurora)
print('icon-aurora.svg')
