#!/usr/bin/env python3
"""NE POKRETATI BEZ RAZLOGA (23.08.2026) — UI zvuci su od tada PRAVI snimci
(assets/process_mixkit_v4.sh). Ova skripta bi ih prepisala sintetičkima i
vratila 13 *_happy đinglova + fanfare koji su namerno obrisani iz igre.
Ostaje kao dokumentacija kako su sintetički zvuci bili napravljeni.

UI zvuci v3 — zamena za sintetizovane "bip" zvuke iz gen_sounds/gen_feedback.

Zasto su stari zvucali robotski:
  - cist sinus + celobrojni harmonici (orguljasti, mrtav ton)
  - linearna anvelopa (pravi udareni instrumenti opadaju eksponencijalno)
  - svi harmonici gasnu istom brzinom (u prirodi visoki gasnu prvi)
  - bez udarnog tranzijenta (nema "kontakta" cekica sa telom)
  - identicno trajanje i jacina svake note (masinski ritam)

Model ovde: udareni drveni/metalni stapic — neharmonicni parcijali, svaki sa
svojim eksponencijalnim opadanjem, + filtriran sum na udaru + kratak prostor.
-> game/sfx/
"""
import wave, struct, math, os, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "sfx")
random.seed(11)


# ---------- osnovni gradivni blokovi ----------

def mix_into(buf, part, at=0.0):
	"""Sabere `part` u `buf` pocev od trenutka `at` (sekunde), sirimo po potrebi."""
	i0 = int(at * SR)
	need = i0 + len(part)
	if need > len(buf):
		buf.extend([0.0] * (need - len(buf)))
	for i, s in enumerate(part):
		buf[i0 + i] += s
	return buf


def struck(freq, dur, partials, atk=0.0015, damp=0.6, detune=0.0):
	"""Udaren idiofon: neharmonicni parcijali, visi gasnu brze.

	partials: lista (odnos_frekvencije, relativna_jacina, faktor_trajanja)
	damp: koliko brze gasnu visi parcijali (vece = tamnije, drvenije)
	"""
	n = int(dur * SR)
	out = [0.0] * n
	for ratio, amp, tfac in partials:
		f = freq * ratio * (1.0 + random.uniform(-detune, detune))
		if f > SR * 0.45:            # bez aliasa
			continue
		tau = dur * tfac / (ratio ** damp)   # visi parcijal = krace trajanje
		w = 2 * math.pi * f / SR
		ph = random.uniform(0, 2 * math.pi)  # razlicita faza = zivlji udar
		for i in range(n):
			t = i / SR
			a = 1.0 - math.exp(-t / atk)     # mek, ali brz napad
			d = math.exp(-t / max(1e-4, tau))
			out[i] += amp * a * d * math.sin(ph + w * i)
	return out


def click(dur=0.012, cutoff=0.45, amp=1.0, lowcut=0.0):
	"""Tranzijent kontakta — kratak filtriran sum. Ovo je ono sto uvu kaze
	"nesto je dodirnulo nesto", i tacno to je falilo starim zvucima."""
	n = int(dur * SR)
	out = []
	lp = 0.0
	hp_prev = 0.0
	hp_out = 0.0
	for i in range(n):
		x = random.random() * 2 - 1
		lp += cutoff * (x - lp)
		y = lp
		if lowcut > 0.0:                      # jednopolni HP da se skine tutnjava
			hp_out = (1 - lowcut) * (hp_out + y - hp_prev)
			hp_prev = y
			y = hp_out
		out.append(amp * y * math.exp(-i / (n * 0.35)))
	return out


def lowpass(sig, hz):
	"""Jednopolni LP — skida piskavost iznad datog praga."""
	a = 1.0 - math.exp(-2 * math.pi * hz / SR)
	out = []
	z = 0.0
	for s in sig:
		z += a * (s - z)
		out.append(z)
	return out


def highpass(sig, hz):
	a = math.exp(-2 * math.pi * hz / SR)
	out = []
	prev_x = 0.0
	prev_y = 0.0
	for s in sig:
		y = a * (prev_y + s - prev_x)
		out.append(y)
		prev_x = s
		prev_y = y
	return out


def room(sig, mix=0.10, decay=0.28):
	"""Sitan Schroeder prostor. Suv zvuk = plasticni zvuk; malo prostora
	je razlika izmedju "bip iz telefona" i "nesto u sobi"."""
	delays = [int(SR * d) for d in (0.0197, 0.0273, 0.0351)]
	wet = [0.0] * (len(sig) + int(SR * decay))
	for d in delays:
		buf = [0.0] * len(wet)
		g = math.exp(-3.0 * d / SR / decay) * 0.72
		for i in range(len(wet)):
			x = sig[i] if i < len(sig) else 0.0
			buf[i] = x + (g * buf[i - d] if i >= d else 0.0)
		for i in range(len(wet)):
			wet[i] += buf[i] / len(delays)
	wet = lowpass(wet, 2600.0)                 # prostor je uvek tamniji od izvora
	out = []
	for i in range(len(wet)):
		dry = sig[i] if i < len(sig) else 0.0
		out.append(dry * (1.0 - mix) + wet[i] * mix)
	return out


def soften(sig, drive=1.4):
	"""Blaga saturacija — zaobli vrhove umesto da secka; toplije na zvucniku."""
	return [math.tanh(s * drive) / math.tanh(drive) for s in sig]


def save(name, samples, peak_db=-11.0):
	pk = max(1e-9, max(abs(s) for s in samples))
	target = 10 ** (peak_db / 20.0)
	g = target / pk
	data = [max(-1.0, min(1.0, s * g)) for s in samples]
	path = os.path.join(OUT, name)
	with wave.open(path, "w") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(SR)
		w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in data))
	print("  %-16s %5.2fs  peak %.1f dBFS" % (name, len(data) / SR, peak_db))


# ---------- profili parcijala ----------
# (odnos, jacina, faktor_trajanja)

WOOD = [(1.00, 1.00, 1.00), (3.93, 0.30, 0.40), (9.20, 0.10, 0.16)]   # marimba/drvo
BELL = [(1.00, 1.00, 1.00), (2.76, 0.26, 0.55), (5.40, 0.085, 0.28),
        (8.93, 0.025, 0.14)]                                           # muzicka kutija,
# gornji parcijali namerno prigušeni: na telefonskom zvučniku pojas 2-5 kHz
# je taj koji "vrišti", a beba ga čuje kao oštrinu.
DROP = [(1.00, 1.00, 1.00), (2.10, 0.22, 0.45)]                        # mek "bloop"


print("UI zvuci v3 ->", os.path.abspath(OUT))

# --- PLUCK: okretanje karte u memoriji. Drveno "tok", toplo, kratko. ---
s = struck(430, 0.26, WOOD, atk=0.0012, damp=0.75, detune=0.004)
s = mix_into(s, click(0.010, cutoff=0.30, amp=0.55, lowcut=0.02))
s = lowpass(s, 3200)
s = room(s, mix=0.08, decay=0.20)
save("pluck.wav", soften(s), -11.0)

# --- POP: dugmad i kartice svetova. Mek "bloop", bez piska. ---
n = int(0.20 * SR)
body = []
ph = 0.0
for i in range(n):
	t = i / SR
	f = 300 + 260 * math.exp(-t / 0.045)      # brz pad visine = "kap"
	ph += 2 * math.pi * f / SR
	e = (1.0 - math.exp(-t / 0.002)) * math.exp(-t / 0.075)
	body.append((math.sin(ph) + 0.20 * math.sin(2 * ph)) * e)
body = mix_into(body, click(0.008, cutoff=0.22, amp=0.35, lowcut=0.03))
body = lowpass(body, 2800)
save("pop.wav", soften(room(body, mix=0.07, decay=0.18)), -12.0)

# --- TAP: najlaksi dodir (kupanje, zmurke). Skoro samo tranzijent. ---
s = struck(620, 0.13, WOOD, atk=0.0010, damp=0.85, detune=0.003)
s = [x * 0.55 for x in s]
s = mix_into(s, click(0.008, cutoff=0.24, amp=0.50, lowcut=0.04))
s = lowpass(s, 3400)
save("tap.wav", soften(room(s, mix=0.06, decay=0.15)), -14.0)

# --- SUCCESS: nagrada. Muzicka kutija, pentatonika, humanizovan ritam. ---
def chime(freqs, step=0.115, dur=0.62, prof=BELL, damp=0.55, swing=0.012):
	buf = []
	t = 0.0
	for k, f in enumerate(freqs):
		note = struck(f, dur, prof, atk=0.0018, damp=damp, detune=0.005)
		vel = 0.82 + 0.18 * random.random()          # nije svaka nota isto jaka
		if k == len(freqs) - 1:
			vel = 1.0                                 # poslednja nosi kraj fraze
		note = [x * vel for x in note]
		note = mix_into(note, click(0.007, cutoff=0.28, amp=0.22, lowcut=0.05))
		mix_into(buf, note, t)
		t += step + random.uniform(-swing, swing)     # mikro-nepravilnost ritma
	buf = lowpass(buf, 2900)
	buf = highpass(buf, 140)
	return soften(room(buf, mix=0.13, decay=0.30))

# C-dur pentatonika — uvek konsonantno, bez piskavih vrhova preko ~900 Hz
save("success.wav",   chime([523, 659, 784, 880]), -12.0)
save("success_1.wav", chime([440, 587, 659, 880]), -12.0)
save("success_2.wav", chime([587, 698, 880, 784]), -12.0)

# --- FANFARE: kraj cele mini-igre. Ista porodica, duza fraza + "iskrice". ---
main = chime([523, 659, 784, 659, 880, 1047], step=0.135, dur=0.85, damp=0.5)
spark = []
for k in range(7):
	f = random.choice([1047, 1175, 1319, 1568])
	s = struck(f, 0.30, BELL, atk=0.0015, damp=0.9, detune=0.01)
	mix_into(spark, [x * 0.16 for x in s], 0.30 + k * 0.075 + random.uniform(0, 0.03))
spark = lowpass(spark, 2800)
out = list(main)
mix_into(out, spark)
save("fanfare.wav", soften(out), -13.5)

print("Gotovo.")


# --- HAPPY ĐINGLOVI po životinji -------------------------------------------
# Koriste se kad životinja nema pravo glasanje (žirafa, nilski konj) i kao
# "srećna" reakcija. Bili su isti sinusni arpeđo kao success — sad su topli
# drveni (marimba), i visina prati veličinu životinje: slon dole, papagaj gore.

ANIMAL_PITCH = {
	"elephant": 196, "hippo": 220, "cow": 247, "horse": 262, "lion": 233,
	"giraffe": 294, "pig": 277, "goat": 330, "dog": 311, "duck": 349,
	"monkey": 392, "chicken": 415, "parrot": 466,
}

print("happy đinglovi:")
for animal, base in sorted(ANIMAL_PITCH.items()):
	buf = []
	t = 0.0
	for k, ratio in enumerate((1.0, 1.25, 1.5, 2.0)):     # veseo durski poskok
		note = struck(base * ratio, 0.52, WOOD, atk=0.0016, damp=0.6, detune=0.006)
		vel = 0.80 + 0.20 * (k / 3.0)                     # fraza raste ka kraju
		note = [x * vel for x in note]
		note = mix_into(note, click(0.007, cutoff=0.26, amp=0.18, lowcut=0.04))
		mix_into(buf, note, t)
		t += 0.105 + random.uniform(-0.010, 0.010)
	buf = lowpass(buf, 2700)
	buf = highpass(buf, 120)
	save("%s_happy.wav" % animal, soften(room(buf, mix=0.11, decay=0.26)), -12.5)
