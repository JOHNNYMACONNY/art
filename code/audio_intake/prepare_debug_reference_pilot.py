#!/usr/bin/env python3
"""Build non-shipping Godot debug-reference WAVs from hash-verified quarantine files.

A runtime loading probe, not asset approval, game audio replacement, or release media.
"""
from __future__ import annotations

import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
import wave

# Deliberate, narrow candidate-to-slot probes. Relative gains are experimental.
PILOT = (
    ("player.footstep", "oga-subway-footsteps", 0, 12.0, 1),
    ("interaction.panel_peel", "oga-metal-foley", 15, -6.0, 1),
    ("vehicle.collision_glance", "oga-metal-foley", 0, -6.0, 1),
    ("vehicle.engine_rev", "oga-fan-motor", 0, -9.0, 1),
    ("ui.nav_confirm", "oga-physical-ui-click", 0, 0.0, 2),
)
GODOT_ROOT = (Path(__file__).resolve().parents[2] / "godot").resolve()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def build(quarantine: Path, output: Path) -> dict:
    if output.resolve().is_relative_to(GODOT_ROOT):
        raise ValueError("Never put unapproved debug WAVs in shipping godot/")
    data = json.loads((quarantine / "manifest.json").read_text(encoding="utf-8"))
    if data.get("approval") != "NONE_NOT_AUDITIONED":
        raise ValueError("Unexpected candidate approval state")
    sources = {row["id"]: row for row in data["sources"]}
    if len(sources) != len(data["sources"]):
        raise ValueError("Duplicate source ID")
    sample_dir = output / "samples"
    sample_dir.mkdir(parents=True, exist_ok=True)
    if sample_dir.resolve().is_relative_to(GODOT_ROOT):
        raise ValueError("Symlink into shipping godot/ rejected")

    manifest = {"version": 1, "slots": {}}
    qc = {"status": "UNAPPROVED_DEBUG_REFERENCE_ONLY", "slots": []}
    for slot, source_id, index, gain_db, channels in PILOT:
        source = sources[source_id]
        if source.get("source_sha256_verified") is not True or source.get("source_sha256") != source.get("expected_source_sha256"):
            raise ValueError("Unverified source: " + source_id)
        file_row = source["files"][index]
        if file_row["metrics"]["technical_warnings"]:
            raise ValueError("Source technical warnings: " + slot)
        rel = Path(file_row["audition_file"])
        if rel.is_absolute() or ".." in rel.parts or not rel.parts or rel.parts[0] != "audition_48khz":
            raise ValueError("Unsafe audition path")
        original = quarantine / rel
        if not original.resolve().is_relative_to((quarantine / "audition_48khz").resolve()):
            raise ValueError("Audition symlink/path escape")
        if sha256(original) != file_row["metrics"]["sha256"]:
            raise ValueError("Derivative SHA-256 mismatch: " + slot)

        wav_name = slot.replace(".", "_") + ".wav"
        target = sample_dir / wav_name
        subprocess.run([
            "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
            "-i", str(original), "-map", "0:a:0", "-vn",
            "-af", "volume=%sdB" % gain_db, "-ar", "48000", "-ac", str(channels),
            "-c:a", "pcm_s16le", str(target),
        ], check=True, timeout=40)
        with wave.open(str(target), "rb") as wav:
            if (wav.getframerate(), wav.getnchannels(), wav.getsampwidth()) != (48000, channels, 2):
                raise ValueError("Godot debug WAV format changed")
            raw = wav.readframes(wav.getnframes())
        samples = array.array("h")
        samples.frombytes(raw)
        if sys.byteorder != "little":
            samples.byteswap()
        if not samples:
            raise ValueError("Empty WAV")
        peak = max(abs(value) for value in samples) / 32768.0
        if peak < 0.0001 or peak >= 0.89125:
            raise ValueError("Silent or excessive sample peak for " + slot)

        manifest["slots"][slot] = "samples/" + wav_name
        qc["slots"].append({
            "id": slot, "source_id": source_id, "source_sha256": source["source_sha256"],
            "audition_sha256": file_row["metrics"]["sha256"], "debug_wav_sha256": sha256(target),
            "gain_db": gain_db, "channels": channels,
            "sample_peak_dbfs": round(20.0 * math.log10(peak), 2),
            "approved": False,
        })
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (output / "qc.json").write_text(json.dumps(qc, indent=2) + "\n", encoding="utf-8")
    (output / "README.txt").write_text(
        "NON-SHIPPING AUDIO TEST ONLY. Not approved or integrated. "
        "Requires explicit debug AudioReferenceResolver opt-in. "
        "Human playback, loop/mix and mobile-quality tests remain open.\n",
        encoding="utf-8",
    )
    return qc


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quarantine", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        qc = build(args.quarantine, args.output)
    except (OSError, ValueError, KeyError, IndexError, wave.Error,
            subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
        print("Debug-reference pilot rejected: %s" % error, file=sys.stderr)
        return 2
    print(json.dumps({"status": qc["status"], "slots": len(qc["slots"])}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
