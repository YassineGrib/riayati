"""Builds the voiceover versions: clips from public/voiceover (see voice.py) + the music bed.

Usage: python scripts/mix_voice.py [promo|howto|problems|story|all]

Rules (from the kit): music ducked under the voice (attack ~80 ms, release ~700 ms), about -15 LUFS,
true peak <= -1.5 dBTP. A clip is sped up only as much as needed (max x1.3) to fit its scene; it may
start up to 0.25 s before its scene so a long sentence does not crash into the next one.
Prints a timing report. Never reads or writes any API key.
"""
import hashlib
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from voice import CACHE_DIR, NARRATION, VOICE_NAME, strip_tashkeel  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUB = os.path.join(ROOT, "public")
DELIV = os.path.join(ROOT, "deliverables", "Videos")
SR = 24000
MAX_TEMPO = 1.3
LEAD = 0.25
GAP = 0.08

FOLDER = {"promo": "Promo", "howto": "How-To", "problems": "Problem and Solution", "story": "Story Film"}
# silent master name in the deliverables folder, per narration key
SILENT = {
    "promo": ["riayati-promo-16x9-silent.mp4", "riayati-promo-9x16-silent.mp4"],
    "howto": ["riayati-howto-9x16-silent.mp4"],
    "problems": ["riayati-problems-9x16-silent.mp4"],
    "story": ["riayati-story-16x9-silent.mp4", "riayati-story-9x16-silent.mp4"],
}


def clip_path(key, idx, text):
    clean = strip_tashkeel(text)
    h = hashlib.sha1(f"{key}_{idx}_{clean}_{VOICE_NAME}".encode("utf-8")).hexdigest()[:12]
    return os.path.join(CACHE_DIR, f"{key}_{idx}_{h}.wav")


def read_wav(path):
    with wave.open(path, "rb") as w:
        x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float32) / 32768.0
        return x, w.getframerate()


def stretch(path, tempo, out):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-filter:a", f"atempo={tempo:.4f}", "-ar", str(SR), "-ac", "1", out], check=True)
    return read_wav(out)[0]


def build_voice(key, total):
    spec = NARRATION[key]
    lines = spec["lines"]
    voice = np.zeros(int(total * SR), dtype=np.float32)
    cursor = 0.0
    report = []
    tmpdir = tempfile.mkdtemp()
    for i, (start, end, text) in enumerate(lines):
        p = clip_path(key, i, text)
        x, sr = read_wav(p)
        d = len(x) / sr
        begin = max(start - LEAD, cursor + GAP)
        next_start = lines[i + 1][0] if i + 1 < len(lines) else total - 0.2
        target_end = next_start - 0.05
        tempo = min(MAX_TEMPO, max(1.0, d / max(0.5, target_end - begin)))
        y = x if tempo <= 1.001 else stretch(p, tempo, os.path.join(tmpdir, f"{i}.wav"))
        b = int(begin * SR)
        voice[b : b + len(y)] += y[: max(0, len(voice) - b)]
        cursor = begin + len(y) / SR
        late = cursor - end
        report.append((i, start, begin, cursor, tempo, late))
    out = os.path.join(PUB, f"voice-{key}.wav")
    with wave.open(out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(voice, -1, 1) * 32767).astype("<i2").tobytes())
    return out, report


def mix(key, silent_name, voice_wav, total):
    folder = os.path.join(DELIV, FOLDER[key])
    video = os.path.join(folder, silent_name)
    out = os.path.join(folder, silent_name.replace("-silent.mp4", "-voice.mp4"))
    music = os.path.join(PUB, f"music-{key}.wav")
    fc = (
        "[1:a]aresample=48000,volume=0.55[m];[2:a]aresample=48000,asplit=2[v][vs];"
        "[m][vs]sidechaincompress=threshold=0.03:ratio=8:attack=80:release=700[md];"
        "[md][v]amix=inputs=2:duration=first:normalize=0,apad=whole_dur=" + str(total) + ",loudnorm=I=-15:TP=-1.5:LRA=11[a]"
    )
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", video, "-i", music, "-i", voice_wav, "-filter_complex", fc,
           "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", str(total), "-movflags", "+faststart", out]
    subprocess.run(cmd, check=True)
    return out


def main(target):
    keys = list(NARRATION) if target == "all" else [target]
    for key in keys:
        total = NARRATION[key]["total"]
        voice_wav, report = build_voice(key, total)
        print(f"\n== {key}: voice track {voice_wav}")
        for i, start, begin, end, tempo, late in report:
            print(f"  line {i}: scene {start:5.2f}s begins {begin:5.2f}s ends {end:5.2f}s tempo x{tempo:.2f} past-window {late:+.2f}s")
        for silent in SILENT[key]:
            print("  ->", mix(key, silent, voice_wav, total))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "all")
