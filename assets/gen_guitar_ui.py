#!/usr/bin/env python3
"""NE KORISTI SE (23.08.2026) — korisniku žica nije legla; meni i biranje
itema sada idu iz pravih Mixkit snimaka kroz process_mixkit_v4.sh.
Fajl ostaje jer je model upotrebljiv ako zatreba.

Trzana žica za meni i biranje itema — Karplus-Strong.

Ovo NIJE aditivna sinteza kao stari bipovi: KS je fizički model žice
(kružni bafer + prigušenje u petlji), isti princip po kom žica stvarno radi,
pa zvuči kao okinuta struna a ne kao generator tona.
-> game/sfx/
"""
import wave, struct, math, os, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "sfx")
random.seed(5)


def pluck(freq, dur, decay_t=0.35, bright=0.5, pick=0.55):
	"""freq: visina žice; decay_t: vreme gašenja; bright: sjaj okidanja;
	pick: koliko se čuje sam prst/trzalica na žici."""
	n_period = max(2, int(SR / freq))
	n = int(dur * SR)

	# Pobuda: šum filtriran prema `bright` — tamnija pobuda = mekši prst,
	# svetlija = trzalica.
	buf = []
	z = 0.0
	for _ in range(n_period):
		x = random.uniform(-1, 1)
		z += bright * (x - z)
		buf.append(z)

	# Prigušenje po obilasku petlje, izračunato iz željenog vremena gašenja.
	per_pass = math.exp(math.log(0.03) / max(1.0, freq * decay_t))

	out = []
	prev = 0.0
	for i in range(n):
		idx = i % n_period
		v = buf[idx]
		nxt = buf[(i + 1) % n_period]
		out.append(v)
		buf[idx] = per_pass * 0.5 * (v + nxt)      # lowpass u petlji = gubitak visokih
		prev = v

	# Zvuk prsta na žici u prvih par milisekundi.
	npick = int(0.006 * SR)
	lp = 0.0
	for i in range(min(npick, n)):
		x = random.uniform(-1, 1)
		lp += 0.5 * (x - lp)
		out[i] += pick * lp * (1.0 - i / npick)

	# Telo instrumenta: blago prigušenje najviših, da ne cvili na zvučniku.
	a = 1.0 - math.exp(-2 * math.pi * 3200.0 / SR)
	z = 0.0
	body = []
	for s in out:
		z += a * (s - z)
		body.append(z)

	# Mek kraj da nema klika.
	tail = int(0.02 * SR)
	for i in range(tail):
		body[n - 1 - i] *= i / tail
	return body


def save(name, samples, rms_db, peak_cap_db=-9.0):
	# Trzaj ima ogroman vrh u odnosu na telo; blaga saturacija ga zaobli da
	# na telefonskom zvučniku ne "pukne", pa tek onda poravnamo nivo.
	samples = [math.tanh(s * 1.8) / math.tanh(1.8) for s in samples]
	sq = sum(s * s for s in samples) / max(1, len(samples))
	cur = 10 * math.log10(max(1e-12, sq))
	g = 10 ** ((rms_db - cur) / 20.0)
	data = [max(-1.0, min(1.0, s * g)) for s in samples]
	pk = max(1e-9, max(abs(s) for s in data))
	cap = 10 ** (peak_cap_db / 20.0)
	if pk > cap:
		data = [s * cap / pk for s in data]
	with wave.open(os.path.join(OUT, name), "w") as w:
		w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
		w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in data))
	pk = 20 * math.log10(max(1e-9, max(abs(s) for s in data)))
	print("  %-12s %4.2fs  RMS %.0f dB  peak %.1f dB" % (name, len(data) / SR, rms_db, pk))


print("Žica za UI ->", os.path.abspath(OUT))

# MENI (dugmad, kartice svetova) — mek, srednji ton, kratko odzvoni.
save("pop.wav", pluck(294.0, 0.55, decay_t=0.30, bright=0.42, pick=0.45), -24)

# BIRANJE ITEMA (hrana, karte u memoriji) — nešto viša žica, jasnija.
save("pluck.wav", pluck(392.0, 0.50, decay_t=0.26, bright=0.52, pick=0.55), -23)

# NAJLAKŠI DODIR — prigušena žica (palm mute), vrlo kratko.
save("tap.wav", pluck(523.0, 0.30, decay_t=0.13, bright=0.45, pick=0.40), -26)

print("Gotovo.")
