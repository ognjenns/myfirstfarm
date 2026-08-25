#!/bin/bash
# Potpisan AAB za Play.
#
# Godot 4.7 NE cita keystore iz export_presets.cfg ni iz export_credentials.cfg
# za Android — jedini pouzdan put su ove tri promenljive okruzenja. Lozinka se
# cuva u game/export_credentials.cfg (u .gitignore) i odavde se samo ucita.
set -e
cd "$(dirname "$0")/game"

CRED="export_credentials.cfg"
[ -f "$CRED" ] || { echo "nema $CRED — upisi lozinku u njega"; exit 1; }

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/oggie-release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="oggie"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(python3 -c "
import re,sys
m = re.search(r'release_password=\"(.*)\"', open('$CRED').read())
sys.stdout.write(m.group(1) if m else '')
")"
[ -n "$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" ] || { echo "lozinka prazna"; exit 1; }

# Godot bi inace pokusao da procita nepotpuna keystore polja iz ovog fajla i
# pao na "Either Release Keystore, Release User AND Release Password ... OR none".
BAK=$(mktemp); cp "$CRED" "$BAK"
printf '[preset.1.options]\n\n' > "$CRED"
trap 'cp "$BAK" "$CRED"; rm -f "$BAK"' EXIT

godot --headless --export-release "AndroidAAB" ../build/myfirstanimals.aab

echo
jarsigner -verify ../build/myfirstanimals.aab | tail -1
ls -lh ../build/myfirstanimals.aab | awk '{print $5, $9}'
