# Moja Farma — Godot projekat

Pokretanje: otvori folder u Godot 4.7+ (importuje asete pri prvom otvaranju) ili:

```
godot --path game/        # pokreni igru
godot --path game/ -e     # otvori editor
```

Na ovom Macu: `godot` = `/Applications/Godot.app/Contents/MacOS/Godot`

## Testovi i alatke (argumenti posle `--`)

```
godot --headless --path game/ -- --smoke      # instancira svih 7 ekrana
godot --headless --path game/ -- --autotest   # odigra sve 4 mini-igre (41 provera)
godot --path game/ -- --shots                 # screenshotovi svih ekrana u shots/
godot --path game/ --resolution 512x512 -- --make-icon   # regeneriši icon.png
```

Napomena: posle dodavanja novog fajla sa `class_name` prvo pokreni
`godot --headless --import --path game/` da se klasa registruje.

## Android build

```
godot --headless --path game/ --export-debug "Android" ../build/moja_farma.apk
```

Instalacija na telefon (uključi USB debugging):
```
~/Library/Android/sdk/platform-tools/adb install build/moja_farma.apk
```

Podešeno: export templates 4.7.1, debug keystore, arm64, paket `rs.mojafarma.game`.
Za Play Store kasnije: release keystore + AAB (`gradle_build/export_format=1`).

## Struktura

- `core/` — main (screen manager), audio autoload, Animals (sadržaj), UI helperi, AnimalSprite, TapButton, FoodItem, BaseScreen
- `screens/` — hub + 4 mini-igre + parental gate + roditeljski ugao
- `art/animals/` — Kenney Animal Pack Redux (CC0)
- `sfx/` — **placeholder** sintetizovani zvuci (`assets/gen_sounds.py`) — zameniti pravim pre objave

## Reskin nove igre

Sve što je tematsko živi u `core/animals.gd` (lista životinja + hrana), `art/`, `sfx/` i bojama pozadina po ekranima. Logika mini-igara se ne dira.

## TODO do objave (plan N5–N6 u ../DESIGN.md)

- [ ] AdMob (Poing Studios plugin): child-directed tag, NPA, max rating G, interstitial samo na prelazu, frequency cap
- [ ] IAP "Ukloni reklame" (Google Play Billing / StoreKit)
- [ ] Pravi zvuci umesto placeholder-a
- [ ] Ikonica + splash + store listing
- [ ] Test sa detetom 2–5 god
