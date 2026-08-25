# Treći svet: OKEAN — dizajn

Status: dizajn zaključan 23.08.2026, art se naručuje, kod tek počinje.
`Animals.OCEAN` je već u `core/animals.gd`.

## Zašto nijedna igra nije reskin

Farma i džungla već pokrivaju ove veštine: povezivanje hrane i životinje,
prepoznavanje oblika (senke), čišćenje (kupanje, tuš), stalnost objekta
(žmurke), pamćenje parova (memorija) i prepoznavanje po zvuku (pogađalica).

Okean namerno uzima **četiri veštine koje nijedna postojeća igra ne dira**:
praćenje pokretne mete, veličinu, boju i slobodnu igru zvukom. Dete koje je
prešlo prva dva sveta u okeanu ne radi ništa što već zna.

## Šest bića

fish, octopus, turtle, crab, dolphin, seahorse — birana tako da im se siluete
razlikuju i kad su sitne na ekranu (izdužena, kuglasta sa kracima, oklop,
klešta, peraje, spiralni rep).

## Četiri igre

### 1. Mehurići — praćenje pokretne mete
Mehurići se dižu sa dna različitim brzinama; dete ih tapka da pucaju. Svaki
peti-šesti mehurić je krupniji i u njemu je beba nekog bića — kad pukne,
beba otpliva uz veselo glasanje.
**Novo:** sve dosadašnje igre imaju **nepokretne** mete. Ovo je prva koja traži
da dete prati nešto što se kreće i pogodi ga u pravom trenutku.
**Uči:** praćenje pogledom, koordinacija oko-ruka, tajming.

### 2. Veliki i mali — veličina
Tri bića iste vrste ali tri veličine plutaju u vodi; na dnu su tri pećine
(velika, srednja, mala). Dete prevlači svako biće u pećinu koje mu odgovara.
Pogrešna pećina biće nežno "ne primi" i ono se vrati.
**Novo:** senke uče **oblik**, ovo uči **veličinu** — druga osobina, i prva igra
u kojoj se tri stvari porede međusobno, a ne jedna prema jednoj meti.
**Uči:** poređenje po veličini, redosled malo-srednje-veliko.

### 3. Nađi boju — boja
Koral na dnu zasvetli u nekoj boji; tri ribe različitih boja plivaju iznad.
Dete tapne onu koje je iste boje. Koral onda menja boju i ide sledeći krug.
**Novo:** boja se nigde u igri do sada ne koristi kao pravilo. Uputstvo je
čisto vizuelno (koral pulsira), pa ostaje pravilo "bez teksta".
**Uči:** prepoznavanje i imenovanje boja, praćenje vizuelnog uputstva.

### 4. Podvodni orkestar — slobodna igra zvukom
Šest bića poređanih po dnu; svako je jedna nota pentatonike. Tap = nota +
biće poskoči i zasvetli. Nema cilja, nema kraja, nema greške — dete pravi
muziku. Pentatonika znači da bilo koji redosled zvuči lepo.
**Novo:** prva igra bez zadatka i bez pobede. Za uzrast 2–3 ovo je često
omiljeni ekran, jer je uzrok-posledica trenutna i potpuno pod kontrolom deteta.
**Uči:** uzrok i posledica, ritam, sloboda bez straha od greške.

Prve dve igre su besplatne, druge dve iza kapije — isti raspored kao farma i
džungla, i pokriveno obećanjem "all worlds forever" u IAP opisu.

## Zvuk — važno, naučeno na žirafi

Morska bića su uglavnom nema. Ako im damo izmišljene "glasove", ispašće lažno
isto kao sintetički đinglovi koje smo danas izbacili.

Plan: **mehurići su njihov glas.** Jedan pravi snimak mehurića, po biću u
drugoj visini (kit dole, morski konjic gore) — isti postupak kao žvakanje za
žirafu i nilskog konja. Izuzetak je delfin, koji ima prava, vesela i nimalo
strašna kliktanja; njega tražiti kao pravi snimak.

Sa Mixkita/Pixabaya treba: mehurići (kratki, pojedinačni), delfin, blag
podvodni ambijent za pozadinu, "pop" za pucanje mehurića, i tiho zapljuskivanje.

## Art koji treba naručiti

Sve u istom stilu kao farma i džungla, i **obavezno po baby-schema pravilu**:
veliko prazno čelo, MALE pune tamne oči NISKO na licu, obraščići uz oči, mali
osmeh. Velike oči su deci strašne — to je već potvrđeno kroz četiri iteracije.

1. `background-ocean` — podvodna scena, pesak sa dnom, snopovi svetla odozgo
2. `card-ocean` — kartica sveta za izbor (uz card-farm i card-jungle)
3. Šest lica: `fish`, `octopus`, `turtle`, `crab`, `dolphin`, `seahorse`
4. Bebe verzije za mehuriće (mogu biti ista lica umanjena)
5. Rekviziti huba: korali, morska trava, školjke, potonuli sanduk, kamen
6. Mehurić (jedan SVG, više veličina kroz skaliranje)
7. Tri pećine za igru veličina (velika/srednja/mala, ista silueta)
8. Koral koji svetli za igru boja (jedan oblik, boja se menja iz koda)
9. Četiri ikonice kapija: mehurić, tri veličine, paleta boja, nota
10. **Mock-kompozicija huba sa tačnim proporcijama (fractions)** — to je
    prošli put uštedelo najviše vremena, tražiti izričito.
