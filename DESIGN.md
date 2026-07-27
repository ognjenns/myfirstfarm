# Moja Farma — dizajn-dokument

**Verzija:** 1.0 (24.07.2026)
**Tip:** dečija igra, uzrast 2–5 godina, bez teksta
**Engine:** Godot 4.7.1 (stable, jul 2026)
**Platforme:** Android prvo, iOS drugo (razlog u sekciji 4)
**Monetizacija:** nepersonalizovane reklame + IAP "Ukloni reklame" (2,99 €)
**Strategija:** prva igra u seriji — isti engine, reskin za nastavke (džungla, okean, dinosaurusi...)

---

## 1. Koncept i struktura igre

### Hub ekran (dvorište farme)

Jedna ilustrovana scena farme sa **6 životinja**: krava, prase, kokoška, ovca, konj, pas.

- Tap na životinju → oglasi se (2–3 varijante zvuka, nasumično) + smešna squash-and-stretch animacija. Za dvogodišnjake ovo je igra sama po sebi.
- Na sceni 4 velike, jasno vidljive "kapije" ka mini-igrama (ikonica bez teksta: korpa hrane, senka, kada, plast sena).
- Diskretno dugme u uglu → roditeljski ugao (iza parental gate-a).

### Mini-igre (4 za v1, peta ide u update)

**1. Nahrani životinju** (drag & drop)
Na ekranu 2–4 životinje i tacna sa hranom. Dete prevuče hranu do prave životinje (krava→trava, kokoška→zrnevlje, prase→jabuka, pas→kost, konj→šargarepa, ovca→detelina).
- Pogodak: životinja žvaće, srećna animacija, zvuk mljackanja.
- Promašaj: životinja blago odmahne glavom — bez negativnog zvuka.
- Progresija bez teksta: kreće sa 2 životinje, posle 3 uspešne runde 3, pa 4.

**2. Senka-slagalica** (drag & drop)
Scena sa 3–4 obrisa (senke) i životinjama sa strane. Dete prevuče životinju na njen obris.
- Snap tolerancija velika (bar 25% preklapanja = pogodak).
- 6 scena (kombinacije životinja); završena scena = konfete + svi se oglase.

**3. Okupaj prase** (care mehanika)
Prase blatnjavo → dete prstom trlja blato (briše se sloj) → sunđer pravi penu → tuš spira → prase sija i gicka od sreće.
- Čista tactile igra, nema pobede/poraza. Faze se smenjuju automatski kad je prethodna "gotova" (npr. 80% blata obrisano).

**4. Žmurke**
Životinja proviri, pa se sakrije iza jednog od 3 objekta (plast sena, štala, traktor). Dete tapne objekat.
- Pogodak: životinja iskoči uz veseli zvuk.
- Promašaj: objekat se zatrese, ništa iza — dete proba ponovo, bez ograničenja pokušaja.

### Pravila dizajna za uzrast 2–5 (važe za sve ekrane)

- **Nula teksta.** Sva komunikacija zvukom, animacijom i ikonicama. → App radi globalno bez lokalizacije.
- **Nema fail-stanja.** Greška nikad ne kažnjava — najviše blaga "nije to" animacija.
- **Nema tajmera, nema score-a.** Deca ovog uzrasta ih ne razumeju, samo frustriraju.
- **Krupne tap zone:** minimum 15% širine ekrana po interaktivnom objektu.
- **Sve reaguje.** Tap bilo gde daje makar mali zvuk/efekat — mrtvih zona nema.
- **Drag mora biti "lepljiv":** objekat se ne ispušta lako, snap zone velikodušne.

---

## 2. Ekrani i tok

```
Splash (logo, 2s)
  └─ Hub (dvorište farme)
       ├─ Mini-igra 1: Nahrani
       ├─ Mini-igra 2: Senke
       ├─ Mini-igra 3: Kupanje
       ├─ Mini-igra 4: Žmurke
       └─ [parental gate] → Roditeljski ugao
                              ├─ Ukloni reklame (IAP 2,99 €)
                              ├─ Restore purchases
                              ├─ Privacy policy (link van app-a)
                              └─ Ostale naše igre (kasnije, cross-promo)
```

**Parental gate:** matematičko pitanje slovima izgovoreno + prikazano ("Koliko je sedam plus četiri?" sa brojčanom tastaturom) ili hold-3-sekunde sa dva prsta. Obavezan pre: IAP-a, bilo kog linka van app-a, podešavanja. Ovo traže i Apple (Kids/deca ispod 13) i Google Families pravila.

**Povratak iz mini-igre:** dugme "kućica" u uglu, uvek vidljivo, vraća na hub.

---

## 3. Asseti — shopping lista

### Grafika

**Preporuka za start (besplatno, CC0):** [Kenney Animal Pack Redux](https://kenney.nl/assets/animal-pack-redux) — 240 asseta, 30 životinja u 8 stilova (uključuje kravu, prase, kokošku, psa, konja, kozu...), PNG + vektori, CC0 licenca (nema ni obaveze potpisa). Okrugli, krupni, "cute" stil — tačno ono što treba za 2–5 godina. **Bonus: 30 životinja pokriva i buduće reskin nastavke (džungla, okean) iz istog paketa.**

Za pozadine (dvorište, štala, scena kupanja) i rekvizite (hrana, plast sena, traktor, kada):
- [GraphicRiver — farm game assets](https://graphicriver.net/graphics-with-farm+animals-in-game-assets) (~10–25 € po paketu, vektorski)
- [itch.io — animals + farming tagovi](https://itch.io/game-assets/tag-animals/tag-farming) (paziti: većina je pixel-art — NE uzimati pixel-art, za ovaj uzrast treba krupna glatka crtana grafika)
- Kenney takođe ima UI pack (dugmad, ikonice) — CC0

**Budžet grafika: 0–40 €.**

### Zvuk (kritično — ovde je razlika između šunda i hita)

| Šta | Količina | Izvor |
|---|---|---|
| Glasanje po životinji | 2–3 varijante × 6 životinja | Freesound (CC0/CC-BY filter), Zapsplat |
| "Srećna" reakcija (gicanje, rzanje od milja) | 1 × 6 | isto |
| Feedback zvuci (pogodak-cin, mljackanje, pena, pljusak, konfete) | ~10 | isto |
| Ambijent farme (ptice, vetar, tiho) | 1 loop | isto |
| Vesela hub muzika | 1 loop, ne-iritantna (roditelj je sluša 500×) | Freesound / AudioJungle (~15 €) |

Pravilo: svaki zvuk presnimiti/normalizovati na istu glasnoću; ništa piskavo ni naglo (deca se uplaše, roditelji brišu app).

**Budžet zvuk: 0–20 €.**

### Animacije — ne kupuju se

Rade se u Godotu (`AnimationPlayer` + `Tween`) nad statičnim sprite-ovima: squash-and-stretch, poskok, naginjanje, treptanje. Po životinji 3 animacije: **idle** (diše, trepne), **tap-reakcija** (poskoči + glasanje), **srećna** (gicanje/vrtenje). Sa Kenney sprite-ovima ovo je 1–2 h po životinji.

---

## 4. Monetizacija i compliance

### Android (Google Play) — primarna platforma za reklame

- App se prijavljuje u **Families program** (self-declaration u Play Console).
- Obavezno: samo **[Families Self-Certified Ads SDK-ovi](https://support.google.com/googleplay/android-developer/answer/9900633)** — AdMob jeste na listi, konfigurisan po [AdMob Families uputstvu](https://support.google.com/admob/answer/6223431).
- U AdMob-u i kodu: `tag_for_child_directed_treatment = true`, samo nepersonalizovane reklame (NPA), max ad content rating **G**. Ako se koristi medijacija — isključivo self-certified mreže u mediation grupi.
- **Napomena (jul 2026):** Google je upravo objavio [preview novih Families pravila](https://support.google.com/googleplay/android-developer/answer/17122218) — pre submita proveriti finalnu verziju.

**Format reklama:**
- **Banner: NE.** Mala deca tapću svuda — slučajni klikovi su i loše iskustvo i rizik za AdMob nalog (invalid traffic).
- **Interstitial: DA, ali samo na prelazu** mini-igra → hub, sa jasnim X, i **ne češće od 1 na 3 minuta** (frequency cap u AdMob-u + lokalni tajmer u kodu).
- **Rewarded: NE** za ovaj uzrast (koncept "nagrade za gledanje" je manipulativan za trogodišnjaka i rizičan po policy).

### iOS (App Store) — druga faza, drugačija strategija

Po [Apple pravilima](https://developer.apple.com/app-store/review/guidelines/) (guideline 1.3), app u **Kids kategoriji ne sme imati third-party reklame** (ni analytics koji šalje identifikatore). Zato:

- **Odluka: iOS verzija ide BEZ reklama** — besplatna sa "otključaj sve" IAP-om (2,99 €), ili sve otključano + "častite nas kafom" model. Čist app, bolje ocene, Apple friendly.
- Alternativa (ako se pokaže da Android reklame dobro rade): iOS van Kids kategorije sa 4+ ratingom i AdMob-om — ali Apple review za očigledno dečiji app ume to da odbije. Ne rizikovati u v1.
- Parental gate obavezan pre IAP-a i linkova u svakom slučaju.

### Zajedničko

- **Privacy policy** (obavezan URL za obe platforme): app ne prikuplja lične podatke, nema naloga, nema third-party analytics u v1 (Firebase Analytics NE dodavati — komplikuje compliance za minimalnu korist).
- COPPA/GDPR-K: pošto nema prikupljanja podataka i reklame su child-directed nepersonalizovane preko UMP-a, izloženost je minimalna.
- IAP "Ukloni reklame": non-consumable, 2,99 €, sa restore opcijom (Apple je zahteva).

---

## 5. Tehnički plan (Godot)

- **Godot 4.7.1 stable** (jun/jul 2026), GDScript. Jedan projekat → Android (Gradle export) + iOS (Xcode export).
- **AdMob:** [Poing Studios godot-admob-plugin](https://github.com/poingstudios/godot-admob-plugin) (v3.x) — podržava Godot 4, GDScript i C#, ima ugrađen UMP SDK (GDPR/COPPA consent). Pri integraciji potvrditi u docs tačan API za child-directed tag (`tag_for_child_directed_treatment`) i postaviti `max_ad_content_rating = "G"`.
- **IAP:** zvanični Godot plugini — Google Play Billing (Android), StoreKit/in-app purchase plugin (iOS).
- **Rezolucija:** dizajn za 1920×1080 landscape, `canvas_items` stretch + `expand` — pokriva telefone i tablete (tableti su bitni: dečiji appovi se dosta igraju na tabletima).

### Arhitektura za reskin (najvažnija tehnička odluka)

Sve što je specifično za temu ide u **jedan `AnimalConfig` custom Resource** po životinji:

```
AnimalConfig (Resource)
├─ id: String                    # "cow"
├─ sprite_frames: SpriteFrames   # idle/tap/happy frejmovi
├─ sounds: Array[AudioStream]    # glasanja
├─ happy_sound: AudioStream
├─ food_sprite: Texture2D        # šta jede (za Nahrani)
└─ shadow_texture: Texture2D     # obris (za Senke)
```

Mini-igre čitaju isključivo iz liste `AnimalConfig`-a (`farm_animals.tres` → sutra `jungle_animals.tres`). **Reskin nove igre = novi set resursa + nova pozadina + novi App ID. Nula izmena game logike.**

Struktura projekta:

```
moja_farma/
├─ DESIGN.md
├─ docs/            # compliance checkliste, store tekstovi
├─ assets/          # sirovi kupljeni/skinuti asseti (van Godot projekta)
└─ game/            # Godot projekat
   ├─ core/         # hub, parental gate, ads, iap, audio manager
   ├─ minigames/    # feed/, shadows/, bath/, hideseek/
   ├─ config/       # animal_configs/, farm_animals.tres
   └─ art/, sfx/    # importovani asseti
```

---

## 6. Plan rada (solo, part-time, ~6 nedelja)

| Nedelja | Cilj | Definicija "gotovo" |
|---|---|---|
| **N1** | Godot setup, asseti skinuti, hub radi | 6 životinja na sceni, tap → zvuk + animacija, na telefonu |
| **N2** | Mini-igra: Nahrani | Kompletna sa progresijom 2→4 životinje |
| **N3** | Mini-igra: Senke | 6 scena, konfete |
| **N4** | Mini-igre: Kupanje + Žmurke | Obe igrive od početka do kraja |
| **N5** | AdMob (NPA + child tag + frequency cap), IAP, parental gate | Test reklame rade na pravom uređaju |
| **N6** | Zvuk-polish, test sa pravim detetom (2–5 god!), ikonica, screenshotovi, Play Store listing + Families declaration, submit | App u review-u |
| kasnije | iOS verzija (bez reklama, IAP model), 5. mini-igra kao update, reskin #2 (džungla) | — |

**Test sa detetom u N6 je obavezan korak, ne opcija** — 10 minuta gledanja dvogodišnjaka otkriva više nego nedelja programiranja (gde tapće, šta ne razume, kad odustaje).

### Budžet

| Stavka | Iznos |
|---|---|
| Grafika (Kenney CC0 + eventualno 1 GraphicRiver paket) | 0–40 € |
| Zvuk | 0–20 € |
| Google Play developer nalog (jednokratno) | 25 $ |
| Apple Developer (tek za iOS fazu, godišnje) | 99 $ |
| **Ukupno do Android launcha** | **~60 €** |

### Realna očekivanja od prihoda

Sa nepersonalizovanim dečijim reklamama eCPM je nizak (okvirno 0,5–2 $ u zavisnosti od zemlje). Prva igra sama verovatno neće zaraditi ozbiljno — **ona je šablon i učionica**. Računica postaje zanimljiva od 3–4 reskin igre koje se međusobno cross-promotuju + "ukloni reklame" kupovine. Ako prva igra organski pređe ~10k preuzimanja, to je signal da serija ima smisla.
