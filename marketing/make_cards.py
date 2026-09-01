import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SRC = os.path.expanduser("~/Desktop/Play_Screenshots_1.1.0/phone")
OUT = "/private/tmp/claude-501/-Users-manevskiognjen-svasta/aff2515b-1833-484a-af07-bd79415d0284/scratchpad/cards"
os.makedirs(OUT, exist_ok=True)

W, H = 1620, 2880           # 1.5x of 1080x1920, downscaled by ffmpeg zoompan

def font(size, bold=True):
    try:
        f = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", size)
        f.set_variation_by_name("Bold" if bold else "Regular")
        return f
    except Exception:
        return ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", size)

F_TITLE = font(118)
F_SUB   = font(66)
F_FOOT  = font(50)

CARDS = [
    ("03-tri-sveta.png", "A game your toddler\ncan't get wrong.", "Ages 2 and up"),
    ("02-farma.png",     "Farm",                                  "Feed them. Wash them. Find them."),
    ("04-dzungla.png",   "Jungle",                                "Match, listen, guess"),
    ("01-okean.png",     "Ocean",                                 "Bubbles, reefs, and a tiny orchestra"),
    ("05-orkestar.png",  "12 gentle games",                       "Three growing worlds"),
    ("06-boje.png",      "No text to read",                       "So they play on their own"),
    ("07-ribica.png",    "No timers",                             "Nothing to lose. Nothing to rush."),
    ("08-za-roditelje.png", "No ads. Ever.",                      "One purchase. Every world, forever."),
    (None,               "My First Animals",                      "Free on the App Store\nand Google Play"),
]

def rounded(img, r):
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.size[0]-1, img.size[1]-1], r, fill=255)
    out = img.convert("RGBA"); out.putalpha(m); return out

def cover(img, w, h):
    s = max(w/img.width, h/img.height)
    im = img.resize((round(img.width*s), round(img.height*s)), Image.LANCZOS)
    return im.crop(((im.width-w)//2, (im.height-h)//2, (im.width-w)//2+w, (im.height-h)//2+h))

def text_shadow(d, xy, txt, f, fill=(255,255,255), anchor="mm", spacing=18):
    x, y = xy
    d.multiline_text((x+4, y+6), txt, font=f, fill=(0,0,0,110), anchor=anchor,
                     align="center", spacing=spacing)
    d.multiline_text((x, y), txt, font=f, fill=fill, anchor=anchor,
                     align="center", spacing=spacing)

for i, (shot, title, sub) in enumerate(CARDS):
    bg_src = shot or "01-okean.png"
    src = Image.open(os.path.join(SRC, bg_src)).convert("RGB")

    bg = cover(src, W, H).filter(ImageFilter.GaussianBlur(70))
    bg = Image.blend(bg, Image.new("RGB", (W, H), (9, 20, 30)), 0.52)
    card = bg.convert("RGBA")
    grad = Image.new("L", (1, H))
    for y in range(H):
        t = y / (H - 1)
        grad.putpixel((0, y), int(150 * (1 - t) ** 1.6 + 130 * t ** 2.2))
    veil = Image.new("RGBA", (W, H), (6, 16, 26, 0))
    veil.putalpha(grad.resize((W, H)))
    card = Image.alpha_composite(card, veil)

    if shot:
        fw = 1450
        fg = src.resize((fw, round(fw*src.height/src.width)), Image.LANCZOS)
        fg = rounded(fg, 46)
        fx, fy = (W-fw)//2, 1560 - fg.height//2
        sh = Image.new("RGBA", (W, H), (0,0,0,0))
        ImageDraw.Draw(sh).rounded_rectangle(
            [fx+10, fy+22, fx+fw+10, fy+fg.height+22], 46, fill=(0,0,0,120))
        card = Image.alpha_composite(card, sh.filter(ImageFilter.GaussianBlur(28)))
        card.alpha_composite(fg, (fx, fy))
        ty, sy = 900, 2180
    else:
        ic = Image.open(os.path.expanduser(
            "~/ProjectsFlutter/moja_farma/build/play_icon.png")).convert("RGB")
        ic = rounded(ic.resize((430, 430), Image.LANCZOS), 96)
        card.alpha_composite(ic, ((W - 430) // 2, 980))
        ty, sy = 1610, 1940

    d = ImageDraw.Draw(card)
    text_shadow(d, (W//2, ty), title, F_TITLE)
    text_shadow(d, (W//2, sy), sub, F_SUB, fill=(226, 240, 248))
    text_shadow(d, (W//2, 2690), "oggiegames.com", F_FOOT, fill=(190, 210, 222))

    card.convert("RGB").save(f"{OUT}/card{i:02d}.png", quality=95)
    print("card", i, title.replace("\n", " / "))
