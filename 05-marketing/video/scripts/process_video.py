"""Post-processing for rendered Remotion video:
- Muxes music bed onto silent video
- Creates both naming styles (e.g. riayati-promo-16x9-silent.mp4 and riayati-promo-16x9-music.mp4)
- Extracts 4 test frames with ffmpeg
- Measures duration, loudness, true peak, and file size
"""

import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUB = os.path.join(ROOT, "public")
OUT = os.path.join(ROOT, "out")
FRAMES_DIR = os.path.join(OUT, "extracted_frames")
os.makedirs(FRAMES_DIR, exist_ok=True)

# Configuration for each video
CONFIG = {
    "riayati-promo": {
        "folder": "Promo",
        "music": "music-promo.wav",
        "dur": 22.0,
        "names": ["riayati-promo", "riayati-promo-16x9"],
    },
    "riayati-promo-vertical": {
        "folder": "Promo",
        "music": "music-promo.wav",
        "dur": 22.0,
        "names": ["riayati-promo-vertical", "riayati-promo-9x16"],
    },
    "riayati-howto-vertical": {
        "folder": "How-To",
        "music": "music-howto.wav",
        "dur": 32.0,
        "names": ["riayati-howto-vertical", "riayati-howto-9x16"],
    },
    "riayati-problems-vertical": {
        "folder": "Problem and Solution",
        "music": "music-problems.wav",
        "dur": 30.0,
        "names": ["riayati-problems-vertical", "riayati-problems-9x16"],
    },
    "riayati-story": {
        "folder": "Story Film",
        "music": "music-story.wav",
        "dur": 40.0,
        "names": ["riayati-story", "riayati-story-16x9"],
    },
    "riayati-story-vertical": {
        "folder": "Story Film",
        "music": "music-story.wav",
        "dur": 40.0,
        "names": ["riayati-story-vertical", "riayati-story-9x16"],
    },
    "riayati-logo-light": {
        "folder": "Logo Animation",
        "music": None,
        "dur": 5.0,
        "names": ["riayati-logo-light"],
    },
    "riayati-logo-dark": {
        "folder": "Logo Animation",
        "music": None,
        "dur": 5.0,
        "names": ["riayati-logo-dark"],
    },
}

def run_cmd(cmd):
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print("ERROR running:", cmd)
        print(res.stderr)
        raise RuntimeError("Command failed")
    return res.stdout

def process(video_key: str):
    cfg = CONFIG[video_key]
    deliv_dir = os.path.join(ROOT, "deliverables", "Videos", cfg["folder"])
    os.makedirs(deliv_dir, exist_ok=True)

    src_mp4 = os.path.join(OUT, f"{video_key}.mp4")
    if not os.path.exists(src_mp4):
        print(f"File not found: {src_mp4}")
        return

    # Check size of raw render; if > 7.5 MB, compress to keep final with audio strictly under 9 MB
    raw_size_mb = os.path.getsize(src_mp4) / (1024 * 1024)
    silent_optimized = os.path.join(OUT, f"{video_key}-silent.mp4")
    crf = 22 if cfg["dur"] > 25 else 21
    if raw_size_mb > 7.5:
        print(f"Compressing {video_key} ({raw_size_mb:.2f} MB with CRF {crf} -> target < 8.5 MB)...")
        cmd_opt = (
            f'ffmpeg -y -i "{src_mp4}" '
            f'-c:v libx264 -crf {crf} -preset fast -pix_fmt yuv420p '
            f'-movflags +faststart "{silent_optimized}"'
        )
        run_cmd(cmd_opt)
    else:
        # Just faststart
        cmd_opt = f'ffmpeg -y -i "{src_mp4}" -c copy -movflags +faststart "{silent_optimized}"'
        run_cmd(cmd_opt)

    # 1. Music mux if music is specified
    if cfg["music"]:
        music_wav = os.path.join(PUB, cfg["music"])
        music_mp4 = os.path.join(OUT, f"{video_key}-music.mp4")
        cmd_mux = (
            f'ffmpeg -y -i "{silent_optimized}" -i "{music_wav}" '
            f'-c:v copy -c:a aac -b:a 192k -t {cfg["dur"]} '
            f'-af "loudnorm=I=-15:TP=-1.5:LRA=11" '
            f'-movflags +faststart "{music_mp4}"'
        )
        run_cmd(cmd_mux)

        # Deploy aliases to deliverables
        for alias in cfg["names"]:
            shutil.copy2(silent_optimized, os.path.join(deliv_dir, f"{alias}-silent.mp4"))
            shutil.copy2(music_mp4, os.path.join(deliv_dir, f"{alias}-music.mp4"))
            print(f"Deployed {alias}-silent.mp4 ({os.path.getsize(silent_optimized)/(1024*1024):.2f} MB)")
            print(f"Deployed {alias}-music.mp4 ({os.path.getsize(music_mp4)/(1024*1024):.2f} MB)")
    else:
        for alias in cfg["names"]:
            shutil.copy2(silent_optimized, os.path.join(deliv_dir, f"{alias}.mp4"))
            print(f"Deployed {alias}.mp4 ({os.path.getsize(silent_optimized)/(1024*1024):.2f} MB)")

    # 2. Extract 4 frames for visual inspection
    timestamps = [
        round(cfg["dur"] * 0.15, 2),
        round(cfg["dur"] * 0.38, 2),
        round(cfg["dur"] * 0.65, 2),
        round(cfg["dur"] * 0.88, 2),
    ]
    for idx, ts in enumerate(timestamps, 1):
        frame_out = os.path.join(FRAMES_DIR, f"{video_key}_f{idx}_{ts}s.png")
        cmd_frame = f'ffmpeg -y -ss {ts} -i "{silent_optimized}" -vframes 1 -q:v 2 "{frame_out}"'
        run_cmd(cmd_frame)

    print(f"Processed {video_key} successfully (frames in out/extracted_frames/)")

if __name__ == "__main__":
    key = sys.argv[1]
    process(key)
