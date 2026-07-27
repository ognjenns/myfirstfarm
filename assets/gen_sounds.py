#!/usr/bin/env python3
"""Placeholder zvukovi za Moja Farma — sintetizovani, za zamenu pravim snimcima.
Generise WAV fajlove u ../game/sfx/"""
import wave, struct, math, os, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "sfx")
os.makedirs(OUT, exist_ok=True)
random.seed(7)

def env(i, n, a=0.02, r=0.3):
    t = i / n
    attack = min(1.0, (i / SR) / a) if a > 0 else 1.0
    release = min(1.0, (1.0 - t) / r) if r > 0 else 1.0
    return attack * release

def save(name, samples):
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in samples))
    print("ok", name)

def tone(dur, freq_fn, vib=0.0, vib_hz=6.0, noise=0.0, a=0.02, r=0.3, harm=(1.0, 0.4, 0.15)):
    n = int(dur * SR); out = []; phase = 0.0
    for i in range(n):
        t = i / SR
        f = freq_fn(t) * (1.0 + vib * math.sin(2 * math.pi * vib_hz * t))
        phase += 2 * math.pi * f / SR
        s = sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harm))
        s += noise * (random.random() * 2 - 1)
        out.append(0.55 * s * env(i, n, a, r))
    return out

def silence(dur): return [0.0] * int(dur * SR)

# --- glasanja zivotinja (2 varijante + happy po zivotinji) ---
def cow(v):      # duboki "muu"
    d = 0.9 + 0.2 * v
    return tone(d, lambda t: 130 - 25 * t + 8 * v, vib=0.04, vib_hz=5, harm=(1, .6, .3, .1), a=.08, r=.4)
def pig(v):      # groktanje: kratki bursts
    out = []
    for k in range(3 + v):
        out += tone(.12, lambda t: 180 + 60 * math.sin(20 * t) + 15 * k, noise=.5, harm=(1, .5), a=.005, r=.2)
        out += silence(.06)
    return out
def chicken(v):  # kokodakanje staccato
    out = []
    for k in range(4 + v):
        f = 520 + (60 if k == 3 else 0) + 25 * v
        out += tone(.09, lambda t, f=f: f + 200 * t, harm=(1, .3), a=.004, r=.1)
        out += silence(.05)
    return out
def goat(v):     # "meee" sa jakim vibratom
    d = 0.7 + 0.15 * v
    return tone(d, lambda t: 300 + 20 * v, vib=0.20, vib_hz=9, harm=(1, .5, .2), a=.03, r=.25)
def horse(v):    # rzanje: silazni glissando s vibratom
    d = 0.8 + 0.15 * v
    return tone(d, lambda t: 700 - 350 * t + 30 * v, vib=0.12, vib_hz=11, noise=.12, harm=(1, .4), a=.02, r=.3)
def dog(v):      # av-av
    out = []
    for k in range(2 + (v % 2)):
        out += tone(.14, lambda t: 320 - 120 * t, noise=.25, harm=(1, .6, .2), a=.004, r=.5)
        out += silence(.10)
    return out

ANIMALS = {"cow": cow, "pig": pig, "chicken": chicken, "goat": goat, "horse": horse, "dog": dog}
BASE = {"cow": 262, "pig": 294, "chicken": 392, "goat": 330, "horse": 349, "dog": 311}

for name, fn in ANIMALS.items():
    for v in (0, 1):
        save(f"{name}_{v}.wav", fn(v))
    # happy: brzi rastuci arpeggio na "visini" zivotinje
    b = BASE[name]; out = []
    for ratio in (1, 1.25, 1.5, 2):
        out += tone(.11, lambda t, f=b * ratio: f, harm=(1, .3, .1), a=.005, r=.15)
    save(f"{name}_happy.wav", out)

# --- UI / feedback ---
out = []
for f in (523, 659, 784, 1047):  # uspeh: C-E-G-C
    out += tone(.12, lambda t, f=f: f, harm=(1, .2), a=.005, r=.2)
save("success.wav", out)

save("pop.wav", tone(.09, lambda t: 400 + 900 * t, harm=(1,), a=.002, r=.05))
save("wrong.wav", tone(.25, lambda t: 220, vib=.03, harm=(1, .2), a=.02, r=.5))  # blag, ne strasan
save("tap.wav", tone(.05, lambda t: 600 + 300 * t, harm=(1,), a=.002, r=.04))

# pljusak/voda: filtriran sum
n = int(0.6 * SR); lp = 0.0; out = []
for i in range(n):
    lp += 0.25 * ((random.random() * 2 - 1) - lp)
    out.append(0.8 * lp * env(i, n, .05, .4))
save("splash.wav", out)

# trljanje/pena: mekan sum u talasima
n = int(0.4 * SR); lp = 0.0; out = []
for i in range(n):
    t = i / SR
    lp += 0.12 * ((random.random() * 2 - 1) - lp)
    out.append(0.9 * lp * (0.6 + 0.4 * math.sin(2 * math.pi * 8 * t)) * env(i, n, .03, .3))
save("scrub.wav", out)

# fanfara za kraj scene (konfete)
out = []
for f in (392, 523, 659, 784, 659, 784, 1047):
    out += tone(.13, lambda t, f=f: f, harm=(1, .3, .1), a=.004, r=.18)
save("fanfare.wav", out)

print("Gotovo:", len(os.listdir(OUT)), "fajlova u", os.path.abspath(OUT))
