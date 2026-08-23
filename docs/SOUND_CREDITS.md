# Izvori zvukova — stanje 27.07.2026

✅ **SVE BEZ OBAVEZE POTPISIVANJA** — spremno za objavu bez credits ekrana.

| Zvuk | Izvor | Licenca |
|---|---|---|
| cow_0/1 | Mixkit "Cow moo in the barn" (1751) | Mixkit Free License (komercijalno OK, bez potpisa) |
| goat_0/1 | Mixkit "Farm goat baa" (1763) | Mixkit Free License |
| horse_0/1 | Mixkit "Scared horse neighing" (85) | Mixkit Free License |
| chicken_0/1 | Mixkit "Rooster crowing in the morning" (2462) | Mixkit Free License |
| duck_0/1 | Pixabay/freesound_community "duck quack" (40345) | Pixabay License (komercijalno OK, bez potpisa) |
| pig_0/1 | Freesound preview 842313 (pig_3 iz audicije) | CC0 |
| happy đinglovi, UI zvuci, muzika | naša sinteza (gen_sounds.py / gen_music.py) | naše |

Varijante `_1` su isti snimci sa blagim pitch pomakom (±5–7%).

Originali: `~/Downloads/mixkit-*.wav`, `assets/fs_candidates/`, `assets/real_sounds*/` (arhiva starih pokušaja).
- `elephant_0/1.wav` — Pixabay (freesound_community, "Elephant trumpets growls"), Pixabay Content License, bez atribucije
- `lion_0/1.wav` — Pixabay (pwlpl, "Powerful lion roar"), Pixabay Content License, bez atribucije; skraćeno i stišano
- `monkey_0/1.wav` — Pixabay (u_zpj3vbdres, "Monkey"), Pixabay Content License, bez atribucije
- `parrot_0/1.wav` — "Parrot squawk sound effect" (korisnikov download), dva različita kreštaja isečena iz istog snimka
- `frog.wav` — Pixabay (freesound_community, "Frog"), Pixabay Content License, bez atribucije

## Dopuna 23.08.2026 — pravi snimci umesto sinteze

Svi Mixkit Free License (komercijalno OK, **bez obaveze potpisivanja**).
Obrada: `assets/process_mixkit_v4.sh` (mono 22050, odsecanje tišine, fade, RMS poravnat na ostatak igre).

| Zvuk u igri | Izvor |
|---|---|
| nom (žvakanje) | Mixkit "Animal eating herb" (2241) |
| giraffe_0/1, hippo_0/1 | isti snimak, pitch varijante — žirafa i nilski konj namerno nemaju pravo glasanje (plašilo bi decu), pa "govore" mirnim žvakanjem |
| wrong | Mixkit "Cartoon girl saying no no no" (2257) |
| success, success_1/2 | Mixkit "Achievement bell" (600), _1/_2 pitch varijante |
| win (kraj runde) | Mixkit "Instant win" (2021) |
| clap | Mixkit "Small group clapping" (475), skraćeno na 2,6 s |
| kid | Mixkit "Funny kid voice" (2879) |
| splash | Mixkit "Spray water or liquid" (3215) |
| pop, tap (meni i dugmad) | Mixkit "Plastic bubble click" (1124), tap je viša i tiša varijanta |
| pluck (uzimanje hrane, karta) | Mixkit "Electric pop" (2365), skraćen na 0,45 s |

**Ostalo sintetičko:** plop, scrub, music, splash_theme,
i 13 `*_happy` đinglova koji su sada MRTVI (sve životinje imaju pravo glasanje) —
mogu se obrisati pri sledećem čišćenju. `buzz.wav` je nezakačen jer su komarci
NAMERNO uklonjeni iz igre — nije propust.
