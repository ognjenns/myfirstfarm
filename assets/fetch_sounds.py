#!/usr/bin/env python3
"""Trazi prava glasanja zivotinja na Wikimedia Commons (CC0/PD/CC-BY),
skida .ogg kandidate u assets/real_sounds/<zivotinja>/ na pregled.
Nista ne ide direktno u igru — bira se rucno."""
import json, os, sys, urllib.parse, urllib.request

UA = {"User-Agent": "MojaFarmaAssetBot/0.1 (manevski.ognjen@gmail.com)"}
OUT = os.path.join(os.path.dirname(__file__), "real_sounds")
API = "https://commons.wikimedia.org/w/api.php"

QUERIES = {
    "cow": "cow moo sound",
    "pig": "pig oink grunt sound",
    "chicken": "chicken clucking sound",
    "goat": "goat bleat sound",
    "horse": "horse neigh sound",
    "dog": "dog bark sound",
}
OK_LICENSES = ("CC0", "Public domain", "CC BY ", "CC BY-SA")  # BY/BY-SA traze potpis — ide u CREDITS

def api(params):
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

credits = []
for animal, q in QUERIES.items():
    try:
        d = api({
            "action": "query", "generator": "search",
            "gsrsearch": q + " filetype:audio", "gsrnamespace": 6, "gsrlimit": 6,
            "prop": "imageinfo", "iiprop": "url|size|extmetadata", "format": "json",
        })
    except Exception as e:
        print(animal, "API greska:", e); continue
    pages = d.get("query", {}).get("pages", {})
    got = 0
    os.makedirs(os.path.join(OUT, animal), exist_ok=True)
    for p in sorted(pages.values(), key=lambda x: x.get("index", 99)):
        if got >= 2:
            break
        ii = (p.get("imageinfo") or [{}])[0]
        url = ii.get("url", "")
        size = ii.get("size", 0)
        meta = ii.get("extmetadata", {})
        lic = meta.get("LicenseShortName", {}).get("value", "?")
        artist = meta.get("Artist", {}).get("value", "?")
        if not url.endswith((".ogg", ".oga", ".wav")):
            continue
        if size > 2_500_000 or size < 8_000:  # predugacko/prekratko
            continue
        if not any(okl in lic for okl in OK_LICENSES):
            continue
        fname = f"{animal}_{got}" + os.path.splitext(url)[1].replace(".oga", ".ogg")
        dest = os.path.join(OUT, animal, fname)
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r, open(dest, "wb") as f:
                f.write(r.read())
            got += 1
            credits.append(f"- {fname}: {p['title']} | {lic} | {artist[:80]} | {url}")
            print("OK", animal, fname, lic, size, "b")
        except Exception as e:
            print("download fail", url[:80], e)
    if got == 0:
        print(animal, ": nista upotrebljivo")

with open(os.path.join(OUT, "CREDITS.md"), "w") as f:
    f.write("# Izvori zvukova (Wikimedia Commons)\n\nCC BY / BY-SA zahtevaju potpis autora u aplikaciji!\n\n" + "\n".join(credits) + "\n")
print("\nCREDITS.md upisan,", len(credits), "fajlova")
