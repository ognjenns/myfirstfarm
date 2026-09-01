# Marketing video pipeline

Dve vrste vertikalnog (9:16) videa za Shorts/Reels/TikTok.

## 1. Snimak pravog igranja — `record_short.sh` + `build_short.py`

Aplikacija se sama igra i to se snima: splash → izbor sveta → okean →
orkestar, sa prstom koji se vidi na ekranu.

    ./record_short.sh              # ~/Desktop/OggieGames_Reel/raw.avi
    python3 build_short.py         # → my-first-animals-gameplay.mp4 (~26 s)

- Prolaz je `game/core/demo.gd` (`godot --path game/ -- --demo`): pravi
  InputEvent-i idu kroz viewport, pa se na snimku dešava tačno ono što vidi i
  dete. Mete se traže po čvorovima (kartice svetova, kapije, muzičari), ne po
  tvrdim koordinatama.
- Snima se Godot Movie Maker režimom, ne snimačem ekrana: deterministično,
  60 fps, sa zvukom igre i bez ispuštenih kadrova. Movie Maker snima veličinu
  PROZORA — ako prozor ne stane na ekran (npr. otvori se na manjem monitoru),
  snimak ispadne manji od 1920×1080; skript to prijavi.
- `build_short.py` sklapa 1080×1920 u više koraka (igra → završna kartica →
  spajanje → zvuk). Zaglavlje snimka i ffmpeg imaju tri zamke koje su opisane
  u komentaru na vrhu skripta; ukratko: takt slike i dužina zvuka iz AVI-ja se
  ne smeju verovati, a slike se ffmpeg-u NE smeju davati kao `-loop 1` ulaz
  (zaglavljuje se bez greške) — zato natpisi i kartica idu kao sirovi kadrovi
  kroz cev.
- Vremena natpisa su u `CAPTIONS`, a `TRIM` seče uvod splash-a; ako se
  `demo.gd` menja, oba se podešavaju po novom snimku.

Igra je pejzažna a Short je uspravan — zato kadar ne ide preko celog ekrana.

## 2. Slajdšou od store screenshotova — `make_cards2.py` + `build_video2.py`

- `make_cards2.py`  → sklapa 9 kartica (blur pozadina + kadar + tekst) u `cards2/`
- `build_video2.py` → Ken Burns zum + prelazi + muzika iz igre → mp4

Pokretanje (iz ovog foldera):

    python3 make_cards2.py && python3 build_video2.py

Ulaz:  ~/Desktop/Play_Screenshots_1.1.0/phone/*.png
       game/sfx/music.wav, build/play_icon.png
Izlaz: ~/Desktop/OggieGames_Reel/my-first-animals-reel-v2.mp4

`make_cards.py` / `build_video.py` su v1 — imaju oggiegames.com upisan u
kadar i "Free on the App Store" karticu. TikTok Promote je tu verziju odbio;
v2 je bez toga.
