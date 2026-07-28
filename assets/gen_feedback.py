#!/usr/bin/env python3
"""Foley feedback zvuci (po istrazivanju dec. appova):
pluck (uzimanje), plop (spustanje-tacno), nom (zvakanje), wrong (najnezniji 'hm?'),
success_1/2 (varijacije zvona), buzz (komarac). -> game/sfx/"""
import wave, struct, math, os, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "sfx")
random.seed(3)

def save(name, samples, vol=1.0):
    peak = max(1e-6, max(abs(s) for s in samples))
    norm = [max(-1, min(1, s / peak * vol)) for s in samples]
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in norm))
    print("ok", name)

def env(i, n, a, r):
    t = i / SR; rem = (n - i) / SR
    return min(1.0, t / a) * min(1.0, rem / r)

def tone(dur, freq_fn, harm=(1.0, 0.3), a=0.004, r=0.15, noise=0.0):
    n = int(dur * SR); out = []; ph = 0.0
    for i in range(n):
        t = i / SR
        ph += 2 * math.pi * freq_fn(t) / SR
        s = sum(h * math.sin(ph * (k + 1)) for k, h in enumerate(harm))
        s += noise * (random.random() * 2 - 1)
        out.append(s * env(i, n, a, r))
    return out

def silence(d): return [0.0] * int(d * SR)

# PLUCK — branje bobice: kratak pad visine, brz decay
save("pluck.wav", tone(0.09, lambda t: 560 - 1600 * t, harm=(1, 0.4, 0.1), a=0.002, r=0.06), 0.7)

# PLOP — soc no spustanje: dubok brzi pad + mali klik
plop = tone(0.11, lambda t: 300 - 1500 * t if t < 0.09 else 130, harm=(1, 0.5), a=0.002, r=0.05)
plop = tone(0.012, lambda t: 1200, harm=(1,), a=0.001, r=0.008) + plop
save("plop.wav", plop, 0.8)

# NOM — dva "zalogaja": sum + niski tup, x2
def bite():
    n = int(0.11 * SR); lp = 0.0; out = []
    for i in range(n):
        lp += 0.35 * ((random.random() * 2 - 1) - lp)
        th = math.sin(2 * math.pi * 150 * i / SR) * 0.7
        out.append((lp * 1.2 + th) * env(i, n, 0.004, 0.05))
    return out
save("nom.wav", bite() + silence(0.09) + bite(), 0.75)

# WRONG — najnezniji "hm?": dva tiha silazna tona (mol terca), mekan napad
save("wrong.wav", tone(0.16, lambda t: 392, harm=(1, 0.15), a=0.05, r=0.08) + silence(0.03)
	+ tone(0.22, lambda t: 330, harm=(1, 0.15), a=0.05, r=0.14), 0.42)

# SUCCESS varijacije (uz postojeci C-E-G-C)
def chime(freqs):
    out = []
    for f in freqs:
        out += tone(0.12, lambda t, ff=f: ff, harm=(1, 0.2), a=0.005, r=0.2)
    return out
save("success_1.wav", chime([392, 494, 587, 784]), 0.8)          # G-dur naviše
save("success_2.wav", chime([349, 440, 523, 440, 698]), 0.8)     # F-dur poskok

# BUZZ — komarac: "testera" sa vibratom i lepetom, tiho, 4s sa fade krajevima
n = int(4.0 * SR); out = []; ph = 0.0
for i in range(n):
    t = i / SR
    f = 380 + 26 * math.sin(2 * math.pi * 7.3 * t) + 10 * math.sin(2 * math.pi * 0.9 * t)
    ph += 2 * math.pi * f / SR
    s = sum(math.sin(ph * k) / k for k in (1, 2, 3, 4, 5))
    flutter = 0.75 + 0.25 * math.sin(2 * math.pi * 31 * t)
    edge = min(1.0, t / 0.25) * min(1.0, (4.0 - t) / 0.6)
    out.append(s * flutter * edge)
save("buzz.wav", out, 0.5)
