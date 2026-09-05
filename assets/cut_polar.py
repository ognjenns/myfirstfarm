#!/usr/bin/env python3
"""Seče kupljene polarne pakete (gamedeveloperstudio) u game/art/polar/.

Životinje: <id>-<anim>-<n>.png, isti isečak za sve animacije jedne životinje
(stopala ostaju na istom mestu pri smeni). Lisica se sklapa iz Spriter fajla
jer kupljene sličice nemaju osmeh — glavi se docrtaju usta i oči, isto kao
lav u džungli. Medved ostaje originalan (namršten), Ognjen tako hoće.

Pozadina: gotova kompozicija paketa "Arctic scene" isečena na 2340×1080 i
zagrejana ka horizontu (nisko sunce), da se svet na ekranu svetova ne meša
sa plavim okeanom.
"""
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import glob, os, re, sys, tempfile

sys.path.insert(0, os.path.dirname(__file__))
from spriter_render import Spriter

DL = os.path.expanduser('~/Downloads')
OUT = os.path.join(os.path.dirname(__file__), '..', 'game', 'art', 'polar')
os.makedirs(OUT, exist_ok=True)
MAXDIM = 480  # najveća strana platna posle skaliranja


def pack(prefix):
    return [p for p in glob.glob(os.path.join(DL, prefix + '*')) if os.path.isdir(p)][0]


PENGUIN = pack('ThreeAnimatedpenguin')
SEAL = pack('Animatedseal')
BEAR = pack('Polarbear')
WALRUS = pack('animatedwalrus')
FOX = pack('Animatedfox')
REINDEER = pack('Animatedreindeer')
ARCTIC = pack('Arcticscene')


def frames(pat):
    """Sličice po glob šablonu; `pat` sme da bude regex-strog (tačan prefiks)."""
    d, base = os.path.split(pat)
    rx = re.compile('^' + re.escape(base).replace(r'\*', r'\d+') + '$')
    fs = sorted(f for f in os.listdir(d) if rx.match(f))
    assert fs, pat
    return [Image.open(os.path.join(d, f)).convert('RGBA') for f in fs]


def sheet_frames(path, fw, fh):
    im = Image.open(path).convert('RGBA')
    cols, rows = im.width // fw, im.height // fh
    out = []
    for r in range(rows):
        for c in range(cols):
            fr = im.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh))
            if fr.getbbox():
                out.append(fr)
    return out


def union_bbox(imgs):
    bb = None
    for im in imgs:
        b = im.getbbox()
        if b is None:
            continue
        bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    return bb


def save(name, im, scale):
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    im.save(os.path.join(OUT, name + '.png'), optimize=True)
    return im.size


def animal_same_canvas(aid, anims, maxdim=MAXDIM):
    """anims: {name: [frames]} — sve na istom platnu."""
    allf = [f for fs in anims.values() for f in fs]
    bb = union_bbox(allf)
    pad = 4
    bb = (max(0, bb[0] - pad), max(0, bb[1] - pad), min(allf[0].width, bb[2] + pad), min(allf[0].height, bb[3] + pad))
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    scale = maxdim / max(w, h)
    for name, fs in anims.items():
        for i, f in enumerate(fs):
            size = save('%s-%s-%d' % (aid, name, i + 1), f.crop(bb), scale)
    print(aid, 'canvas', (w, h), '->', size, {k: len(v) for k, v in anims.items()})


# --- pingvin: veliki (1) je glavni, mali (3) je beba ------------------------
def penguin(n, aid):
    pk = lambda a: frames(os.path.join(PENGUIN, 'keyframes', 'penguin_%d' % n, '__penuin_%d_%s_*.png' % (n, a)))
    animal_same_canvas(aid, {'idle': pk('idle'), 'walk': pk('walk'), 'jump': pk('jump'), 'fall': pk('fall_back')})

penguin(1, 'penguin')
penguin(3, 'penguin3')

# --- foka: krem odrasla, bela beba -------------------------------------------
def seal(color, aid):
    sk = lambda a: frames(os.path.join(SEAL, 'keyframes', '__%s_seal_%s_*.png' % (color, a)))
    animal_same_canvas(aid, {
        'idle': sk('idle_on_land'), 'walk': sk('move_on_land'), 'jump': sk('move_jumping_on_land'),
        'up': sk('idle_on_land_upright'), 'swim': sk('swim'), 'float': sk('floating'),
    })

seal('cream', 'seal')
seal('white', 'seal-white')

# --- morž: smeđi -------------------------------------------------------------
wk = lambda a: frames(os.path.join(WALRUS, 'keyframes', 'brown', '__brown_walrus_%s_*.png' % a))
animal_same_canvas('walrus', {'idle': wk('laying_down'), 'walk': wk('move'), 'up': wk('idle_up_right'),
                              'swim': wk('swim'), 'float': wk('floating_in_water')})

# --- irvas: smeđi bez ama (am je ljudski rekvizit) ----------------------------
rk = lambda a: frames(os.path.join(REINDEER, 'keyframes', 'brown', '__brown_reindeer_without_harness_%s_*.png' % a))
animal_same_canvas('reindeer', {'idle': rk('idle'), 'walk': rk('walk'), 'run': rk('run'), 'eat': rk('eating')})

# --- polarna lisica: Spriter, sa osmehom i otvorenim okom ------------------------
# Kupljena lisica nema liniju usta kad su zatvorena (donja vilica je poseban
# deo samo za otvorena usta) i ima teške kapke — Ognjen: "lisica nema osmeh".
# Glavi se docrta osmeh, a oba oka zamene okruglim otvorenim.
FOX_PARTS = os.path.join(FOX, 'Spriter_file_and_body_parts')

def fox_parts():
    d = os.path.join(FOX_PARTS, 'arctic_fox')
    out = {}
    head = Image.open(os.path.join(d, 'head.png')).convert('RGBA')
    hd = ImageDraw.Draw(head)
    # osmeh: od iza njuške unazad, pa gore ka obrazu; debljina kao kontura
    hd.line([(118, 318), (150, 352), (200, 372), (255, 370), (300, 348), (326, 320)], fill=(26, 26, 26, 255), width=15, joint='curve')
    hd.ellipse((316, 306, 340, 330), fill=(26, 26, 26, 255))   # jamica na kraju osmeha
    pth = os.path.join(tempfile.gettempdir(), 'fox_head.png'); head.save(pth); out['arctic_fox/head.png'] = pth
    for name, size in [('top_eye_open', 183), ('back_eye_open', 157)]:
        eye = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        ed = ImageDraw.Draw(eye)
        r = size // 2 - 4
        c = size // 2
        ed.ellipse((c - r, c - r, c + r, c + r), fill=(240, 244, 246, 255), outline=(26, 26, 26, 255), width=max(10, size // 14))
        pr = int(size * 0.17)
        px, py = int(c - size * 0.12), int(c + size * 0.06)
        ed.ellipse((px - pr, py - pr, px + pr, py + pr), fill=(26, 26, 26, 255))
        ed.ellipse((px - pr * 0.55, py - pr * 0.75, px - pr * 0.05, py - pr * 0.25), fill=(255, 255, 255, 255))
        pth = os.path.join(tempfile.gettempdir(), 'fox_%s.png' % name); eye.save(pth); out['arctic_fox/%s.png' % name] = pth
    return out

def fox():
    sp = Spriter(os.path.join(FOX_PARTS, 'fox.scml'), overrides=fox_parts())
    ent = 'arctic_fox'
    anims = ['idle', 'walk', 'run', 'jump']
    RS = 0.45
    times = {a: [i * 100 for i in range(10)] for a in anims}
    bb = sp.bounds(ent, anims, RS, times=times)
    W, H = int(bb[2] - bb[0]) + 12, int(bb[3] - bb[1]) + 12
    off = (6 - bb[0], 6 - bb[1])
    animal_same_canvas('fox', {a: [sp.render(ent, a, t, RS, (W, H), off) for t in times[a]] for a in anims})

fox()


# --- polarni medved: ORIGINALNE sličice, bez prepravke lica ------------------
# Probano sa docrtanim osmehom i okruglim okom (Spriter) — Ognjen 05.09.2026:
# "ostavi ljutog, on mnogo prirodnije izgleda, ovi svi kao da su bili na
# plastičnoj". Namršten je, ali je dosledan crtežu.
bk = lambda a: frames(os.path.join(BEAR, 'keyframes', 'cream_white', '__cream_polar_bear_%s_*.png' % a))
animal_same_canvas('bear', {'idle': bk('idle'), 'walk': bk('walk'), 'run': bk('run')})


# --- scenografija ---------------------------------------------------------------
def env(src, name, scale=0.5):
    im = Image.open(src).convert('RGBA')
    im = im.crop(im.getbbox())
    print(name, save(name, im, scale))

FG = os.path.join(ARCTIC, 'pngs', 'foreground_parts')
BGP = os.path.join(ARCTIC, 'pngs', 'background_parts')
env(os.path.join(FG, 'floating_ice_group_01.png'), 'ice-group-1', 0.6)
env(os.path.join(FG, 'floating_ice_group_03.png'), 'ice-group-2', 0.6)
env(os.path.join(FG, 'floating_ice_piece_01.png'), 'ice-piece-1', 0.6)
env(os.path.join(FG, 'floating_ice_piece_02.png'), 'ice-piece-2', 0.6)
env(os.path.join(FG, 'floating_ice_piece_06.png'), 'ice-piece-3', 0.6)
for i in range(1, 7):
    env(os.path.join(BGP, 'floating_icebergs', 'iceberg_%02d.png' % i), 'iceberg-%d' % i, 0.6)
for i in range(1, 6):
    env(os.path.join(BGP, 'clouds', 'cloud_%02d.png' % i), 'cloud-%d' % i, 0.6)


# pozadina: gotova scena 4000×1900 -> 2340×1080 (visina se seče malo gore),
# nebo zagrejano ka horizontu + nisko sunce
BW, BH = 2340, 1080
src = Image.open(os.path.join(ARCTIC, 'examples', 'straight_foreground.png')).convert('RGB')
sw = BW / src.width
src = src.resize((BW, round(src.height * sw)), Image.LANCZOS)
top = src.height - BH          # seče se nebo odozgo, led ostaje ceo
bg = src.crop((0, top, BW, top + BH)).convert('RGBA')
# topla maska: puna na horizontu (y≈0.40), nula na vrhu i ispod horizonta
HORIZON = 0.40
warm = Image.new('L', (BW, BH), 0)
wd = ImageDraw.Draw(warm)
for y in range(int(BH * HORIZON)):
    t = y / (BH * HORIZON)
    wd.line([(0, y), (BW, y)], fill=int(150 * (t ** 1.6)))
for y in range(int(BH * HORIZON), int(BH * 0.47)):
    t = (y - BH * HORIZON) / (BH * 0.07)
    wd.line([(0, y), (BW, y)], fill=int(150 * (1 - t) * 0.5))
peach = Image.new('RGBA', (BW, BH), (255, 196, 150, 255))
bg = Image.composite(peach, bg, warm)
# ljubičast vrh neba, da nije čisto plavo
lav = Image.new('L', (BW, BH), 0)
ld = ImageDraw.Draw(lav)
for y in range(int(BH * 0.30)):
    ld.line([(0, y), (BW, y)], fill=int(70 * (1 - y / (BH * 0.30))))
bg = Image.composite(Image.new('RGBA', (BW, BH), (200, 170, 230, 255)), bg, lav)
# sunce: mek disk nisko levo, iza santi
sun = Image.new('RGBA', (BW, BH), (0, 0, 0, 0))
sd = ImageDraw.Draw(sun)
# u praznini neba između santi (x 0.33–0.45), iznad linije horizonta
sx, sy, sr = int(BW * 0.39), int(BH * 0.30), 85
for i in range(6, 0, -1):
    r = sr + i * 26
    sd.ellipse((sx - r, sy - r, sx + r, sy + r), fill=(255, 230, 170, int(22 * (7 - i) / 6)))
sd.ellipse((sx - sr, sy - sr, sx + sr, sy + sr), fill=(255, 244, 205, 255))
sun = sun.filter(ImageFilter.GaussianBlur(6))
bg = Image.alpha_composite(bg, sun)
bg.convert('RGB').save(os.path.join(OUT, 'bg-scene.png'), optimize=True)
print('bg-scene', bg.size)

# --- detalji scene (Ognjen 05.09.2026: "fale detalji, previše je prazno") ------
# ledeni kristali iz "Ice spell" paketa (kupljen usput): sličica 16 je pun rast
ICE = pack('Icespell2dgameasset')
env(os.path.join(ICE, 'frames', '16_ice_spell.png'), 'crystal', 0.4)
# jelke, sneško i ledeno kamenje iz zimskog paketa su SVG (PNG-ovi su sitni);
# kopiraju se kao SVG, a razmera uvoza (svg/scale) se podesi u .import fajlu.
import shutil
WINTER = pack('Winternightbackdrop')
for name in ['tree_02', 'tree_03', 'tree_05', 'snowman', 'rock_group', 'rock_01']:
    shutil.copy(os.path.join(WINTER, 'SVGS', name + '.svg'), os.path.join(OUT, name.replace('_', '-') + '.svg'))
    print('svg', name)
