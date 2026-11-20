import os
import subprocess
from PIL import Image

video_dir = r"C:\projects\in progress\Riayati\05-marketing\video"
stills_dir = os.path.join(video_dir, "out", "stills")
os.makedirs(stills_dir, exist_ok=True)

test_frames = [
    ("Promo", 120, "promo_120.png"),
    ("Promo", 310, "promo_310.png"),
    ("Promo", 600, "promo_600.png"),
    ("PromoVertical", 120, "promo_v_120.png"),
    ("PromoVertical", 310, "promo_v_310.png"),
    ("PromoVertical", 600, "promo_v_600.png"),
    ("HowTo", 150, "howto_150.png"),
    ("HowTo", 530, "howto_530.png"),
    ("HowTo", 920, "howto_920.png"),
    ("Problems", 180, "prob_180.png"),
    ("Story", 250, "story_250.png"),
    ("StoryVertical", 480, "story_v_480.png"),
    ("LogoLight", 75, "logo_light_75.png"),
    ("LogoDark", 75, "logo_dark_75.png"),
]

for comp, frame, outname in test_frames:
    outpath = os.path.join(stills_dir, outname)
    cmd = f'npx remotion still src/index.ts {comp} "{outpath}" --frame={frame}'
    print(f"Rendering {comp} @ frame {frame} -> {outname}...")
    res = subprocess.run(cmd, cwd=video_dir, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error rendering {comp}: {res.stderr}")
        raise SystemExit(1)
    im = Image.open(outpath)
    print(f"  OK: size={im.size}, mode={im.mode}")

print("All key stills successfully verified!")
