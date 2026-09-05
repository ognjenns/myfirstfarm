#!/bin/bash
# Store arhiva za iOS — JEDINI dozvoljeni put do App Store-a.
#
# 05.09.2026: 2.0.0 je otišao u App Store sa DEBUG Godot šablonom (projekat
# exportovan sa --export-debug, pa arhiviran kao Xcode "Release" — Xcode
# konfiguracija ne menja Godot šablon). Debug šablon vraća is_debug_build()
# = true, a igra je to čitala kao "sve otključano": svi kupci su dobili sve
# igre besplatno. Ova skripta to čini nemogućim: export je uvek release, a
# binarni fajl se PROVERAVA pre nego što se arhiva otvori za upload.
#
#   ./build_ios.sh            → build/ios/myfirstanimals.xcarchive + Organizer
set -e
cd "$(dirname "$0")"
ARCH="$PWD/build/ios/myfirstanimals.xcarchive"

echo "== 1/4 release export"
godot --headless --path game --export-release "iOS" build/ios/myfirstanimals.ipa 2>&1 \
  | grep -E "DONE|ERROR" | grep -v -iE "godot_iap|gdextension" | tail -2

echo "== 2/4 provera šablona u xcframework-u"
LIB=$(find build/ios/myfirstanimals.xcframework -name "libgodot.a" | head -1)
strings "$LIB" | grep -q "this build = release export template" \
  || { echo "STOP: xcframework NIJE release šablon"; exit 1; }

echo "== 3/4 arhiva (Release)"
rm -rf "$ARCH"
xcodebuild -project build/ios/myfirstanimals.xcodeproj -scheme myfirstanimals \
  -configuration Release -sdk iphoneos -archivePath "$ARCH" archive \
  CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" \
  DEVELOPMENT_TEAM=HCB46VP7L4 -allowProvisioningUpdates 2>&1 \
  | grep -E "ARCHIVE SUCCEEDED|ARCHIVE FAILED|error:" | head -5
[ -d "$ARCH" ] || { echo "STOP: arhiva nije napravljena"; exit 1; }

echo "== 4/4 provera arhive"
BIN="$ARCH/Products/Applications/myfirstanimals.app/myfirstanimals"
strings "$BIN" | grep -q "this build = release export template" \
  || { echo "STOP: ARHIVA JE DEBUG ŠABLON — NE SLATI"; rm -rf "$ARCH"; exit 1; }
PLIST="$ARCH/Products/Applications/myfirstanimals.app/Info.plist"
VER=$(plutil -extract CFBundleShortVersionString raw "$PLIST")
BLD=$(plutil -extract CFBundleVersion raw "$PLIST")
APPVER=$(grep -o 'const VERSION := "[^"]*"' game/screens/parent_corner.gd | grep -o '"[^"]*"' | tr -d '"')
[ "$VER" = "$APPVER" ] || { echo "STOP: verzija u arhivi ($VER) != parent_corner.gd ($APPVER)"; exit 1; }
echo "OK: release šablon, verzija $VER (build $BLD)"
open "$ARCH"
echo "Organizer otvoren → Distribute App → App Store Connect"
