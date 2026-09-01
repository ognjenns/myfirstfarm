#!/bin/bash
# Snima demo prolaz kroz igru (game/core/demo.gd) u AVI preko Godot Movie
# Maker režima: deterministično, 60 fps, sa zvukom igre — bez snimanja ekrana.
#
#   ./record_short.sh          → ~/Desktop/OggieGames_Reel/raw.avi
#   python3 build_short.py     → gotov 9:16 Short
set -e
cd "$(dirname "$0")/../game"
OUT="${1:-$HOME/Desktop/OggieGames_Reel/raw.avi}"
mkdir -p "$(dirname "$OUT")"
# Prozor je 1920x1080 jer Movie Maker snima tačno veličinu prozora.
godot --path . --write-movie "$OUT" --fixed-fps 60 --resolution 1920x1080 \
      --position 0,0 -- --demo
# Movie Maker snima veličinu prozora — na manjem monitoru ispadne manji snimak.
W=$(ffprobe -v error -select_streams v -show_entries stream=width -of csv=p=0 "$OUT")
[ "$W" = "1920" ] || echo "PAŽNJA: snimljeno je ${W}px široko umesto 1920 — prozor nije stao na ekran"
echo "snimak: $OUT"
