import os, subprocess

CARDS = sorted(f"cards/{f}" for f in os.listdir("cards") if f.startswith("card"))
MUSIC = os.path.expanduser("~/ProjectsFlutter/moja_farma/game/sfx/music.wav")
OUTDIR = os.path.expanduser("~/Desktop/OggieGames_Reel")
os.makedirs(OUTDIR, exist_ok=True)
OUT = f"{OUTDIR}/my-first-animals-reel.mp4"

SEG, FADE, FPS = 2.2, 0.45, 30
N = len(CARDS)
total = N * SEG - (N - 1) * FADE
frames = round(SEG * FPS)

cmd = ["ffmpeg", "-y"]
for c in CARDS:
    cmd += ["-loop", "1", "-t", str(SEG), "-i", c]
cmd += ["-i", MUSIC]

fc = []
for i in range(N):
    # alternate slow push-in / pull-out so it never feels mechanical
    z = (f"min(zoom+0.00085,1.11)" if i % 2 == 0
         else f"if(eq(on,0),1.11,max(zoom-0.00085,1.0))")
    fc.append(
        f"[{i}:v]scale=1620:2880,zoompan=z='{z}':d={frames}"
        f":x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'"
        f":s=1080x1920:fps={FPS},setsar=1[v{i}]")

prev = "v0"
for i in range(1, N):
    off = round(i * (SEG - FADE), 3)
    lbl = f"x{i}"
    fc.append(f"[{prev}][v{i}]xfade=transition=fade:duration={FADE}:offset={off}[{lbl}]")
    prev = lbl

fc.append(f"[{N}:a]atrim=0:{total},asetpts=N/SR/TB,"
          f"afade=t=in:st=0:d=0.4,afade=t=out:st={total-1.4}:d=1.4,"
          f"volume=0.9[aout]")

cmd += ["-filter_complex", ";".join(fc),
        "-map", f"[{prev}]", "-map", "[aout]",
        "-c:v", "libx264", "-preset", "medium", "-crf", "20",
        "-pix_fmt", "yuv420p", "-r", str(FPS),
        "-c:a", "aac", "-b:a", "192k", "-shortest", OUT]

print(f"{N} kartica, {total:.1f}s")
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
print("gotovo:", OUT)
