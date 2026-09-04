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
godot --path game/ -- --shots --only=jungle,jfeed   # samo navedeni ekrani
godot --path game/ --resolution 1440x1080 -- --shots   # tablet 4:3
godot --path game/ --resolution 512x512 -- --make-icon   # regeneriši icon.png
godot --path game/ -- --demo                  # demo prolaz sa vidljivim prstom
```

`--demo` sam odigra: splash → izbor sveta → okean → orkestar, pravim
dodirima i sa prstom na ekranu. Služi za promo video — snima se preko
`marketing/record_short.sh` (Godot Movie Maker).

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
- `art/farm/`, `art/ocean/`, `art/dino/`, `art/jungle/` — kupljeni paketi (gamedeveloperstudio.com, Robert Brooks; komercijalna upotreba i izmene dozvoljene, bez atribucije). Džungla se seče iz `~/Downloads/<Paket>--<id>/` skriptom `assets/cut_jungle.py` (životinje: `<id>-<anim>-N.png`, isti isečak za sve animacije jedne životinje). Lav je kupljen namršten, pa se njegove sličice sklapaju iz Spriter fajla (`assets/spriter_render.py`, mali renderer za `.scml`) bez obrva i sa vilicom bez očnjaka — sve u `cut_jungle.py`. `FarmBody` sam pada na staru glavu za životinje koje nemaju red u `ANIMS`.
- `sfx/` — **placeholder** sintetizovani zvuci (`assets/gen_sounds.py`) — zameniti pravim pre objave

## Reskin nove igre

Sve što je tematsko živi u `core/animals.gd` (lista životinja + hrana), `art/`, `sfx/` i bojama pozadina po ekranima. Logika mini-igara se ne dira.

## TODO do objave (plan N5–N6 u ../DESIGN.md)

- [ ] AdMob (Poing Studios plugin): child-directed tag, NPA, max rating G, interstitial samo na prelazu, frequency cap
- [ ] IAP "Ukloni reklame" (Google Play Billing / StoreKit)
- [ ] Pravi zvuci umesto placeholder-a
- [ ] Ikonica + splash + store listing
- [ ] Test sa detetom 2–5 god
