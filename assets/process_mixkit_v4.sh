#!/bin/bash
# Obrada pravih Mixkit snimaka -> game/sfx/ (23.08.2026)
# Recept isti kao za glasanja životinja: mono 22050, odsecanje tišine,
# kratki fade-ovi, pa poravnanje RMS-a na nivo ostatka igre.
# Licenca: Mixkit Free License — komercijalno OK, bez obaveze potpisivanja.
set -e
SRC="$HOME/Downloads"
DST="$(cd "$(dirname "$0")/../game/sfx" && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# start_duration mora biti kraće od najkraćeg korisnog zvuka: sa 0.02 s
# silenceremove je POJEO cele klikove (transijent kraći od 20 ms se ne
# prizna kao "ne-tišina", pa filter nastavi da briše do kraja fajla).
TRIM="silenceremove=start_periods=1:start_duration=0.004:start_threshold=-72dB:detection=peak,areverse,silenceremove=start_periods=1:start_duration=0.004:start_threshold=-72dB:detection=peak,areverse"

# prep <izvor> <izlaz> <ciljni_RMS_dB> [dodatni_filteri]
prep() {
	local src="$1" out="$2" target="$3" extra="${4:-anull}"
	# aresample MORA prvi: bez njega graf radi na 44100, pa asetrate=22050*X
	# reinterpretira uzorke na pogrešnom rate-u i zvuk ispadne usporen.
	ffmpeg -v error -i "$src" -ac 1 -af "aresample=22050,$TRIM,$extra" -ar 22050 -c:a pcm_s16le "$TMP/a.wav" -y
	local dur rms gain
	dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/a.wav")
	# Zaštita: ako je trim pojeo sve, uzmi snimak bez odsecanja tišine.
	if [ -z "$dur" ] || [ "$dur" = "N/A" ]; then
		echo "  (trim bi obrisao $out — obrađujem bez odsecanja)"
		ffmpeg -v error -i "$src" -ac 1 -af "aresample=22050,$extra" -ar 22050 -c:a pcm_s16le "$TMP/a.wav" -y
		dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/a.wav")
	fi
	# Fade-ovi MORAJU biti srazmerni dužini: fiksnih 8/30 ms je na kliku od
	# 40 ms sekло sam udar i pojelo ceo odzvon. Ulaz je jedva primetan (udar je
	# ono što se čuje), izlaz najviše četvrtina trajanja.
	local fin fout fst
	fin=$(python3 -c "print(f'{min(0.004, $dur*0.03):.4f}')")
	fout=$(python3 -c "print(f'{min(0.030, $dur*0.25):.4f}')")
	fst=$(python3 -c "print(f'{max(0.0, $dur-min(0.030, $dur*0.25)):.4f}')")
	ffmpeg -v error -i "$TMP/a.wav" -af "afade=t=in:st=0:d=$fin,afade=t=out:st=$fst:d=$fout" -c:a pcm_s16le "$TMP/b.wav" -y
	rms=$(ffmpeg -hide_banner -i "$TMP/b.wav" -af astats -f null - 2>&1 | grep "RMS level dB" | tail -1 | awk '{print $NF}')
	gain=$(python3 -c "print(f'{($target)-($rms):.2f}')")
	ffmpeg -v error -i "$TMP/b.wav" -af "volume=${gain}dB,alimiter=limit=0.89" -c:a pcm_s16le "$DST/$out" -y
	printf "  %-16s %5.2fs  RMS %6s -> %s dB  (gain %s)\n" "$out" "$dur" "$rms" "$target" "$gain"
}

echo "Obrada pravih snimaka -> $DST"

# --- ŽVAKANJE: hrana koju životinja pojede -----------------------------------
prep "$SRC/mixkit-animal-eating-herb-2241.wav" nom.wav -38

# Žirafa i nilski konj namerno nemaju pravo glasanje (deca bi se uplašila),
# pa im je "glas" mirno žvakanje — oba su biljojedi, deci ima smisla.
# Nivo im je NIŽI od svih ostalih životinja (-30 prema -22..-27): žvakanje je
# u stvarnosti tih zvuk, pa na nivou rike ili muka zvuči neprirodno glasno.
prep "$SRC/mixkit-animal-eating-herb-2241.wav" giraffe_0.wav -30
prep "$SRC/mixkit-animal-eating-herb-2241.wav" giraffe_1.wav -30 "asetrate=22050*1.07,aresample=22050"
prep "$SRC/mixkit-animal-eating-herb-2241.wav" hippo_0.wav  -30 "asetrate=22050*0.88,aresample=22050"
prep "$SRC/mixkit-animal-eating-herb-2241.wav" hippo_1.wav  -30 "asetrate=22050*0.83,aresample=22050"

# --- GREŠKA: "no no no" ------------------------------------------------------
prep "$SRC/mixkit-cartoon-girl-saying-no-no-no-2257.wav" wrong.wav -19

# --- TAČNO: zvonce ----------------------------------------------------------
prep "$SRC/mixkit-achievement-bell-600.wav" success.wav   -18 "atrim=0:1.5"
prep "$SRC/mixkit-achievement-bell-600.wav" success_1.wav -18 "atrim=0:1.5,asetrate=22050*1.06,aresample=22050"
prep "$SRC/mixkit-achievement-bell-600.wav" success_2.wav -18 "atrim=0:1.5,asetrate=22050*0.94,aresample=22050"

# --- KRAJ RUNDE: pobeda + aplauz + dečji glas -------------------------------
prep "$SRC/mixkit-instant-win-2021.wav" win.wav -18
prep "$SRC/mixkit-small-group-clapping-475.wav" clap.wav -27 "atrim=0:2.6"
prep "$SRC/mixkit-funny-kid-voice-2879.wav" kid.wav -20

# --- VODA: tuš i prskanje ----------------------------------------------------
prep "$SRC/mixkit-spray-water-or-liquid-3215.wav" splash.wav -18

# --- MENI I BIRANJE ITEMA ----------------------------------------------------
# Klik po meniju i dugmadima.
prep "$SRC/mixkit-plastic-bubble-click-1124.wav" pop.wav -24
# Najlakši dodir (kupanje, žmurke) — isti klik, malo viši i tiši.
prep "$SRC/mixkit-plastic-bubble-click-1124.wav" tap.wav -27 "asetrate=22050*1.18,aresample=22050"
# Uzimanje hrane i okretanje karte u memoriji.
prep "$SRC/mixkit-electric-pop-2365.wav" pluck.wav -24 "atrim=0:0.45"

echo "Gotovo."
