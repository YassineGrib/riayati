"""Renders all Remotion videos and executes audio mixing and delivery.

Usage:
    python scripts/render_all_videos.py
"""

import os
import subprocess
import time
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "out")
os.makedirs(OUT, exist_ok=True)

VIDEOS = [
    ("Promo", "riayati-promo.mp4", 19),
    ("PromoVertical", "riayati-promo-vertical.mp4", 19),
    ("HowTo", "riayati-howto-vertical.mp4", 20),
    ("Problems", "riayati-problems-vertical.mp4", 20),
    ("Story", "riayati-story.mp4", 20),
    ("StoryVertical", "riayati-story-vertical.mp4", 20),
    ("LogoLight", "riayati-logo-light.mp4", 18),
    ("LogoDark", "riayati-logo-dark.mp4", 18),
]

def render_video(comp: str, outfile: str, crf: int):
    outpath = os.path.join(OUT, outfile)
    cmd = (
        f'npx remotion render src/index.ts {comp} "{outpath}" '
        f'--codec=h264 --crf={crf} --pixel-format=yuv420p --concurrency=4'
    )
    print(f"\n==========================================")
    print(f"Rendering {comp} -> {outfile} (CRF {crf})...")
    print(f"==========================================")
    t0 = time.time()
    res = subprocess.run(cmd, cwd=ROOT, shell=True)
    if res.returncode != 0:
        raise RuntimeError(f"Rendering failed for {comp}")
    elapsed = round(time.time() - t0, 1)
    sz_mb = round(os.path.getsize(outpath) / (1024 * 1024), 2)
    print(f"Finished {outfile} in {elapsed} s ({sz_mb} MB)")
    return outpath

def main():
    print("Step 1: Rendering all silent Remotion videos...")
    for comp, outname, crf in VIDEOS:
        render_video(comp, outname, crf)

    print("\nStep 2: Synthesising ambient music beds...")
    subprocess.run(f'python "{os.path.join(ROOT, "scripts", "music.py")}"', cwd=ROOT, shell=True, check=True)

    print("\nStep 3: Muxing audio onto videos and deploying to deliverables...")
    subprocess.run(f'python "{os.path.join(ROOT, "scripts", "build_audio.py")} all"', cwd=ROOT, shell=True, check=True)

    # Copy logo animations to deliverables/Videos/Logo Animation/
    logo_dir = os.path.join(ROOT, "deliverables", "Videos", "Logo Animation")
    os.makedirs(logo_dir, exist_ok=True)
    shutil.copy2(os.path.join(OUT, "riayati-logo-light.mp4"), os.path.join(logo_dir, "riayati-logo-light.mp4"))
    shutil.copy2(os.path.join(OUT, "riayati-logo-dark.mp4"), os.path.join(logo_dir, "riayati-logo-dark.mp4"))
    print("Logo videos copied to deliverables/Videos/Logo Animation/")

    print("\nAll videos rendered, muxed, and deployed successfully!")

if __name__ == "__main__":
    main()
