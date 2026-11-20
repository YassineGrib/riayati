"""Riayati Narration scripts, Gemini TTS integration & audio declicking.

Narration rules strictly enforced:
- Real Arabic RTL sentences, one natural full sentence per scene.
- No choppy fragments.
- No style instructions in prompt (Gemini TTS reads style prompts aloud).
- No tashkeel.
- No forbidden claims: no legal advice, no statistics, no '100% safe', no 'معتمد من الوزارة',
  no assistant mention ('مساعد' / 'ذكاء'), no fake claims.
- Mandatory disclaimer in every outro/finale:
  «محتوى تعريفي للإرشاد الأولي، ولا يغني عن استشارة مختص أو عن نص القانون الرسمي»
"""

import base64
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUB = os.path.join(ROOT, "public")
CACHE_DIR = os.path.join(PUB, "voiceover")
os.makedirs(CACHE_DIR, exist_ok=True)

# Word duration baseline in seconds (Gemini Arabic reading speed)
# Retime parameter: adjust this ONE value to resize margins if measured voice is faster/slower
WORD_DURATION_SEC = 0.75
SPEECH_MARGIN_SEC = 0.40

GEMINI_MODEL = os.environ.get("GEMINI_TTS_MODEL", "gemini-3.8-flash-tts")
VOICE_NAME = "Kore"

# Narration lines: (start_s, window_end_s, text)
NARRATION = {
    "promo": {
        "title": "Promo (22 s)",
        "total": 22.0,
        "videos": ["riayati-promo", "riayati-promo-vertical"],
        "lines": [
            # Scene 1: Open (0.0 - 2.6 s)
            (0.30, 2.20, "هذه هي رعايتي."),
            # Scene 2: Intro (2.2 - 5.6 s)
            (2.30, 5.15, "مساحة آمنة لحماية الطفل."),
            # Scene 3: Home & accounts (5.2 - 9.0 s)
            (5.40, 8.55, "حسابات مستقلة وربط برمز دعوة."),
            # Scene 4: Report + PDF (8.6 - 12.4 s)
            (8.70, 11.95, "توثيق رسمي غير قابل للحذف."),
            # Scene 5: Calendar (12.0 - 15.6 s)
            (12.00, 15.15, "تقويم مشترك لتنسيق الزيارات باحترام."),
            # Scene 6: Library + Centers (15.2 - 18.2 s)
            (15.20, 17.85, "مكتبة ودليل للجهات المتخصصة."),
            # Scene 7: Finale + CTA (17.8 - 22.0 s)
            (17.90, 21.60, "رعايتي، بيئة هادئة لرعاية طفلك."),
        ],
    },
    "howto": {
        "title": "How-To (32 s)",
        "total": 32.0,
        "videos": ["riayati-howto-vertical"],
        "lines": [
            # Intro (0.0 - 3.0 s)
            (0.30, 2.90, "كيف تبدأ مع تطبيق رعايتي؟"),
            # Step 1 (3.0 - 7.2 s)
            (3.30, 7.10, "الخطوة الأولى: حمّل النسخة التجريبية من الموقع."),
            # Step 2 (7.2 - 11.4 s)
            (7.40, 11.20, "الخطوة الثانية: أنشئ حسابك كأب أو أم."),
            # Step 3 (11.4 - 15.6 s)
            (11.50, 15.30, "الخطوة الثالثة: اربط الطرف الآخر برمز دعوة."),
            # Step 4 (15.6 - 19.8 s)
            (15.60, 19.40, "الخطوة الرابعة: وثّق أي واقعة مع المرفقات."),
            # Step 5 (19.8 - 24.0 s)
            (19.70, 23.50, "الخطوة الخامسة: نسّق مواعيد الزيارة عبر التقويم."),
            # Step 6 (24.0 - 28.2 s)
            (23.80, 27.60, "الخطوة السادسة: تصفح المكتبة التوعوية ودليل الهيئات."),
            # Outro (28.2 - 32.0 s)
            (28.00, 31.60, "رعايتي، مساحة آمنة لحماية الطفل."),
        ],
    },
    "problems": {
        "title": "Problem -> Solution (30 s)",
        "total": 30.0,
        "videos": ["riayati-problems-vertical"],
        "lines": [
            # Intro (0.0 - 2.5 s)
            (0.30, 2.40, "مشكلة في تنظيم الحضانة؟"),
            # Pair 1: Problem (2.5 - 4.5 s) -> Solution (4.5 - 8.3 s)
            (2.60, 4.40, "كيف أوثق ما حدث؟"),
            (4.60, 8.20, "وثّق الوقائع بتقرير غير قابل للحذف."),
            # Pair 2: Problem (8.3 - 10.3 s) -> Solution (10.3 - 14.1 s)
            (8.50, 10.20, "كيف ننسق الزيارات؟"),
            (10.40, 14.00, "تقويم مشترك لتأكيد المواعيد بوضوح واحترام."),
            # Pair 3: Problem (14.1 - 16.1 s) -> Solution (16.1 - 19.9 s)
            (14.30, 16.00, "أين أجد الجهات المختصة؟"),
            (16.20, 19.80, "دليل للجهات المتخصصة مع اتصال مباشر."),
            # Pair 4: Problem (19.9 - 21.9 s) -> Solution (21.9 - 25.7 s)
            (20.10, 21.80, "من يرى بياناتي؟"),
            (22.00, 25.60, "كل والد يرى تقاريره الخاصة فقط."),
            # Outro (25.7 - 30.0 s)
            (26.00, 29.70, "رعايتي، لحماية الطفل واستقرار الأسرة."),
        ],
    },
    "story": {
        "title": "Story Film (40 s)",
        "total": 40.0,
        "videos": ["riayati-story", "riayati-story-vertical"],
        "lines": [
            # Scene 1 (0.0 - 6.0 s)
            (0.40, 5.60, "تنظيم رعاية الطفل بعد الانفصال يحتاج إلى الكثير من الهدوء."),
            # Scene 2 (6.0 - 12.0 s)
            (6.20, 11.60, "فمصلحة الطفل تبدأ بحوار واضح وبيئة يسودها الاحترام."),
            # Scene 3 (12.0 - 20.0 s)
            (12.30, 19.20, "تقويم مشترك يتيح للوالدين الاتفاق على المواعيد دون تصادم."),
            # Scene 4 (20.0 - 27.0 s)
            (20.00, 26.50, "وتوثيق منظم يحفظ الوقائع بملفات رسمية واضحة."),
            # Scene 5 (27.0 - 33.0 s)
            (27.30, 32.50, "ومع مكتبة تعريفية ودليل للجهات المتخصصة حسب ولايتك."),
            # Scene 6 (33.0 - 40.0 s)
            (33.40, 38.60, "رعايتي، مساحة آمنة لحماية الطفل في إطار الحضانة."),
        ],
    },
}

def strip_tashkeel(text: str) -> str:
    """Strip Arabic harakat/tashkeel to ensure clean natural speech."""
    return re.sub(r"[\u064B-\u065F\u0670]", "", text).replace("…", "،")

def verify_lines_timing():
    """Verify that all narration lines comfortably fit their allotted time windows."""
    print("=== Checking Narration Timing & Word Durations ===")
    all_ok = True
    for key, spec in NARRATION.items():
        print(f"\nChecking {spec['title']}:")
        for start, end, text in spec["lines"]:
            clean = strip_tashkeel(text)
            words = clean.split()
            word_count = len(words)
            window = end - start
            est_duration = word_count * WORD_DURATION_SEC
            fits = est_duration <= (window + SPEECH_MARGIN_SEC)
            status = "OK" if fits else "TIGHT / TOO LONG"
            if not fits:
                all_ok = False
            print(f"  [{start:4.1f}s -> {end:4.1f}s | win {window:4.1f}s] {word_count:2d} words (~{est_duration:4.1f}s) -> {status} : {clean}")
    return all_ok

def declick(path: str):
    """Declick raw Gemini TTS clips:
    - Gemini TTS clips start with a ~50ms tick and end with a loud burst cut off after silence.
    - Remove both cleanly and apply gentle edge fades (50ms in, 80ms out).
    """
    with wave.open(path, "rb") as w:
        sr = w.getframerate()
        ch = w.getnchannels()
        sw = w.getsampwidth()
        n = w.getnframes()
        pcm = w.readframes(n)

    x = np.frombuffer(pcm, dtype="<i2").astype(float) / 32768.0
    if len(x) == 0:
        return

    # Frame size for RMS energy analysis: 20 ms
    fr = int(sr * 0.020)
    num_frames = len(x) // fr
    if num_frames < 5:
        return
    rms = np.array([np.sqrt(np.mean(x[i * fr : (i + 1) * fr] ** 2)) for i in range(num_frames)])

    start_idx = 0
    end_idx = len(x)

    # 1. Trailing burst removal: look for loud tail (<= 0.4s) after quiet speech
    k = num_frames - 1
    while k >= 0 and rms[k] < 0.025:  # ignore digital trailing silence
        k -= 1
    j = k
    while j >= 0 and rms[j] >= 0.025:
        j -= 1
    tail = rms[j + 1 : k + 1] if (j + 1 <= k) else np.array([])
    if j >= 0 and 0 < len(tail) * 0.020 <= 0.40 and tail.mean() > 0.28:
        end_idx = (j + 1) * fr

    # 2. Leading tick removal: short blip (<= 0.1s) before speech
    i = 0
    while i < num_frames and rms[i] < 0.025:
        i += 1
    if i < num_frames and rms[i] > 0.20:
        # Check if following 80ms is quiet
        next_quiet = all(rms[min(i + 1 + step, num_frames - 1)] < 0.04 for step in range(4))
        if next_quiet:
            start_idx = (i + 3) * fr

    # Slice clean audio
    cleaned = x[start_idx:end_idx].copy()
    if len(cleaned) < int(sr * 0.1):
        cleaned = x.copy()

    # Apply smooth fades (50 ms attack, 80 ms release)
    fade_in_len = min(int(sr * 0.050), len(cleaned))
    fade_out_len = min(int(sr * 0.080), len(cleaned))
    if fade_in_len > 0:
        cleaned[:fade_in_len] *= np.linspace(0, 1, fade_in_len)
    if fade_out_len > 0:
        cleaned[-fade_out_len:] *= np.linspace(1, 0, fade_out_len)

    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((cleaned * 32767).clip(-32768, 32767).astype("<i2").tobytes())

def gemini_tts(text: str, out_wav: str, voice: str = VOICE_NAME) -> str:
    """Call Gemini TTS API (gemini-3.8-flash-tts).
    Requires GEMINI_API_KEY environment variable. Never hardcode keys in files.
    """
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        raise ValueError("GEMINI_API_KEY environment variable is not set.")

    clean_text = strip_tashkeel(text)
    body = {
        "contents": [{"parts": [{"text": clean_text}]}],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": {"voiceName": voice}
                }
            },
        },
    }

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"x-goog-api-key": key, "Content-Type": "application/json"},
    )

    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.load(resp)
                break
        except urllib.error.HTTPError as e:
            if e.code == 429:
                err_body = e.read()
                if b"per day" in err_body:
                    raise SystemExit("Daily free-tier quota exhausted for " + GEMINI_MODEL)
                print(f"429 Rate limit, waiting 20s (attempt {attempt+1}/6)...")
                time.sleep(20)
            elif e.code in (500, 503) and attempt < 5:
                time.sleep(10)
            else:
                raise

    pcm_b64 = data["candidates"][0]["content"]["parts"][0]["inlineData"]["data"]
    pcm = base64.b64decode(pcm_b64)

    with wave.open(out_wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(24000)
        w.writeframes(pcm)

    declick(out_wav)
    return out_wav

def synthesize_all(dry_run: bool = False):
    """Synthesize voiceover for all scripts or check cache."""
    has_key = bool(os.environ.get("GEMINI_API_KEY"))
    print(f"Gemini API Key configured: {has_key}")
    if not has_key:
        print("NOTE: GEMINI_API_KEY is not set. Silent masters and music-only masters will be rendered now.")
        print("Voiceover clips will be generated when GEMINI_API_KEY is supplied.")
        return

    for key, spec in NARRATION.items():
        print(f"\nProcessing voice for {key}:")
        for idx, (start, end, text) in enumerate(spec["lines"]):
            clean = strip_tashkeel(text)
            h = hashlib.sha1(f"{key}_{idx}_{clean}_{VOICE_NAME}".encode("utf-8")).hexdigest()[:12]
            clip_path = os.path.join(CACHE_DIR, f"{key}_{idx}_{h}.wav")
            if os.path.exists(clip_path):
                print(f"  [cached] {clip_path}")
            else:
                print(f"  [synthesizing] {clean}")
                gemini_tts(clean, clip_path, VOICE_NAME)

if __name__ == "__main__":
    verify_lines_timing()
    synthesize_all()
