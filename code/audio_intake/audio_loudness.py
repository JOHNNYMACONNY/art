#!/usr/bin/env python3
"""Offline PCM-WAV intake metrics for Burnside Audio Mix Pilot 01.

This tool measures sample-domain statistics, not perceptual loudness.
It deliberately does NOT report LUFS or dBTP without a true BS.1770 /
oversampled meter. Do not normalize transient, music, and ambience
to one generic sample-peak target.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import wave

SAMPLE_FORMATS = {1: 128.0, 2: 32768.0, 3: 8388608.0, 4: 2147483648.0}


def pcm_samples(data: bytes, sample_width: int):
    """Yield normalized [-1, 1) PCM samples from little-endian RIFF WAV bytes."""
    if sample_width not in SAMPLE_FORMATS:
        raise ValueError("Unsupported PCM width: %d" % sample_width)
    if len(data) % sample_width:
        raise ValueError("Partial PCM sample")
    maximum = SAMPLE_FORMATS[sample_width]
    for offset in range(0, len(data), sample_width):
        chunk = data[offset:offset + sample_width]
        if sample_width == 1:  # RIFF PCM8 is unsigned; Godot's internal WAV8 is signed.
            value = chunk[0] - 128
        else:
            value = int.from_bytes(chunk, "little", signed=True)
        yield float(value) / maximum


def dbfs(amplitude: float) -> float | None:
    return round(20.0 * math.log10(amplitude), 2) if amplitude > 0.0 else None


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def inspect_wav(path: Path, active_threshold_dbfs: float = -50.0) -> dict:
    """Read in bounded chunks; preserve channel information and avoid padding bias."""
    if not path.is_file():
        raise FileNotFoundError(path)
    with wave.open(str(path), "rb") as audio:
        channels = audio.getnchannels()
        rate = audio.getframerate()
        width = audio.getsampwidth()
        count = audio.getnframes()
        if audio.getcomptype() != "NONE" or width not in SAMPLE_FORMATS:
            raise ValueError("Only uncompressed integer PCM WAV 8/16/24/32 is supported")
        if channels < 1 or channels > 8 or rate < 8000 or rate > 192000:
            raise ValueError("Unsupported WAV channel count or sample rate")
        if count < 1:
            raise ValueError("Empty audio file")
        energy = [0.0] * channels
        total = [0.0] * channels
        peak = [0.0] * channels
        clipped = [0] * channels
        active_energy = 0.0
        active_count = 0
        window_max = 0.0
        threshold = 10 ** (active_threshold_dbfs / 20.0)
        frame_block = max(1, int(rate * 0.05))  # 50 ms energy windows, not LUFS.
        frames_read = 0
        while frames_read < count:
            take = min(frame_block, count - frames_read)
            values = list(pcm_samples(audio.readframes(take), width))
            if len(values) != take * channels:
                raise ValueError("Truncated PCM data")
            window_energy = 0.0
            for index, sample in enumerate(values):
                channel = index % channels
                energy[channel] += sample * sample
                total[channel] += sample
                peak[channel] = max(peak[channel], abs(sample))
                if abs(sample) >= 1.0 - (1.0 / SAMPLE_FORMATS[width]):
                    clipped[channel] += 1
                window_energy += sample * sample
            window_rms = math.sqrt(window_energy / len(values))
            window_max = max(window_max, window_rms)
            if window_rms >= threshold:
                active_energy += window_energy
                active_count += len(values)
            frames_read += take
    rms = [math.sqrt(v / count) for v in energy]
    dc = [v / count for v in total]
    peak_all = max(peak)
    rms_all = math.sqrt(sum(energy) / (count * channels))
    dc_all = sum(dc) / channels
    return {
        "path": str(path),
        "sha256": sha256_file(path),
        "duration_seconds": round(count / rate, 3),
        "frames": count,
        "sample_rate_hz": rate,
        "channels": channels,
        "pcm_bit_depth": 8 * width,
        "sample_peak_dbfs": dbfs(peak_all),
        "rms_dbfs": dbfs(rms_all),
        "active_rms_dbfs": dbfs(math.sqrt(active_energy / active_count)) if active_count else None,
        "max_50ms_rms_dbfs": dbfs(window_max),
        "per_channel_peak_dbfs": [dbfs(x) for x in peak],
        "per_channel_rms_dbfs": [dbfs(x) for x in rms],
        "per_channel_dc_offset": [round(x, 6) for x in dc],
        "mean_dc_offset": round(dc_all, 6),
        "clipped_samples": sum(clipped),
        "clipped_per_channel": clipped,
        "silent": peak_all < threshold,
        "true_peak_dbtp": None,
        "integrated_lufs": None,
        "warning": "Sample-domain statistics only; true peak/LUFS require an external BS.1770 meter.",
    }


def intake_verdict(metrics: dict) -> list[str]:
    """Objective source warnings; not a subjective mix or automated approval."""
    issues = []
    if metrics["silent"]:
        issues.append("SILENT_OR_NEAR_SILENT")
    if metrics["clipped_samples"]:
        issues.append("PCM_SAMPLE_CLIPPING")
    if abs(metrics["mean_dc_offset"]) >= 0.03:
        issues.append("HIGH_DC_OFFSET")
    if metrics["sample_peak_dbfs"] is not None and metrics["sample_peak_dbfs"] > -0.1:
        issues.append("PEAK_NEAR_0_DBFS")
    return issues


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="+", type=Path, help="uncompressed PCM WAV(s) to inspect")
    parser.add_argument("--output", type=Path, help="optional machine-readable JSON report")
    parser.add_argument("--fail-on-technical-warning", action="store_true")
    args = parser.parse_args(argv)
    reports = []
    try:
        for path in args.files:
            report = inspect_wav(path)
            report["technical_warnings"] = intake_verdict(report)
            report["status"] = "REQUIRES_LISTENING_AND_RIGHTS_REVIEW"
            reports.append(report)
    except (OSError, ValueError, wave.Error) as exc:
        print("Audio intake rejected: %s" % exc, file=sys.stderr)
        return 2
    output = json.dumps({"schema_version": 1, "assets": reports}, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(output, encoding="utf-8")
    else:
        sys.stdout.write(output)
    return 1 if args.fail_on_technical_warning and any(r["technical_warnings"] for r in reports) else 0


if __name__ == "__main__":
    raise SystemExit(main())
