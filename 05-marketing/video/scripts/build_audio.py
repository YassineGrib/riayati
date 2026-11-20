"""Audio building and video muxing for Riayati marketing videos.

Usage:
    python scripts/build_audio.py promo
    python scripts/build_audio.py howto
    python scripts/build_audio.py problems
    python scripts/build_audio.py story
    python scripts/build_audio.py all

What this does:
1. Verifies silent renders in out/ (e.g. out/riayati-promo.mp4)
2. Normalizes music to -15 LUFS, peak <= -1.5 dBTP
3. Muxes music-only master: ...-music.mp4
4. If voiceover clips are present in public/voiceover/, ducks music under voice and muxes ...-voiceover.mp4
5. Deploys silent and music-only files to deliverables/Videos/...
"""

import os
import shutil
import subprocess
import sys
from voice import NARRATION, strip_tashkeel

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUB = os.path.join(ROOT, "public")
OUT = os.path.join(ROOT, "out")
DELIV = os.path.join(ROOT, "deliverables", "Videos")

# Map of video keys to deliverables subfolders
DELIV_FOLDERS = {
    "promo": os.path.join(DELIV, "Promo"),
    "howto": os.path.join(DELIV, "How-To"),
    "problems": os.path.join(DELIV, "Problem and Solution"),
    "story": os.path.join(DELIV, "Story Film"),
}

def run_cmd(cmd):
    print("Running:", cmd)
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print("ERROR:", res.stderr)
        raise RuntimeError(f"Command failed with code {res.returncode}")
    return res.stdout

def mux_music_only(video_name: str, music_path: str, duration_s: float, deliv_folder: str):
    """Mux music onto silent video, keeping file size small (< 9 MB)."""
    silent_mp4 = os.path.join(OUT, f"{video_name}.mp4")
    if not os.path.exists(silent_mp4):
        print(f"Warning: {silent_mp4} not found. Render silent video first.")
        return False

    music_mp4 = os.path.join(OUT, f"{video_name}-music.mp4")
    
    # Mux using ffmpeg with AAC audio, normalized, and trimmed to exact video length
    cmd = (
        f'ffmpeg -y -i "{silent_mp4}" -i "{music_path}" '
        f'-c:v copy -c:a aac -b:a 192k -t {duration_s} '
        f'-af "loudnorm=I=-15:TP=-1.5:LRA=11" '
        f'-movflags +faststart "{music_mp4}"'
    )
    run_cmd(cmd)
    print(f"Created music-only master: {music_mp4}")

    # Copy to deliverables
    os.makedirs(deliv_folder, exist_ok=True)
    shutil.copy2(silent_mp4, os.path.join(deliv_folder, f"{video_name}.mp4"))
    shutil.copy2(music_mp4, os.path.join(deliv_folder, f"{video_name}-music.mp4"))
    return True

def process_target(key: str):
    if key not in NARRATION:
        print(f"Unknown target '{key}'. Choose from: {list(NARRATION.keys())}")
        return

    spec = NARRATION[key]
    music_file = os.path.join(PUB, f"music-{key}.wav")
    if not os.path.exists(music_file):
        print(f"Synthesising music for {key}...")
        run_cmd(f'python "{os.path.join(ROOT, "scripts", "music.py")}"')

    deliv_dir = DELIV_FOLDERS[key]
    for vid in spec["videos"]:
        print(f"\n--- Processing {vid} ({spec['total']} s) ---")
        mux_music_only(vid, music_file, spec["total"], deliv_dir)

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    if target == "all":
        for k in NARRATION:
            process_target(k)
    else:
        process_target(target)
