#!/usr/bin/env python3
"""Splash džingl (~5s) uklopljen u animaciju loga:
0.0-2.2  spin: whoosh (sum) + uzlazni gliss
2.2      sletanje: mekan tup + sparkle arpeggio
3.2      namig-gore: boing + ding
3.75     namig-dole: kratki silazni boing
4.1-5.0  topli zavrsni akord
Pise game/sfx/splash_theme.wav"""
import wave, struct, math, os, random

SR = 22050
DUR = 5.0
N = int(DUR * SR)
random.seed(5)
buf = [0.0] * N

def add(t0, samples, vol=1.0):
    n0 = int(t0 * SR)
    for i, s in enumerate(samples):
        idx = n0 + i
        if 0 <= idx < N:
            buf[idx] += s * vol

def env_ar(n, a, r):
    out = []
    for i in range(n):
        t = i / SR
        rem = (n - i) / SR
        out.append(min(1.0, t / a) * min(1.0, rem / r))
    return out

def tone(dur, freq_fn, harm=(1.0, 0.35, 0.12), a=0.01, r=0.2, vib=0.0):
    n = int(dur * SR); out = []; ph = 0.0
    e = env_ar(n, a, r)
    for i in range(n):
        t = i / SR
        f = freq_fn(t) * (1.0 + vib * math.sin(2 * math.pi * 5.5 * t))
        ph += 2 * math.pi * f / SR
        s = sum(h * math.sin(ph * (k + 1)) for k, h in enumerate(harm))
        out.append(s * e[i])
    return out

# 1) WHOOSH — filtriran sum koji raste pa se stisa (prati brzo->sporo vrtenje)
n = int(2.3 * SR); lp = 0.0; out = []
for i in range(n):
    t = i / SR
    k = t / 2.3
    cutoff = 0.04 + 0.30 * (1.0 - k) ** 1.5  # svetlije na pocetku (brzo), tamnije kako usporava
    lp += cutoff * ((random.random() * 2 - 1) - lp)
    amp = math.sin(math.pi * min(1.0, k * 1.15)) ** 0.8
    out.append(lp * amp)
add(0.0, out, 0.55)

# 2) GLISS — uzlazni portamento (pentatonika u duhu), sa vibratom pri vrhu
add(0.0, tone(2.2, lambda t: 196.0 * (2.0 ** (t / 2.2 * 2.0)), harm=(1, 0.4, 0.15), a=0.15, r=0.5, vib=0.02), 0.30)

# 3) SLETANJE (2.2s): mekan niski tup + sparkle arpeggio
add(2.2, tone(0.35, lambda t: 98.0, harm=(1, 0.5), a=0.004, r=0.3), 0.5)
for j, ratio in enumerate([1, 1.25, 1.5, 2, 2.5, 3]):
    add(2.28 + j * 0.055, tone(0.5, lambda t, f=523.25 * ratio: f, harm=(1, 0.2), a=0.003, r=0.45), 0.16)

# 4) NAMIG GORE (3.2s): boing (savijanje navise) + ding
add(3.2, tone(0.22, lambda t: 280.0 + 320.0 * (t / 0.22) ** 0.7, harm=(1, 0.3), a=0.005, r=0.1), 0.4)
add(3.42, tone(0.6, lambda t: 1318.5, harm=(1,), a=0.002, r=0.55), 0.18)

# 5) NAMIG DOLE (3.75s): kratki silazni boing
add(3.75, tone(0.18, lambda t: 560.0 - 220.0 * (t / 0.18), harm=(1, 0.3), a=0.005, r=0.1), 0.3)

# 6) ZAVRSNI AKORD (4.1s): topli C-dur (C-E-G-C), mekan pluck koji se gasi do kraja
for j, f in enumerate([261.63, 329.63, 392.0, 523.25]):
    add(4.1 + j * 0.03, tone(0.85, lambda t, ff=f: ff, harm=(1, 0.3, 0.1), a=0.02, r=0.7), 0.22)

peak = max(abs(s) for s in buf)
buf = [s / peak * 0.85 for s in buf]
out_path = os.path.join(os.path.dirname(__file__), "..", "game", "sfx", "splash_theme.wav")
with wave.open(out_path, "w") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in buf))
print("splash_theme.wav OK")
