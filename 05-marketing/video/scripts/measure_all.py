"""Measures duration, loudness, true peak, and file size for all deliverables.
Outputs a markdown table suitable for docs/Video-Promo-Guide.md.
"""

import json
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DELIV = os.path.join(ROOT, "deliverables", "Videos")

FILES = [
    ("Promo", "riayati-promo-16x9-silent.mp4"),
    ("Promo", "riayati-promo-16x9-music.mp4"),
    ("Promo", "riayati-promo-9x16-silent.mp4"),
    ("Promo", "riayati-promo-9x16-music.mp4"),
    ("How-To", "riayati-howto-9x16-silent.mp4"),
    ("How-To", "riayati-howto-9x16-music.mp4"),
    ("Problem and Solution", "riayati-problems-9x16-silent.mp4"),
    ("Problem and Solution", "riayati-problems-9x16-music.mp4"),
    ("Story Film", "riayati-story-16x9-silent.mp4"),
    ("Story Film", "riayati-story-16x9-music.mp4"),
    ("Story Film", "riayati-story-9x16-silent.mp4"),
    ("Story Film", "riayati-story-9x16-music.mp4"),
    ("Logo Animation", "riayati-logo-light.mp4"),
    ("Logo Animation", "riayati-logo-dark.mp4"),
]

def get_ffprobe_info(path):
    cmd = (
        f'ffprobe -v quiet -print_format json -show_format -show_streams "{path}"'
    )
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        return None
    return json.loads(res.stdout)

def get_ebur128(path):
    cmd = f'ffmpeg -i "{path}" -af ebur128=framelog=verbose -f null - 2>&1'
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    out = res.stdout + res.stderr
    lufs = "—"
    tp = "—"
    for line in out.splitlines():
        if "    I:" in line and "LUFS" in line:
            lufs = line.split("I:")[1].split("LUFS")[0].strip() + " LUFS"
        elif "Peak:" in line and "dBFS" in line:
            tp = line.split("Peak:")[1].split("dBFS")[0].strip() + " dBTP"
    return lufs, tp

def main():
    rows = []
    print("Measuring all deliverable videos...")
    for folder, fname in FILES:
        p = os.path.join(DELIV, folder, fname)
        if not os.path.exists(p):
            print(f"Pending: {fname}")
            continue
        info = get_ffprobe_info(p)
        dur = round(float(info["format"]["duration"]), 2)
        sz_mb = round(os.path.getsize(p) / (1024 * 1024), 2)
        v_stream = next((s for s in info["streams"] if s["codec_type"] == "video"), None)
        a_stream = next((s for s in info["streams"] if s["codec_type"] == "audio"), None)
        res = f"{v_stream['width']}x{v_stream['height']}" if v_stream else "—"

        if a_stream:
            lufs, tp = get_ebur128(p)
        else:
            lufs, tp = "Silent", "Silent"

        rows.append({
            "folder": folder,
            "file": fname,
            "res": res,
            "dur": f"{dur}s",
            "size": f"{sz_mb} MB",
            "lufs": lufs,
            "tp": tp,
        })

    print("\n| Folder | File | Resolution | Duration | File Size | Loudness | True Peak |")
    print("|---|---|---|---|---|---|---|")
    for r in rows:
        print(f"| `{r['folder']}` | `{r['file']}` | {r['res']} | {r['dur']} | {r['size']} | {r['lufs']} | {r['tp']} |")

if __name__ == "__main__":
    main()
