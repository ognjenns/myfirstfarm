# Četvrti svet: DINOSAURUSI — dizajn

Status: koncept dogovoren 25.08.2026, dizajn raspisan 01.09.2026. Art se
naručuje, kod nije počeo. `Animals.DINO` još ne postoji u `core/animals.gd`.

Svet ide **unutar My First Animals**, kao i džungla i okean — ne kao zasebna
aplikacija. Pokriveno je obećanjem "all worlds forever" iz IAP opisa.

## Ton — pravilo pre svega ostalog

**Ništa strašno: bez zuba, bez jurnjave, bez opasnosti.** T-Rex je blesav i
dobroćudan (kratke ruke, zeva, saplete se), vulkan lenjo dimi i nikad ne
eruptira, lava je mirna i topla narandžasta bez prskanja. Ovo je uzrast 2–5 i
Kids kategorija — isto pravilo koje je žirafi i nilskom konju uzelo riku
(`Animals.SILENT`) važi i ovde, samo za ceo svet.

## Zašto nijedna igra nije reskin

Tri postojeća sveta pokrivaju: povezivanje hrane i životinje, oblik (senke),
čišćenje (kupanje, tuš), stalnost objekta (žmurke), pamćenje parova, zvuk
(pogađalica), pokretnu metu (mehurići), veličinu, boju i slobodnu igru zvukom
(orkestar).

Dinosaurusi uzimaju **tri mehaničke porodice kojih nigde nema** — sklapanje
delova u celinu, građenje putanje i fiziku — plus jednu koja menja pravilo
nagrade (napredak po objektu umesto pogodak/promašaj).

## Šest bića

Birana isključivo po siluetama koje se razlikuju i kad su sitne na ekranu:

| id | prepoznaje se po | "food" (radi jednoobraznosti) |
|---|---|---|
| `trex` | velika glava, smešno kratke ruke | `meat` (komad mesa, bez kostiju i krvi) |
| `bronto` | dugačak vrat | `leaves` |
| `trike` | tri roga i kragna | `fern` |
| `stego` | pločice duž leđa | `moss` |
| `ptero` | krila, kljun | `berries` |
| `anky` | kugla na repu, oklop | `roots` |

Dinosaurusi za sada **nemaju igru hranjenja**, kao ni okean — polje `food`
postoji samo da `Animals` ostane jednoobrazan.

Lica po baby-schema pravilu, isto kao dosad i **bez izuzetka**: veliko prazno
čelo, MALE pune tamne oči NISKO na licu, obraščići uz oči, mali osmeh. Velike
oči su deci strašne, kod dinosaurusa dvostruko.

## Četiri igre

**Stanje 02.09.2026: sve četiri su napisane i rade** — mehanika u kodu,
izgled privremen (crta se iz koda ili od postojećih delova) i čeka Design.


### 1. Legu se jaja — napredak po objektu *(besplatna)*
Tri jaja u gnezdu. Svaki tap širi pukotinu; jaje se ljulja i kucka iznutra,
zvuk raste. Posle 3–4 tapa izlazi beba i uradi nešto blesavo (kine, prevrne se,
skoči). Svako jaje je druga vrsta.
**Novo:** sve dosadašnje igre su pogodak-ili-promašaj u jednom potezu. Ovde
jedan te isti tap ponovljen na istom mestu **gura stanje napred** — dete vidi
da se nešto skuplja, i to je prvi put.
**Uči:** uzrok i posledica, upornost, iščekivanje.
**Pokazivač:** tap na jaje sa najviše pukotina (`hint_spot` → `{"at": ...}`).

### 2. Staza preko lave — građenje putanje *(besplatna)*
Reka lave između dve obale, dino čeka sa jedne strane. Dete tapka po lavi i na
svakom tapu se pojavi kamen; kad kamenje spoji obale, dino veselo pretrči.
4–5 tabli, razmak raste. Bez tajmera i bez pada u lavu — dino jednostavno čeka.
**Novo:** prvo građenje u igri. Ono što dete napravi **ostaje na ekranu** i tek
zbir poteza daje rezultat; do sada je svaki potez bio sam sebi kraj.
**Uči:** prostorno rezonovanje, niz koraka ka cilju, planiranje.
**Pokazivač:** sledeća praznina u nizu.

### 3. Iskopavanje i sklapanje kostura — deo i celina *(zaključana)*
Glavna igra sveta i najbolja za screenshotove, u dve faze:
1. Prst briše pesak (isti gest kao kupanje i tuš — poznat i lak) i ispod se
   ukazuje 5–6 kostiju.
2. Kosti se prevlače u obris na tabli, snap velik kao u senkama (~25%
   preklapanja). Kad je poslednja na mestu, kostur zasvetli, "obuče se" u živog
   dinosaurusa i prošeta kroz kadar uz konfete.

**Novo:** prva igra u kojoj se **više delova sklapa u jednu celinu**. Senke su
jedan objekat na jednu metu; ovde dete ne zna ni koji je dino dok ga ne otkrije.
**Uči:** odnos dela i celine, strpljenje, redosled.
**Pokazivač:** u prvoj fazi kružno brisanje po pesku, u drugoj `from` kost →
`to` prazno mesto u obrisu.

### 4. Kula do lišća — fizika *(zaključana)*
Gomila kamenja dole, brontosaurus sa strane pruža vrat ka krošnji. Dete slaže
kamenje jedno na drugo mekom fizikom dok kula ne bude dovoljno visoka da
bronto dohvati lišće (i zahvalno se oglasi).
**Bez kazne:** ako se kula prospe, kamenje se otkotrlja uz smešan zvuk i vrati
u gomilu — nema poraza i nema početka iz početka.
**Novo:** prva igra sa fizikom i **bez unapred određenog rešenja** — svaka kula
je drugačija i sve su tačne ako drže.
**Uči:** ravnoteža, fina motorika, istrajnost posle neuspeha.
**Pokazivač:** `from` gomila → `to` vrh kule.

**Free/locked:** besplatni su **jaja** i **staza**, zaključani **iskopavanje** i
**kula** — dve od četiri, kao u sva tri postojeća sveta.

## Hub — vulkanski sumrak

**Izgled je odlučen 01.09.2026: sumrak, ne dan i ne noć.** Duboko šljivasto
nebo koje se ka horizontu greje u narandžasto, vulkan kao tamna silueta sa
svetlucavim kraterom, žar-čestice lenjo lebde naviše, pesak topao i osvetljen
odsjajem odozdo, paprat tamnozelena sa toplom ivicom.

Zašto ne crna pozadina sa lavom preko celog ekrana, iako je i to bilo na stolu:
crno + crveno dete čita kao opasnost pre nego što išta prepozna, lica sa malim
tamnim očima se na crnom gube (ceo sistem lica stoji na svetlom licu), a četvrti
screenshot koji je crn pored tri svetla ne izgleda kao isti app. Sumrak daje
istu dramu bez toga. **Lava postoji ali daleko i u koritu — nikad pod nogama
nekog bića.**

Dobitak koji se ne sme izgubiti u kasnijim iteracijama: krem kapije na tamnoj
pozadini imaju najjači kontrast koji igra do sada nije imala, a „dete ne zna gde
da tapne" je jedini dokazani problem koji imamo.

Svet time dobija raspon: **staza preko lave** je najtamniji ekran u igri,
**jaja** najsvetliji.

Šablon kretanja je okean, ne farma — ništa ne stoji mirno:

- **arukarija na desnoj ivici** (krošnja do y 0.20) — oslonac cele kompozicije.
  Palma je odbačena 02.09.2026: čita se kao plaža i nije iz tog doba
- **brontosaurus u punoj figuri hoda** s leva do drveta, digne vrat i pase
  krošnju; traka peska od x 0.05 do x 0.85 mora ostati prazna da šetnja ne
  prolazi iza žbunja
- **pterodaktil preleti** u pojasu neba između y 0.26 i y 0.40 — ispod reda
  kapija, da nikad ne udara u UI
- vulkan daleko pozadi, manji i mutniji nego u prvoj skici (inače se bori sa
  drvetom za pažnju). **Erupcija je uvedena 02.09.2026** (90 frejmova,
  `volcano-erupt-1..90`, ~4,5 s na 20 sličica u sekundi, na svakih 20–35 s):
  lava se prelije preko ivice kratera i sklizne niz bok. Bez praska, bez
  pepela u nebo i bez lave koja stigne do scene — pravilo "ništa strašno"
  važi i za nju
- mali dino viri iz paprati i sakrije se na dodir
- **jezerce ohlađene lave** mehuri: tamna kora sa žarećim pukotinama, jedini
  izvor svetla u prednjem planu (odbačena crna katranska bara — u njoj se ništa
  nije videlo). Puna tečna lava ne dolazi u obzir tamo gde biće hoda
- paprat se leluja oko oslonca na dnu (isti `_sway` mehanizam kao korali)

Četiri kapije bez teksta: jaje, kamen na lavi, kost, kula.

**Kako se anima naručuje — isto kao okean:** jedna statična kompozicija bez
velikih bića, pa odvojeno nizovi frejmova (sabljarka je 24 frejma
`swordfish-1..24.svg`, meduza 20). Za dinosauruse: `bronto-walk-1..24`,
`bronto-graze-1..12`, `ptero-1..16`. Svi frejmovi jednog niza moraju imati
identičan viewBox i biće na istom mestu u kadru — inače sprite trza. Kod ih
vrti na ~11 fps. Rig sa pivotima (`_rig_parts`) ostaje samo za sitne delove.

## Zvuk

Dinosauruse niko nije čuo. Filmska rika je isključena dvaput: zato što plaši i
zato što je izmišljena, a sintetičke zvuke smo već jednom izbacili iz igre
(v1.0.3).

**Glas im je nizak, mekan "hu-hu"** — pravi snimci golubova, sova i velikih
ptica spušteni u visini, jer ptice i jesu dinosaurusi. Po biću druga visina
(bronto najniže, ptero najviše), isti postupak kao mehurići u okeanu. T-Rex
dobija blesavo zevanje umesto rike.

Sa Mixkita/Pixabaya treba: pucanje ljuske jajeta, korak teške životinje (tup),
kamen na kamen (za kulu i stazu), kotrljanje kamenja, tiho brisanje peska,
nizak tutanj vulkana (jedva čujan, ambijent), mehur u gustoj tečnosti, ptičji
glasovi za spuštanje u visini.

**Odlučeno protiv: mikrofon za rikanje.** Dozvola za mikrofon u Kids kategoriji
kvari čist "collects no data" status koji se čuva.

## Art koji treba naručiti

Isti stil kao farma/džungla/okean, baby-schema obavezno.

1. `background-dino` — sumračna dolina: šljivasto nebo, narandžast horizont,
   vulkan-silueta, jezerce lave, pesak sa toplim odsjajem
2. `card-dino` + `title-dino` (crtani SVG naslov, ne font — kao ostala tri)
3. Šest bića: `trex`, `bronto`, `trike`, `stego`, `ptero`, `anky`
4. Bebe verzije za jaja (mogu biti ista lica umanjena, kao u okeanu)
5. Jaje u tri stanja pukotine + gnezdo
6. Kosti za kostur (5–6 komada) i tabla sa obrisom
7. Kamen za slaganje (2–3 oblika, rotiraju se iz koda) i kamen-ploča za lavu
8. Pozadine igara: `background-eggs`, `background-lava`, `background-dig`,
   `background-tower`
9. Rekviziti huba: arukarija (stablo + krošnja u slojevima), paprat, cikasi,
    stene, `lava-pool`, žar-čestica
9b. Nizovi frejmova: `bronto-walk-1..24`, `bronto-graze-1..12`, `ptero-1..16`
10. Četiri ikonice kapija: jaje, kamen na lavi, kost, kula
11. **Mock-kompozicija huba sa tačnim frakcijama ekrana** — tražiti izričito,
    to je kod okeana uštedelo najviše vremena

## Šta kod mora da dotakne

- `core/animals.gd` — `const DINO` + `by_id_dino()`
- `core/main.gd` — pet novih unosa u `SCREENS` (`dino`, `eggs`, `lava`, `dig`,
  `tower`), plus `WORLD_HUBS` i `NOT_GAMES`
- `screens/dino_hub.gd` — `LOCKED_GAMES := ["dig", "tower"]`, `IMPLEMENTED` (sve četiri)
- `screens/eggs_game.gd`, `lava_game.gd`, `dig_game.gd`, `tower_game.gd`
- `screens/worlds_screen.gd` — **četvrta kartica menja raspored**: sada su tri
  na 0.20 / 0.50 / 0.80; sa četiri ide 0.14 / 0.38 / 0.62 / 0.86, uz proveru da
  kartice ne postanu presitne na 4:3
- `hint_spot()` u sve četiri igre — od 1.1.2 to nije opcija
- provera rasporeda u **16:9, 3:2 (1920×1280) i 4:3 (1920×1440)** pre izdanja,
  kako je urađeno u 1.1.1
- store listing: novi screenshotovi (iskopavanje je nosilac), i verzija u App
  Store Connect-u mora tačno da odgovara `application/short_version`

## Paleta — vulkanski sumrak (zaključana 02.09.2026)

Boje žive u samim SVG fajlovima, kao i u okeanu — `palette.gd` dobija samo ono
što kod stvarno crta (dugmad, konfete, pokazivač). Ovo je referenca za sve
buduće assete ovog sveta, da četiri ekrana igara ostanu u istom svetlu.

| ime | hex | gde |
|---|---|---|
| sky-top | `#2E2140` | duboko šljivasto teme neba |
| sky-plum | `#3C2645` | drugi pojas neba |
| sky-mid | `#4A2B4A` | nebo iza dugmadi |
| sky-rose-deep | `#6B3448` | četvrti pojas |
| sky-glow | `#8A3F45` | prašnjava ružičasta |
| sky-warm | `#A94A40` | greje se ka horizontu |
| horizon-red | `#C25A3C` | pojas horizonta |
| horizon-orange | `#DC7743` | niži horizont |
| horizon-gold | `#E8944C` | najsvetlije nebo, uz greben |
| glow-wash | `#F0A45C` | široka meka elipsa sjaja |
| glow-core | `#FFC489` | unutrašnja elipsa sjaja |
| ember | `#FFB866` | žar-čestice, topla ivica stena i paprati |
| ember-core | `#FFE0B8` | središte žara |
| araucaria-dark | `#12291F` | slojevi krošnje, vrh |
| araucaria-mid | `#183328` | slojevi krošnje |
| araucaria-tier | `#1B3E31` | naizmenični slojevi grana |
| volcano-dark | `#2A2030` | silueta vulkana, jezgro stabla |
| volcano-shade | `#372A3D` | daleki bok vulkana |
| crater | `#F0913C` | krater, ohlađeni tragovi, jezgro lave |
| lava-body | `#C2532E` | telo lava-kanala |
| ridge-plum | `#5A3340` | daleki greben |
| ridge-warm | `#7A4740` | drugi greben |
| sand-near | `#B98A63` | prednji plan — traka za šetnju |
| sand-mid | `#A27654` | srednja terasa |
| sand-far | `#8A6349` | treća terasa |
| sand-deep | `#71503C` | terasa uz greben |
| sand-patch | `#C99A70` | meke mrlje na tlu |
| fern | `#1E4436` | osvetljeni listovi paprati i cikasa |
| fern-dark | `#16342A` | zadnji listovi, senka slojeva arukarije |
| fern-mid | `#274F3D` | naličje prednjeg lista |
| fern-rim | `#C97A4A` | topla ivica listova okrenutih ka lavi |
| rock-dark | `#2C2432` | telo stene |
| rock-lit | `#4A3A40` | strana stene okrenuta sjaju |
| trunk-lit | `#4A3140` | osvetljena strana stabla |
| trunk-ring | `#5E3E44` | prstenovi kore |
| crust | `#2A1E22` | ohlađena kora lave |
| crust-deep | `#3A2528` | toplija kora u sredini jezerca |
| crack-hot | `#F0B23C` | najsvetlije pukotine i mehurovi |
| crack-mid | `#E8703C` | srednje pukotine |
| crack-deep | `#B33A2E` | spoljne pukotine |
| glow-spill | `#C97A4A` | odsjaj na pesku, rim na kamenju i paprati |
| stone-dark | `#241B20` | venac kamenja oko jezerca |
| peek-body | `#7A5C6B` | osvetljena strana dinosaurusa u paprati |
| peek-shade | `#63495A` | njegova senka i rogovi |
| peek-muzzle | `#C9908A` | njuška |
| eye | `#26202C` | oči i osmeh |
| blush | `#E08A8A` | obraščići |
| cream | `#FDFBF6` | kapije — nepromenjeno |
| outline | `#4A3F3A` | samo potezi u ikonicama kapija |
