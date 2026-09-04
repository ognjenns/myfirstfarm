#!/usr/bin/env python3
"""Seče kupljene džungla pakete (gamedeveloperstudio) u game/art/jungle/.

Životinje: <id>-<anim>-<n>.png, isti isečak za sve animacije jedne životinje
(stopala ostaju na istom mestu pri smeni). Papagaj je iz spritesheet-ova sa
različitim platnima, pa se svaka animacija poravnava po dnu i sredini.
"""
from PIL import Image, ImageDraw, ImageFilter
import glob, os

DL = os.path.expanduser('~/Downloads')
OUT = os.path.join(os.path.dirname(__file__), '..', 'game', 'art', 'jungle')
os.makedirs(OUT, exist_ok=True)
MAXDIM = 420  # najveća strana platna posle skaliranja

def pack(prefix):
    return [p for p in glob.glob(os.path.join(DL, prefix + '*')) if os.path.isdir(p)][0]

MONKEY = pack('Animated2Dmonkey')
HIPPO = pack('Animatedhippopotamus')
ELEPHANT = pack('2Danimatedelephant')
GIRAFFE = pack('Animatedgiraffe')
PARROT = pack('Animatedparrot')
JUNGLE = pack('Megajunglescene')

def frames(pat):
    fs = sorted(glob.glob(pat))
    assert fs, pat
    return [Image.open(f).convert('RGBA') for f in fs]

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

def animal_same_canvas(aid, anims):
    """anims: {name: [frames]} — sve na istom platnu."""
    allf = [f for fs in anims.values() for f in fs]
    bb = union_bbox(allf)
    pad = 4
    bb = (max(0, bb[0] - pad), max(0, bb[1] - pad), min(allf[0].width, bb[2] + pad), min(allf[0].height, bb[3] + pad))
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    scale = MAXDIM / max(w, h)
    for name, fs in anims.items():
        for i, f in enumerate(fs):
            size = save('%s-%s-%d' % (aid, name, i + 1), f.crop(bb), scale)
    print(aid, 'canvas', (w, h), '->', size, {k: len(v) for k, v in anims.items()})

def animal_align_bottom(aid, anims):
    """Različita platna: svaka animacija se seče po svom uniji-okviru i
    poravnava po dnu (stopala) i sredini u zajedničko platno."""
    crops = {}
    for name, fs in anims.items():
        bb = union_bbox(fs)
        crops[name] = [f.crop(bb) for f in fs]
    W = max(c[0].width for c in crops.values())
    H = max(c[0].height for c in crops.values())
    scale = MAXDIM / max(W, H)
    for name, fs in crops.items():
        for i, f in enumerate(fs):
            canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            canvas.paste(f, ((W - f.width) // 2, H - f.height), f)
            size = save('%s-%s-%d' % (aid, name, i + 1), canvas, scale)
    print(aid, 'canvas', (W, H), '->', size, {k: len(v) for k, v in anims.items()})

# --- majmun: na tlu (čučeći) + na lijani -------------------------------
mk = lambda n: frames(os.path.join(MONKEY, 'keyframes', '__monkey_%s_*.png' % n))
animal_same_canvas('monkey', {
    'idle': mk('crouched_idle'),
    'walk': mk('crouched_walk'),
    'jump': mk('standing_jump'),
})
animal_same_canvas('monkey-vine', {
    'idle': mk('on_vine_idle_no_vine'),
    'bounce': mk('on_vine_up_down_no_vine'),
})

# --- nilski konj ---------------------------------------------------------
hp = lambda n: frames(os.path.join(HIPPO, 'keyframes', '__grey_blue_hippo_%s_*.png' % n))
animal_same_canvas('hippo', {'idle': hp('idle'), 'walk': hp('walk'), 'bite': hp('bite')})

# --- slon -----------------------------------------------------------------
el = lambda n: frames(os.path.join(ELEPHANT, 'keyframes', '__grey_elephant_%s_*.png' % n))
animal_same_canvas('elephant', {'idle': el('idle'), 'walk': el('walk'), 'blow': el('blow_trunk')})

# --- žirafa: pase = saginjanje dole pa gore; tačka = pruža vrat pa nazad --
gf = lambda n: frames(os.path.join(GIRAFFE, 'keyframes', 'light', '__giraffe_light_patches_%s_*.png' % n))
reach = gf('reaching_uppose')
animal_same_canvas('giraffe', {
    'idle': gf('idle'), 'walk': gf('walk'),
    'graze': gf('bend_down') + gf('bend_up'),
    'reach': reach + reach[::-1],
})

# --- papagaj: CRVENA varijanta paketa (Ognjen, 04.09.2026), stoji/hoda, na
# dodir zaleprša. Plavi se ne koristi; papagaj u džungli ne preleće ekran. ---
def parrot(base, aid):
    sheets = os.path.join(base, 'spritesheets')
    anims = {'fly': sheet_frames(glob.glob(os.path.join(sheets, 'parrot-flying-spritesheet*.png'))[0], 1390, 1299),
             'idle': sheet_frames(glob.glob(os.path.join(sheets, 'parrot-idle-with-blink*.png'))[0], 1228, 863),
             'walk': sheet_frames(glob.glob(os.path.join(sheets, 'parrot-walking*.png'))[0], 1236, 931)}
    animal_align_bottom(aid, anims)

parrot(os.path.join(PARROT, 'parrot-update-red-parrot'), 'parrot')

# --- scenografija ---------------------------------------------------------
ENV = os.path.join(JUNGLE, 'enviromental_assets')
def env(src, name, scale=0.5):
    im = Image.open(os.path.join(ENV, src)).convert('RGBA')
    bb = im.getbbox()
    im = im.crop(bb)
    size = save(name, im, scale)
    print(name, size)

env('trees/tree_top_1.png', 'canopy-1', 0.6)
env('trees/tree_top_2.png', 'canopy-2', 0.6)
env('trees/light_trees/light_trunk_4.png', 'trunk-1', 0.45)
env('trees/light_trees/light_trunk_2.png', 'trunk-2', 0.45)
env('trees/dark_trees/light_trunk_3.png', 'trunk-3', 0.45)
env('trees/dark_trees/light_trunk_5.png', 'trunk-4', 0.45)
env('trees/light_trees/branch_3.png', 'branch-1', 0.45)
env('trees/dark_trees/branch_4.png', 'branch-2', 0.45)
env('trees/light_trees/long_branch.png', 'branch-long', 0.45)
env('trees/side_screen_branch.png', 'side-branch', 0.5)
env('trees/branch_leaves_bright_green.png', 'branch-leaves', 0.5)
env('trees/fallen_trunk.png', 'fallen-trunk', 0.5)
env('trees/light_trees/old_cut_green_leaves.png', 'stump', 0.5)
env('vines/hanging_vine.png', 'vine-hang', 0.5)
env('vines/hanging_vine_long.png', 'vine-hang-long', 0.5)
env('vines/vine_1.png', 'vine-1', 0.5)
env('vines/vine_2.png', 'vine-2', 0.5)
env('vines/vine_4.png', 'vine-4', 0.5)
env('palms/palm_trunk_1_dark_brown.png', 'palm-trunk', 0.45)
env('palms/palm_leaves_1_bright_green.png', 'palm-leaves', 0.45)
env('bushes/bush_1_bright_green.png', 'bush-1', 0.5)
env('bushes/bush_2_bright_green.png', 'bush-2', 0.5)
env('bushes/bush_1_dark_green.png', 'bush-3', 0.5)
env('bushes/ground_leaves_bright_green.png', 'ground-leaves', 0.5)
env('bushes/leaves_1_bright_green_small.png', 'tuft-1', 0.5)
env('bushes/leaves_1_light_green_small.png', 'tuft-2', 0.5)
env('bushes/leaves_1_dark_green_big.png', 'tuft-3', 0.5)
env('bushes/plant_bright_green.png', 'plant-1', 0.5)
env('bushes/plant_light_green.png', 'plant-2', 0.5)
env('bushes/leaf_1_bright_green.png', 'leaf-1', 0.5)
env('bushes/leaf_2_bright_green.png', 'leaf-2', 0.5)
env('rocks/rock_1.png', 'rock-1', 0.5)
env('rocks/rock_2.png', 'rock-2', 0.5)
env('rocks/rock_3.png', 'rock-3', 0.5)
env('rocks/rock_4.png', 'rock-4', 0.5)
env('rocks/rock_5.png', 'rock-5', 1.0)   # ravna ploča: puna mera, jer stoji krupno kao postolje
env('rocks/rock_head_2.png', 'rock-head', 0.5)   # mirniji totem (rock_head je namršten)
env('rocks/rock_head.png', 'rock-head-2', 0.5)
env('vines/large_full_screen_vines.png', 'vines-top', 0.5)
env('rocks/grass_drape.png', 'grass-drape', 0.5)
env('rocks/grass_top_2.png', 'grass-top', 0.5)
env('flowers/flower_3_red.png', 'flower-red', 0.5)
env('flowers/flower_3_yellow.png', 'flower-yellow', 0.5)
env('flowers/flower_4_blue.png', 'flower-blue', 0.5)
env('flowers/vine_flower_purple.png', 'flower-purple', 0.5)

# pozadina po uzoru na promo sliku paketa: samo nebo-gradijent iz paketa sa
# mekim svetlijim sjajem u sredini. Bez silueta i drveća — sve ranije
# varijante (gotova background_fixed, pa siluete) bile su prenatrpane.
# Smeđa traka tla se crta u igri (JungleScene.background), jer mora da stoji
# na istoj visini ekrana bez obzira na odnos strana.
BGD = os.path.join(JUNGLE, 'background')
BW, BH = 2400, 1350
bg = Image.open(os.path.join(BGD, 'sky.png')).convert('RGB').resize((BW, BH))
glow = Image.new('L', (BW, BH), 0)
gd = ImageDraw.Draw(glow)
cx, cy = BW * 0.5, BH * 0.55
for i in range(40, 0, -1):
    r = i / 40.0
    gd.ellipse((cx - BW * 0.55 * r, cy - BH * 0.55 * r, cx + BW * 0.55 * r, cy + BH * 0.55 * r), fill=int(70 * (1 - r)))
glow = glow.filter(ImageFilter.GaussianBlur(120))
bg = Image.composite(Image.new('RGB', (BW, BH), (210, 255, 150)), bg, glow).convert('RGBA')
# siluete šume iz paketa preko gradijenta, prigušene — "šuma kao senka"
# (Ognjen, 04.09.2026). Sloj 04 (tamna trava) ne treba: tlo je smeđa traka.
for name, alpha in [('farground_01', 0.55), ('farground_02', 0.40), ('farground_03', 0.45)]:
    lay = Image.open(os.path.join(BGD, name + '.png')).convert('RGBA')
    lay = lay.resize((BW, round(lay.height * BW / lay.width)), Image.LANCZOS)
    r, g, b, a = lay.split()
    lay = Image.merge('RGBA', (r, g, b, a.point(lambda v: int(v * alpha))))
    c = Image.new('RGBA', (BW, BH), (0, 0, 0, 0))
    c.paste(lay, (0, BH - lay.height), lay)
    bg = Image.alpha_composite(bg, c)
bg = bg.convert('RGB')
bg.save(os.path.join(OUT, 'bg.png'), optimize=True)

# dublja šuma za memoriju ("stari hram"): siluete jače, uz tamnu travu dole
deep = Image.open(os.path.join(BGD, 'sky.png')).convert('RGBA').resize((BW, BH))
for name, alpha in [('farground_01', 0.9), ('farground_02', 0.75), ('farground_03', 0.85), ('farground_04', 1.0)]:
    lay = Image.open(os.path.join(BGD, name + '.png')).convert('RGBA')
    lay = lay.resize((BW, round(lay.height * BW / lay.width)), Image.LANCZOS)
    r, g, b, a = lay.split()
    lay = Image.merge('RGBA', (r, g, b, a.point(lambda v: int(v * alpha))))
    c = Image.new('RGBA', (BW, BH), (0, 0, 0, 0))
    c.paste(lay, (0, BH - lay.height), lay)
    deep = Image.alpha_composite(deep, c)
deep.convert('RGB').save(os.path.join(OUT, 'bg-deep.png'), optimize=True)
print('bg-deep')
print('bg', bg.size)

# hrana za žirafu: list iz paketa u kvadrat 320 (kao kupljeno povrće)
leaf = Image.open(os.path.join(ENV, 'bushes', 'leaf_1_bright_green.png')).convert('RGBA')
leaf = leaf.crop(leaf.getbbox())
sc = 300 / max(leaf.size)
leaf = leaf.resize((round(leaf.width * sc), round(leaf.height * sc)), Image.LANCZOS)
sq = Image.new('RGBA', (320, 320), (0, 0, 0, 0))
sq.paste(leaf, ((320 - leaf.width) // 2, (320 - leaf.height) // 2), leaf)
sq.save(os.path.join(os.path.dirname(__file__), '..', 'game', 'art', 'food', 'leaves.png'), optimize=True)
print('food leaves', sq.size)

# --- lav: kupljen je NAMRŠTEN (obrve). Keyframe-ovi su spljošteni, pa se
# sličice ponovo sklapaju iz Spriter fajla (assets/spriter_render.py) bez
# obrva (kao ostale životinje paketa). Zubi ostaju — bez njih je "krezav"
# (Ognjen, 04.09.2026). ---------------------------------------------------
import sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from spriter_render import Spriter
from PIL import ImageDraw, ImageChops

LION = pack('Animatedlioncartoonsprite')
LION_PARTS = os.path.join(LION, 'spriter_file_png_parts')

def friendly_jaw():
    """jaw.png bez očnjaka: obriše se sve iznad crne linije usne."""
    j = Image.open(os.path.join(LION_PARTS, 'jaw.png')).convert('RGBA')
    mask = Image.new('L', j.size, 255)
    ImageDraw.Draw(mask).polygon([(0, 0), (640, 0), (640, 540), (600, 572), (500, 603), (400, 650), (380, 705), (0, 705)], fill=0)
    r, g, b, a = j.split()
    out = Image.merge('RGBA', (r, g, b, ImageChops.multiply(a, mask)))
    path = os.path.join(tempfile.gettempdir(), 'lion_jaw_friendly.png')
    out.save(path)
    return path

def lion():
    sp = Spriter(os.path.join(LION_PARTS, 'lion.scml'),
                 adjust={'eyebrow_left.png': {'hide': True}, 'eyebrow_right.png': {'hide': True}})
    # Razmak sličica kao u kupljenom izvozu (animation_export_info.png):
    # stajanje 50 ms (20), hod 62 ms (16), skok 100 ms (10). U .scml fajlu
    # svuda piše 100, pa se ne sme uzeti odatle.
    # tačka na dodir je RIKA (Ognjen: "stavi mu da riče"), skok ne treba
    anims = {'idle': ('idle', 50), 'walk': ('walk', 62), 'roar': ('roar', 100)}
    RS = 0.45   # ista mera kao kupljeni keyframe-ovi
    times = {a: [i * dt for i in range(int(1000 // dt))] for a, dt in anims.values()}
    bb = sp.bounds('lion', [a for a, _ in anims.values()], RS, times=times)
    W, H = int(bb[2] - bb[0]) + 12, int(bb[3] - bb[1]) + 12
    off = (6 - bb[0], 6 - bb[1])
    frames = {}
    for ours, (theirs, _) in anims.items():
        frames[ours] = [sp.render('lion', theirs, t, RS, (W, H), off) for t in times[theirs]]
    animal_same_canvas('lion', frames)

lion()
