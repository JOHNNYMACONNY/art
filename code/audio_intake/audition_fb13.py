#!/usr/bin/env python3
"""
FB-13 Local Audition & Acoustic Analysis Tool.
Non-destructive loudness-matching, windowed acoustic band analysis, boundary pop audit, and afplay runner.
"""

import argparse
import math
import os
from pathlib import Path
import struct
import subprocess
import time
import wave
from typing import Any, Dict, List, Tuple

RAW_DIR = Path("audio_staging/fb13_candidates/raw")
AUDITION_DIR = Path("audio_staging/fb13_candidates/audition_normalized")

CANDIDATES = [
    {
        "id": "A",
        "label": "Candidate A (GENRL Bank 7 Sound 0)",
        "pak": "GENRL",
        "bank_id": 7,
        "sound_index": 0,
        "raw_file": RAW_DIR / "candidate_a_genrl_b7_s0.wav",
        "norm_file": AUDITION_DIR / "audition_A_genrl_b7_s0_norm.wav"
    },
    {
        "id": "B",
        "label": "Candidate B (GENRL Bank 122 Sound 0)",
        "pak": "GENRL",
        "bank_id": 122,
        "sound_index": 0,
        "raw_file": RAW_DIR / "candidate_b_genrl_b122_s0.wav",
        "norm_file": AUDITION_DIR / "audition_B_genrl_b122_s0_norm.wav"
    },
    {
        "id": "C",
        "label": "Candidate C (GENRL Bank 76 Sound 1)",
        "pak": "GENRL",
        "bank_id": 76,
        "sound_index": 1,
        "raw_file": RAW_DIR / "candidate_c_genrl_b76_s1.wav",
        "norm_file": AUDITION_DIR / "audition_C_genrl_b76_s1_norm.wav"
    },
    {
        "id": "D",
        "label": "Candidate D (SCRIPT Bank 260 Sound 0)",
        "pak": "SCRIPT",
        "bank_id": 260,
        "sound_index": 0,
        "raw_file": RAW_DIR / "candidate_d_script_b260_s0.wav",
        "norm_file": AUDITION_DIR / "audition_D_script_b260_s0_norm.wav"
    }
]


def load_wav_samples(path: Path) -> Tuple[List[float], int]:
    with wave.open(str(path), "rb") as wf:
        n = wf.getnframes()
        sr = wf.getframerate()
        raw = wf.readframes(n)
        samples_int = struct.unpack(f"<{n}h", raw)
        samples_float = [s / 32768.0 for s in samples_int]
        return samples_float, sr


def write_wav_samples(path: Path, samples: List[float], sr: int):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        raw = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            raw.extend(struct.pack("<h", val))
        wf.writeframes(raw)


def prepare_audition_normalized(target_rms_db: float = -16.0):
    """
    Creates non-destructive loudness-matched audition copies.
    Normalizes RMS energy to target_rms_db while applying gentle 2ms boundary taper.
    """
    AUDITION_DIR.mkdir(parents=True, exist_ok=True)
    for c in CANDIDATES:
        samples, sr = load_wav_samples(c["raw_file"])
        if not samples:
            continue
        
        # Calculate current RMS
        rms = math.sqrt(sum(s * s for s in samples) / len(samples))
        current_rms_db = 20 * math.log10(rms) if rms > 0 else -99
        gain_db = target_rms_db - current_rms_db
        gain = 10 ** (gain_db / 20.0)

        # Scale and apply boundary fade-in/fade-out (2ms)
        fade_samples = max(1, int(sr * 0.002))
        scaled = []
        for i, s in enumerate(samples):
            v = s * gain
            if i < fade_samples:
                v *= (i / fade_samples)
            elif i >= len(samples) - fade_samples:
                v *= ((len(samples) - 1 - i) / fade_samples)
            scaled.append(v)

        # Peak limiter to avoid clipping
        peak = max(abs(v) for v in scaled)
        if peak > 0.95:
            limiter_gain = 0.95 / peak
            scaled = [v * limiter_gain for v in scaled]

        write_wav_samples(c["norm_file"], scaled, sr)


def compute_spectral_distribution(samples: List[float], sr: int) -> Dict[str, float]:
    """
    Computes spectral energy distribution in standard acoustic bands:
    - Sub-bass: 20 - 150 Hz
    - Low-mid / body: 150 - 600 Hz
    - Mid-range / clarity: 600 - 2500 Hz
    - Presence / air: 2500 - 8000 Hz
    """
    # Use windowed DFT chunk analysis
    n = len(samples)
    window = [0.5 * (1 - math.cos(2 * math.pi * i / (n - 1))) for i in range(n)]
    windowed = [samples[i] * window[i] for i in range(n)]

    # Compute energy in frequency bins
    bin_count = min(1024, n // 2)
    energies = [0.0] * bin_count
    
    # Analyze discrete frequency bands
    for k in range(1, bin_count):
        freq = (k * sr) / (2.0 * bin_count)
        # Approximate DFT bin magnitude
        real = sum(windowed[i] * math.cos(2 * math.pi * k * i / n) for i in range(0, n, max(1, n // 512)))
        imag = sum(windowed[i] * math.sin(2 * math.pi * k * i / n) for i in range(0, n, max(1, n // 512)))
        mag = math.sqrt(real * real + imag * imag)
        energies[k] = mag

    total_e = sum(energies) or 1.0

    sub_bass = sum(energies[k] for k in range(1, bin_count) if 20 <= (k * sr)/(2.0 * bin_count) < 150)
    low_mid = sum(energies[k] for k in range(1, bin_count) if 150 <= (k * sr)/(2.0 * bin_count) < 600)
    mid_range = sum(energies[k] for k in range(1, bin_count) if 600 <= (k * sr)/(2.0 * bin_count) < 2500)
    presence = sum(energies[k] for k in range(1, bin_count) if 2500 <= (k * sr)/(2.0 * bin_count) <= 8000)

    # Find dominant peak frequency
    max_bin = max(range(1, bin_count), key=lambda k: energies[k])
    peak_freq = (max_bin * sr) / (2.0 * bin_count)

    return {
        "peak_freq_hz": round(peak_freq, 1),
        "sub_bass_pct": round((sub_bass / total_e) * 100.0, 1),
        "low_mid_pct": round((low_mid / total_e) * 100.0, 1),
        "mid_range_pct": round((mid_range / total_e) * 100.0, 1),
        "presence_pct": round((presence / total_e) * 100.0, 1)
    }


def audit_integrity(path: Path) -> Dict[str, Any]:
    samples, sr = load_wav_samples(path)
    dur = len(samples) / sr
    dc_offset = sum(samples) / len(samples)
    start_click = abs(samples[0])
    end_click = abs(samples[-1])
    peak = max(abs(s) for s in samples)
    peak_db = 20 * math.log10(peak) if peak > 0 else -99
    rms = math.sqrt(sum(s * s for s in samples) / len(samples))
    rms_db = 20 * math.log10(rms) if rms > 0 else -99

    spec = compute_spectral_distribution(samples, sr)

    return {
        "duration_sec": round(dur, 4),
        "sample_rate": sr,
        "peak_db": round(peak_db, 2),
        "rms_db": round(rms_db, 2),
        "dc_offset": round(dc_offset, 5),
        "start_boundary_val": round(start_click, 4),
        "end_boundary_val": round(end_click, 4),
        "spectral": spec
    }


def play_audio(wav_path: Path):
    if not wav_path.exists():
        print(f"File missing: {wav_path}")
        return
    subprocess.run(["afplay", str(wav_path)], check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FB-13 Audition Tool")
    parser.add_argument("--play", choices=["A", "B", "C", "D", "all"], help="Play specified candidate")
    parser.add_argument("--fatigue", choices=["A", "B", "C", "D"], help="Run rapid-fire repetition test on candidate")
    parser.add_argument("--report", action="store_true", help="Print acoustic inspection report")
    args = parser.parse_args()

    # Move previous extractions into RAW_DIR if needed
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    for c in CANDIDATES:
        legacy = Path("audio_staging/fb13_candidates") / c["raw_file"].name
        if legacy.exists() and not c["raw_file"].exists():
            legacy.rename(c["raw_file"])

    prepare_audition_normalized()

    if args.report or not (args.play or args.fatigue):
        print("=" * 70)
        print("FB-13 CANDIDATE AUDITION & SPECTRAL ANALYSIS REPORT")
        print("=" * 70)
        for c in CANDIDATES:
            raw_diag = audit_integrity(c["raw_file"])
            norm_diag = audit_integrity(c["norm_file"])
            spec = raw_diag["spectral"]
            print(f"\n[{c['id']}] {c['label']}")
            print(f"    Source: {c['pak']} | Bank ID: {c['bank_id']} | Sound Index: {c['sound_index']}")
            print(f"    Raw Duration: {raw_diag['duration_sec']}s ({raw_diag['sample_rate']} Hz)")
            print(f"    Raw Peak / RMS: {raw_diag['peak_db']} dBFS / {raw_diag['rms_db']} dBFS")
            print(f"    Audition Matched RMS: {norm_diag['rms_db']} dBFS (Peak: {norm_diag['peak_db']} dBFS)")
            print(f"    Peak Frequency: {spec['peak_freq_hz']} Hz")
            print(f"    Spectral Energy: Sub-bass (20-150Hz): {spec['sub_bass_pct']}% | Low-mid (150-600Hz): {spec['low_mid_pct']}% | Mid-range (600-2500Hz): {spec['mid_range_pct']}% | Presence (2.5k-8k): {spec['presence_pct']}%")
            print(f"    Boundary DC/Click: Start={raw_diag['start_boundary_val']} | End={raw_diag['end_boundary_val']} | DC Offset={raw_diag['dc_offset']}")
        print("=" * 70)

    if args.play:
        if args.play == "all":
            for c in CANDIDATES:
                print(f"\n>>> Playing {c['label']} (Audition Normalized) <<<")
                play_audio(c["norm_file"])
                time.sleep(1.2)
        else:
            match_cand = next(c for c in CANDIDATES if c["id"] == args.play)
            print(f"\n>>> Playing {match_cand['label']} (Audition Normalized) <<<")
            play_audio(match_cand["norm_file"])

    if args.fatigue:
        match_cand = next(c for c in CANDIDATES if c["id"] == args.fatigue)
        print(f"\n>>> Running 5-Pulse Repetition Fatigue Test on {match_cand['label']} <<<")
        for rep in range(5):
            print(f"  Pulse [{rep + 1}/5] ...")
            play_audio(match_cand["norm_file"])
            time.sleep(0.70)
        print(">>> Fatigue test complete. <<<")
