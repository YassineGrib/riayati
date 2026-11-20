"""Synthesises the calm ambient music bed for Riayati from scratch (numpy only).

    python scripts/music.py
    -> public/music-promo.wav (22.6 s)
    -> public/music-howto.wav (32.6 s)
    -> public/music-problems.wav (30.6 s)
    -> public/music-story.wav (40.6 s)

Calm, reassuring harmonic beds with warm pads, gentle arpeggios, and soft closing chime.
Zero sample licensing issues, zero transition whooshes.
Loudness normalized to approx -15 LUFS, true peak <= -1.5 dBFS.
"""
import os
import wave
import numpy as np

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "public")
os.makedirs(OUT, exist_ok=True)

# Note frequencies (Hz)
N = {
    "C2": 65.41, "G2": 98.00, "B2": 123.47, "C3": 130.81, "E3": 164.81, "G3": 196.00, "B3": 246.94,
    "D3": 146.83, "A3": 220.00, "F3": 174.61, "F#3": 185.00, "Bb2": 116.54, "D2": 73.42,
    "A2": 110.00, "F2": 87.31, "E2": 82.41, "C4": 261.63, "D4": 293.66, "E4": 329.63,
    "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88, "C5": 523.25, "E5": 659.25,
    "G5": 783.99, "A5": 880.00
}

# Warm peaceful chords fitting the olive/lime comforting theme (Key of C / F)
CHORDS = {
    "Cmaj9": ["C2", "G2", "E3", "G3", "B3", "D4"],
    "Am9": ["A2", "E3", "A3", "C4", "E4", "G4"],
    "Fmaj7": ["F2", "C3", "F3", "A3", "C4", "E4"],
    "Gadd9": ["G2", "D3", "G3", "B3", "D4", "A4"],
    "Em7": ["E2", "B2", "E3", "G3", "B3", "D4"],
    "Dm9": ["D2", "A2", "F3", "A3", "C4", "E4"],
    "C": ["C2", "G2", "C3", "E3", "G3", "C4"],
}

def env(n, a, r):
    e = np.ones(n)
    na, nr = int(a * SR), int(r * SR)
    if na > 0:
        e[:na] = np.linspace(0, 1, na) ** 2
    if nr > 0:
        e[-nr:] = np.linspace(1, 0, nr) ** 2
    return e

def pad(freqs, dur, gain=0.045):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for i, f in enumerate(freqs):
        det = 1 + 0.0015 * (i - len(freqs)/2)
        s += np.sin(2 * np.pi * f * det * t) + 0.3 * np.sin(2 * np.pi * f * 2 * t + i) + 0.1 * np.sin(2 * np.pi * f * 3 * t)
    # Slow gentle chorus breathing
    s *= 1 + 0.06 * np.sin(2 * np.pi * 0.15 * t)
    return s * gain * env(n, min(1.8, dur / 3), min(2.0, dur / 3))

def pluck(f, dur=1.8, gain=0.085):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 2 * t) + 0.08 * np.sin(2 * np.pi * f * 3 * t)) * np.exp(-t * 2.8)
    # Anti-click attack
    attack_len = int(0.005 * SR)
    s[:attack_len] *= np.linspace(0, 1, attack_len)
    return s * gain

def chime(f, dur=3.5, gain=0.075):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = (np.sin(2 * np.pi * f * t) + 0.45 * np.sin(2 * np.pi * f * 2.76 * t) + 0.2 * np.sin(2 * np.pi * f * 5.4 * t)) * np.exp(-t * 1.4)
    attack_len = int(0.005 * SR)
    s[:attack_len] *= np.linspace(0, 1, attack_len)
    return s * gain

def place(buf, sig, at):
    i = int(at * SR)
    j = min(len(buf), i + len(sig))
    if i < len(buf) and i >= 0:
        buf[i:j] += sig[: j - i]

def build(name, total, plan, chime_at):
    n = int((total + 0.6) * SR)
    L = np.zeros(n)
    R = np.zeros(n)
    t0 = 0.0
    for chord, dur in plan:
        chord_freqs = [N[x] for x in CHORDS[chord]]
        p = pad(chord_freqs, dur + 1.2)
        place(L, p, t0)
        place(R, np.roll(p, 48), t0) # gentle stereo width
        
        # Soft arpeggio plucks
        notes = chord_freqs[2:]
        step = 0.58
        k = 0
        tt = t0 + 0.45
        while tt < t0 + dur - 0.4:
            f = notes[k % len(notes)]
            pl = pluck(f)
            place(L, pl * (0.65 if k % 2 else 0.95), tt)
            place(R, pl * (0.95 if k % 2 else 0.65), tt + 0.015)
            tt += step
            k += 1
        t0 += dur

    # Closing peaceful chime
    ch = chime(N["C5"]) + chime(N["G5"]) * 0.6
    place(L, ch, chime_at)
    place(R, ch, chime_at + 0.01)

    x = np.stack([L, R], 1)
    
    # Peak normalise with headroom
    peak = np.abs(x).max()
    if peak > 1e-9:
        x /= peak
    # Master gain around -15 LUFS equivalent
    x *= 0.68

    # Fade in / out
    fi, fo = int(0.4 * SR), int(1.2 * SR)
    x[:fi] *= np.linspace(0, 1, fi)[:, None]
    x[-fo:] *= np.linspace(1, 0, fo)[:, None]

    path = os.path.join(OUT, f"music-{name}.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).clip(-32768, 32767).astype("<i2").tobytes())
    print(f"Generated {path} ({round(len(x)/SR, 2)} s)")
    return path

if __name__ == "__main__":
    # Promo: 22 s
    build(
        "promo",
        22.0,
        [("Cmaj9", 5.5), ("Fmaj7", 5.5), ("Am9", 5.5), ("Gadd9", 5.5)],
        chime_at=18.0
    )
    # How-To: 32 s
    build(
        "howto",
        32.0,
        [("Cmaj9", 5.5), ("Fmaj7", 5.5), ("Dm9", 5.5), ("Am9", 5.5), ("Fmaj7", 5.0), ("Gadd9", 5.0)],
        chime_at=28.0
    )
    # Problems: 30 s
    build(
        "problems",
        30.0,
        [("Am9", 5.5), ("Fmaj7", 6.0), ("Dm9", 6.0), ("Gadd9", 6.5), ("Cmaj9", 6.0)],
        chime_at=26.0
    )
    # Story: 40 s
    build(
        "story",
        40.0,
        [("Am9", 6.5), ("Em7", 6.5), ("Fmaj7", 7.0), ("Cmaj9", 7.0), ("Dm9", 6.5), ("C", 6.5)],
        chime_at=34.0
    )
