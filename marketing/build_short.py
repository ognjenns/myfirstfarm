"""Sklapa vertikalni YouTube Short (1080x1920) od snimka pravog igranja.

Ulaz  : raw.avi iz `record_short.sh` (Godot Movie Maker, 1920x1080 + zvuk igre)
Izlaz : ~/Desktop/OggieGames_Reel/my-first-animals-gameplay.mp4

Igra je pejzažna, pa kadar ide u sredinu, a pozadinu pravi ista slika
razvučena, zamućena i zatamnjena. Natpise crta Pillow (ffmpeg u ovom sistemu
nema drawtext).

Tri stvari su naučene na teži način i zato posao ide u više koraka:

1. Godot u AVI upiše pogrešan takt slike — ffmpeg 26-sekundni snimak čita kao
   trinaest minuta razvučenih kadrova. Zato ulaz dobija `-r 60`.
2. Posle stvarnog zvuka Godot upiše još ~15 minuta tišine; u istom poslu sa
   slikom se zvučni red demuksera napuni i sve stane. Zato zvuk ide posebno,
   kroz sirov PCM, i spaja se tek na kraju.
3. ffmpeg 8.1.2 se zaglavljuje kad se slika daje kao ulaz preko `-loop 1`
   (natpisi, maska, senka, završna kartica) — bez ijedne poruke, sat vremena u
   mestu. Zato ovde NEMA nijednog ulaza-slike: sve što Pillow nacrta ulazi kao
   sirovi kadrovi kroz cev, koje ffmpeg troši jedan po jedan.
"""
import os, subprocess, sys, tempfile
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1080, 1920
FPS = 30
RAW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Desktop/OggieGames_Reel/raw.avi")
WORK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "short_cards")
OUTDIR = os.path.expanduser("~/Desktop/OggieGames_Reel")
OUT = f"{OUTDIR}/my-first-animals-gameplay.mp4"
ICON = os.path.expanduser("~/ProjectsFlutter/moja_farma/build/play_icon.png")

RAW_FPS = 60          # stvarni takt snimka (u AVI zaglavlju je pogrešan)
TRIM = 3.00           # snimak počinje logom koji raste; Short kreće kad slegne
MAIN = 23.10          # koliko snimka ostaje posle rezanja glave
END = 3.00            # završna kartica
FADE = 0.50           # zatamnjenje igre, pa se kartica pojavi iz crnog
FRAME_W = 1010        # širina kadra igre u vertikalnom platnu
FRAME_Y = 716         # gornja ivica kadra
STRIP_Y, STRIP_H = 300, 400   # traka sa tekstom, tačno iznad kadra
FADE_IN, FADE_OUT = 0.35, 0.40

# (početak, trajanje, naslov, podnaslov) — vreme je u gotovom videu
CAPTIONS = [
    (0.30, 3.30, "A game a two-year-old\ncan actually play", ""),
    (4.50, 3.90, "Everything reacts", "Tap anything on the screen"),
    (9.10, 4.10, "Tap a fish, it sings", ""),
    (13.80, 3.80, "Taller pillar, higher note", ""),
    (18.10, 3.90, "No score, no timer,\nno way to lose", ""),
]
END_TITLE = "My First Animals"
END_SUB = "Farm · Jungle · Ocean · Ages 2 to 5\nGoogle Play  ·  App Store"

VENC = ["-c:v", "libx264", "-preset", "medium", "-crf", "19",
        "-pix_fmt", "yuv420p", "-r", str(FPS)]


def font(size, bold=True):
    try:
        f = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", size)
        f.set_variation_by_name("Bold" if bold else "Regular")
        return f
    except Exception:
        return ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", size)


def halo_text(img, xy, txt, f, fill=(255, 255, 255), spacing=18):
    """Beli tekst sa tamnim oreolom po obliku slova.

    Pozadina se menja iz sekunde u sekundu — kremasti splash pa tamna voda —
    pa obična senka ponekad nestane. Oreol je zamućena alfa samog teksta:
    drži se slova i čita se na svakoj pozadini."""
    if not txt:
        return
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).multiline_text(xy, txt, font=f, fill=fill + (255,),
                                         anchor="mm", align="center", spacing=spacing)
    halo = layer.split()[3].filter(ImageFilter.GaussianBlur(18)).point(lambda a: min(255, int(a * 2.6)))
    dark = Image.new("RGBA", img.size, (4, 12, 20, 0))
    dark.putalpha(halo)
    img.alpha_composite(dark)
    img.alpha_composite(layer)


def build_cards():
    """Trake sa natpisima i završna kartica (za pregled se čuvaju i kao PNG)."""
    os.makedirs(WORK, exist_ok=True)
    f_head, f_sub = font(88), font(52, bold=False)
    strips = []
    for i, (_, _, head, sub) in enumerate(CAPTIONS):
        s = Image.new("RGBA", (W, STRIP_H), (0, 0, 0, 0))
        halo_text(s, (W // 2, 150), head, f_head, spacing=20)
        halo_text(s, (W // 2, 320), sub, f_sub, fill=(228, 242, 250))
        s.save(f"{WORK}/cap{i}.png")
        strips.append(s)

    # Završna kartica je crtež, ne zamrznut kadar: dublja voda, ikonica, ime.
    end = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    d = ImageDraw.Draw(end)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=(int(9 + 12 * t), int(38 + 28 * t), int(54 + 30 * t), 255))
    ic = Image.open(ICON).convert("RGB").resize((380, 380), Image.LANCZOS)
    m = Image.new("L", (380, 380), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, 379, 379], 86, fill=255)
    ic.putalpha(m)
    end.alpha_composite(ic, ((W - 380) // 2, 660))
    halo_text(end, (W // 2, 1180), END_TITLE, font(96))
    halo_text(end, (W // 2, 1390), END_SUB, font(54, bold=False), fill=(214, 233, 244), spacing=20)
    end = end.convert("RGB")
    end.save(f"{WORK}/end.png")
    return strips, end


def pipe_to_ffmpeg(cmd, frames):
    """Pokreni ffmpeg i guraj mu kadrove na stdin dok ih traži."""
    err = tempfile.TemporaryFile()
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=err)
    try:
        for buf in frames:
            p.stdin.write(buf)
        p.stdin.close()
    except BrokenPipeError:
        pass
    if p.wait() != 0:
        err.seek(0)
        sys.exit(err.read().decode()[-2000:])


def strip_frames(strips):
    """Kadrovi trake sa natpisima — po jedan za svaki kadar gotovog videa."""
    blank = Image.new("RGBA", (W, STRIP_H), (0, 0, 0, 0)).tobytes()
    alphas = [s.split()[3] for s in strips]
    cache = {}
    for n in range(round(MAIN * FPS)):
        t = n / FPS
        out = blank
        for i, (st, dur, _, _) in enumerate(CAPTIONS):
            if not (st <= t < st + dur):
                continue
            k = round(max(min((t - st) / FADE_IN, (st + dur - t) / FADE_OUT, 1.0), 0.0), 2)
            if (i, k) not in cache:
                frame = strips[i].copy()
                frame.putalpha(alphas[i].point(lambda a: int(a * k)))
                cache[(i, k)] = frame.tobytes()
            out = cache[(i, k)]
            break
        yield out


def end_frames(end):
    """Završna kartica: pojavljuje se iz crnog, pa stoji."""
    black = Image.new("RGB", (W, H), (0, 0, 0))
    cache = {}
    for n in range(round(END * FPS)):
        k = round(min(n / FPS / FADE, 1.0), 2)
        if k not in cache:
            cache[k] = Image.blend(black, end, k).tobytes()
        yield cache[k]


def build_main(strips, tmp):
    """Igra: zamućena pozadina, kadar u sredini, natpisi, zatamnjenje na kraju."""
    frame_h = round(FRAME_W * 9 / 16)
    fx = (W - FRAME_W) // 2
    fc = (
        f"[0:v]trim=start={TRIM}:duration={MAIN},setpts=PTS-STARTPTS,fps={FPS},split=2[s1][s2];"
        # pozadina: mutimo sličicu pa je uvećamo — isti izgled, višestruko brže
        f"[s1]scale=-2:300,crop=169:300,gblur=sigma=7,scale={W}:{H},"
        f"eq=brightness=-0.13:saturation=0.82[bg];"
        f"[s2]scale={FRAME_W}:{frame_h}[fg];"
        f"[bg][fg]overlay=(W-w)/2:{FRAME_Y}[v0];"
        # tanka svetla ivica odvaja kadar od zamućene pozadine
        f"[v0]drawbox=x={fx-3}:y={FRAME_Y-3}:w={FRAME_W+6}:h={frame_h+6}:"
        f"color=white@0.5:t=3[v1];"
        f"[v1][1:v]overlay=0:{STRIP_Y},format=yuv420p,"
        f"fade=t=out:st={MAIN-FADE}:d={FADE},setsar=1[vout]"
    )
    cmd = ["ffmpeg", "-y", "-v", "error",
           "-r", str(RAW_FPS), "-i", RAW,
           "-f", "rawvideo", "-pixel_format", "rgba", "-video_size", f"{W}x{STRIP_H}",
           "-framerate", str(FPS), "-i", "pipe:0",
           "-filter_complex", fc, "-map", "[vout]", "-an",
           "-t", f"{MAIN:.2f}"] + VENC + [tmp]
    pipe_to_ffmpeg(cmd, strip_frames(strips))


def build_end(end, tmp):
    cmd = ["ffmpeg", "-y", "-v", "error",
           "-f", "rawvideo", "-pixel_format", "rgb24", "-video_size", f"{W}x{H}",
           "-framerate", str(FPS), "-i", "pipe:0",
           "-vf", "format=yuv420p,setsar=1", "-an", "-t", f"{END:.2f}"] + VENC + [tmp]
    pipe_to_ffmpeg(cmd, end_frames(end))


def build_audio(tmp):
    """Zvuk igre kroz sirov PCM — dužina u AVI zaglavlju se ne može koristiti."""
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", RAW, "-vn", "-f", "s16le", "-"],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if raw.returncode != 0:
        sys.exit(raw.stderr.decode()[-2000:])
    total = MAIN + END
    # Zvuk igre je tih (prosek oko -33 dBFS), a YouTube tiho NE pojačava —
    # samo glasno stišava. Zato se izjednači na -14 LUFS, koliko Shorts i traži.
    af = (f"atrim=start={TRIM}:duration={MAIN},asetpts=N/SR/TB,"
          f"loudnorm=I=-14:TP=-1.5:LRA=11,"
          f"afade=t=in:st=0:d=0.6,apad=pad_dur={END},"
          f"afade=t=out:st={total-1.8:.2f}:d=1.8")
    r = subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar", "48000",
                        "-ac", "2", "-i", "pipe:0", "-af", af, "-t", f"{total:.2f}",
                        "-c:a", "pcm_s16le", tmp],
                       input=raw.stdout, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if r.returncode != 0:
        sys.exit(r.stderr.decode()[-2000:])


def join(main_v, end_v, audio):
    """Nastavi kartu na igru (bez ponovnog kodiranja) i dodaj zvuk."""
    os.makedirs(OUTDIR, exist_ok=True)
    lst = os.path.join(WORK, "_join.txt")
    with open(lst, "w") as f:
        f.write(f"file '{main_v}'\nfile '{end_v}'\n")
    joined = os.path.join(WORK, "_joined.mp4")
    for cmd in (
        ["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", lst,
         "-c", "copy", joined],
        ["ffmpeg", "-y", "-v", "error", "-i", joined, "-i", audio,
         "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
         "-movflags", "+faststart", OUT],
    ):
        r = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        if r.returncode != 0:
            sys.exit(r.stderr.decode()[-2000:])
    for junk in (joined, main_v, end_v, audio, lst):
        os.remove(junk)   # međukorak, pravi se ispočetka pri svakom pokretanju
    print(f"gotovo ({MAIN + END:.1f}s): {OUT}")


if __name__ == "__main__":
    if not os.path.exists(RAW):
        sys.exit(f"nema snimka: {RAW}  (prvo pokreni record_short.sh)")
    strips, end = build_cards()
    v_main = os.path.join(WORK, "_main.mp4")
    v_end = os.path.join(WORK, "_end.mp4")
    a_wav = os.path.join(WORK, "_audio.wav")
    build_audio(a_wav)
    build_end(end, v_end)
    build_main(strips, v_main)
    join(v_main, v_end, a_wav)
