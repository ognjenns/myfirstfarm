#!/usr/bin/env python3
"""Blaga pentatonska uspavanka-loop za hub (placeholder dok ne dodje prava muzika).
Pise game/sfx/music.wav — tiho, toplo, bez ostrih napada."""
import wave, struct, math, os, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "sfx", "music.wav")
random.seed(11)

BPM = 84.0
BEAT = 60.0 / BPM
BARS = 8
TOTAL = BARS * 4 * BEAT
N = int(TOTAL * SR)

# C-dur pentatonika
PENTA = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25]
BASS = [130.81, 98.00, 110.00, 130.81, 130.81, 98.00, 110.00, 130.81]  # C G A C po taktu

buf = [0.0] * N

def pluck(t0, freq, dur, vol):
    """Mekan 'marimba' ton: sinus + 2. harmonik, spor napad, dug rep."""
    n0 = int(t0 * SR)
    nd = int(dur * SR)
    for i in range(nd):
        idx = n0 + i
        if idx >= N:
            idx -= N  # prelij preko kraja → besavan loop
        t = i / SR
        env = min(1.0, t / 0.04) * math.exp(-2.2 * t / dur)
        s = math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(4 * math.pi * freq * t)
        # blagi detune za toplinu
        s += 0.4 * math.sin(2 * math.pi * freq * 1.003 * t)
        buf[idx] += vol * env * s

# bas: jedna nota po taktu
for bar in range(BARS):
    pluck(bar * 4 * BEAT, BASS[bar], 4 * BEAT * 0.95, 0.10)

# melodija: lagani random walk po pentatonici, sa pauzama
note_idx = 2
for bar in range(BARS):
    for beat in range(4):
        for half in range(2):
            t0 = (bar * 4 + beat + half * 0.5) * BEAT
            if random.random() < 0.38:
                continue  # pauza — da diše
            note_idx = max(0, min(len(PENTA) - 1, note_idx + random.choice([-2, -1, -1, 0, 1, 1, 2])))
            # poslednji takt smiri ka C
            if bar == BARS - 1 and beat >= 2:
                note_idx = max(0, note_idx - 1) if note_idx > 0 else 0
            pluck(t0, PENTA[note_idx], BEAT * 1.6, 0.055)

peak = max(abs(s) for s in buf)
buf = [s / peak * 0.5 for s in buf]

with wave.open(OUT, "w") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in buf))
print("music.wav:", round(TOTAL, 1), "s")
