#!/usr/bin/env python3
"""Acquire and meter untrusted CC0 candidates into a NON-SHIPPING audition artifact.

This tool never approves a sample or writes under godot/. Explicit listening,
source-file rights checks and runtime tests remain required before ingestion.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import math
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
from urllib.parse import urlparse
from urllib.request import Request, urlopen
import zipfile

from audio_loudness import inspect_wav, intake_verdict

MAX_DOWNLOAD = 16 * 1024 * 1024
MAX_ENTRY = 12 * 1024 * 1024
MAX_EXTRACTED = 64 * 1024 * 1024
MAX_ENTRIES = 48
MAX_DECODED_FILE = 12 * 1024 * 1024
MAX_DECODED_TOTAL = 64 * 1024 * 1024
MAX_AUDIO_SECONDS = 30.0
GODOT_PROJECT = (Path(__file__).resolve().parents[2] / "godot").resolve()
ALLOWED_HOST = "opengameart.org"
ALLOWED_SUFFIXES = {".wav", ".ogg"}


def safe_url(url: str) -> bool:
    p = urlparse(url)
    return p.scheme == "https" and p.hostname == ALLOWED_HOST and not p.username and not p.password and p.port is None


def safe_archive_members(blob: bytes) -> list[tuple[str, bytes]]:
    """Never extract paths or symlinks; accept only bounded audio bytes."""
    results = []
    total = 0
    with zipfile.ZipFile(io.BytesIO(blob)) as archive:
        for info in archive.infolist():
            path = PurePosixPath(info.filename)
            if info.is_dir():
                continue
            if path.is_absolute() or ".." in path.parts or "\\" in info.filename:
                raise ValueError("Unsafe archive path")
            if (info.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError("Archive symlink rejected")
            if path.suffix.lower() not in ALLOWED_SUFFIXES:
                continue
            if info.file_size > MAX_ENTRY or info.flag_bits & 1:
                raise ValueError("Oversize or encrypted archive audio")
            total += info.file_size
            if total > MAX_EXTRACTED or len(results) >= MAX_ENTRIES:
                raise ValueError("Archive audio budget exceeded")
            content = archive.read(info)
            if len(content) != info.file_size:
                raise ValueError("Bad archive entry length")
            results.append((path.name, content))
    if not results:
        raise ValueError("Archive contains no WAV/OGG audio")
    return results


def fetch_limited(url: str) -> bytes:
    if not safe_url(url):
        raise ValueError("Download URL not on approved origin")
    request = Request(url, headers={"User-Agent": "FB13-CC0-audition/1.0"})
    with urlopen(request, timeout=35) as response:
        if not safe_url(response.geturl()):
            raise ValueError("Cross-origin redirect rejected")
        data = response.read(MAX_DOWNLOAD + 1)
        if len(data) > MAX_DOWNLOAD:
            raise ValueError("Download over 16 MiB limit")
    if not data:
        raise ValueError("Empty download")
    return data


def is_shipping_path(path: Path) -> bool:
    """Protect the actual repository Godot directory regardless of current CWD."""
    return path.resolve().is_relative_to(GODOT_PROJECT)


def probe_decoded_budget(path: Path) -> int:
    """Require credible bounded audio metadata before allocating a PCM WAV."""
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "a:0",
         "-show_entries", "format=duration:stream=channels,sample_rate,duration",
         "-of", "json", str(path)],
        check=True, capture_output=True, text=True, timeout=20,
    )
    info = json.loads(result.stdout)
    streams = info.get("streams") or []
    if not streams:
        raise ValueError("No decodable audio stream")
    audio = streams[0]
    channels = int(audio.get("channels", 0))
    rate = int(audio.get("sample_rate", 0))
    duration_text = (info.get("format") or {}).get("duration") or audio.get("duration")
    if duration_text is None:
        raise ValueError("Unbounded audio duration")
    duration = float(duration_text)
    if not math.isfinite(duration) or duration <= 0 or duration > MAX_AUDIO_SECONDS:
        raise ValueError("Audio duration exceeds audition limit")
    if channels not in (1, 2) or not 8000 <= rate <= 192000:
        raise ValueError("Unsupported audio channels or rate")
    projected = math.ceil(duration * 48000 * channels * 3) + 4096
    if projected > MAX_DECODED_FILE:
        raise ValueError("Decoded PCM file exceeds limit")
    return projected


def basename(value: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_.-]+", "_", value)[:80].strip("._") or "sound"


def stage_sources(catalog: dict, output: Path, fetch_fn=fetch_limited, convert=True) -> dict:
    if catalog.get("schema_version") != 1:
        raise ValueError("Unknown catalog schema")
    if is_shipping_path(output):
        raise ValueError("Do not stage in shipping Godot project")
    source_dir = output / "raw_source"
    audition_dir = output / "audition_48khz"
    source_dir.mkdir(parents=True, exist_ok=True)
    audition_dir.mkdir(parents=True, exist_ok=True)
    if is_shipping_path(source_dir) or is_shipping_path(audition_dir):
        raise ValueError("Symlink to shipping Godot project rejected")
    projected_total = 0
    report = {"schema_version": 1, "approval": "NONE_NOT_AUDITIONED", "purpose": "quarantine_only_not_game_assets", "sources": []}
    for item in catalog["sources"]:
        url = item["download_url"]
        if not safe_url(url) or item["license"] != "CC0-1.0" or item["license_url"] != "https://creativecommons.org/publicdomain/zero/1.0/":
            raise ValueError("Unapproved source or license fields")
        source_id = basename(item["id"])
        if source_id != item["id"]:
            raise ValueError("Unsafe source ID")
        blob = fetch_fn(url)
        if len(blob) > MAX_DOWNLOAD:
            raise ValueError("Oversize downloaded content")
        suffix = Path(urlparse(url).path).suffix.lower()
        if suffix not in {".zip", ".wav", ".ogg"}:
            raise ValueError("Unsupported source format")
        raw_path = source_dir / f"{source_id}{suffix}"
        raw_path.write_bytes(blob)
        entries = safe_archive_members(blob) if suffix == ".zip" else [(raw_path.name, blob)]
        asset = {k: item[k] for k in ("id", "family", "creator", "source_title", "source_page", "download_url", "license", "license_url")}
        asset.update({"source_sha256": hashlib.sha256(blob).hexdigest(), "download_bytes": len(blob), "audition_status": "NOT_AUDITIONED", "files": []})
        for i, (name, data) in enumerate(entries):
            if Path(name).suffix.lower() not in ALLOWED_SUFFIXES:
                raise ValueError("Non-audio source payload")
            path = source_dir / f"{source_id}_{i:02}_{basename(name)}"
            path.write_bytes(data)
            file_row = {"original_name": name, "file_sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
            if convert:
                projected_total += probe_decoded_budget(path)
                if projected_total > MAX_DECODED_TOTAL:
                    raise ValueError("Decoded audition artifact exceeds total PCM budget")
                derived = audition_dir / (path.stem + ".wav")
                subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-i", str(path), "-map", "0:a:0", "-vn", "-ar", "48000", "-c:a", "pcm_s24le", "-fs", str(MAX_DECODED_FILE), str(derived)], check=True, timeout=60)
                if derived.stat().st_size >= MAX_DECODED_FILE:
                    raise ValueError("FFmpeg output hit its safety cap")
                metrics = inspect_wav(derived)
                file_row.update({"audition_file": str(derived.relative_to(output)), "metrics": metrics | {"technical_warnings": intake_verdict(metrics)}})
            asset["files"].append(file_row)
        report["sources"].append(asset)
    (output / "manifest.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (output / "READ_ME_FIRST.txt").write_text("FB-13 AUDIO PRODUCTION 02 / QUARANTINED CC0 AUDITION\nAll sources: NOT AUDITIONED and NOT INTEGRATED. Listen and verify rights again before any merge into godot/.\nOriginal input files under raw_source; 48 kHz 24-bit listening copies under audition_48khz. No gain normalization, mix approval, or shipping authorization is implied.\n", encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        report = stage_sources(json.loads(args.catalog.read_text(encoding="utf-8")), args.output)
        print(json.dumps({"sources": len(report["sources"]), "files": sum(len(r["files"]) for r in report["sources"]), "approval": report["approval"]}))
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        print(f"Audition quarantine failed: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
