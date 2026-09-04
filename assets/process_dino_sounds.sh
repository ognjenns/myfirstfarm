#!/bin/bash
# Zvuci za dino svet -> game/sfx/ (04.09.2026)
# Isti recept kao process_mixkit_v4.sh (mono 22050, trim, fade, RMS).
# Izvori: Mixkit (Free License) i Freesound CC0 — vidi docs/SOUND_CREDITS.md.
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


echo "Dino zvuci -> $DST"

# --- KAMENJE: udar cekica (prvi tap) i raspadanje (drugi tap) ---------------
prep "$SRC/freesound-431019-stone-hit-CamoMano-cc0.mp3" rock_hit.wav -22
# Mixkit "stone debris" (403) je tiho kotrljanje kamencica — ne zvuci kao lom.
prep "$SRC/freesound-524312-rock-destroy-Bertsz-cc0.mp3" rock_break.wav -22 "atrim=0:1.0"

# --- JAJA: pucanje ljuske na svaki tap ---------------------------------------
prep "$SRC/freesound-244723-egg-crack1-Reitanna-cc0.mp3" egg_crack.wav -24

# --- LAVA: kamen izranja iz lave (mehur) -------------------------------------
prep "$SRC/mixkit-volcano-lava-bubble-2445.wav" lava_bubble.wav -24 "atrim=0:1.1"

# --- JAJA: trenutak izleganja (umesto zvonca i konfeta) ---------------------
prep "$SRC/mixkit-gen-egg-hatch-1740.wav" egg_hatch.wav -22

# --- OKEAN, orkestar: jedan ton glockenspiela, igra ga transponuje po lestvici
# Glockenspiel (348923) je ukućanima bio iritantan — ide kalimba, mekša, i još
# malo prigušena iznad 3 kHz.
prep "$SRC/freesound-659909-kalimba-PanPiper5-cc0.mp3" note.wav -21 "atrim=0:1.6,lowpass=f=3200"
