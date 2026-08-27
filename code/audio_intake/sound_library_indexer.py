#!/usr/bin/env python3
"""
Sound Library Indexer & Inventory Tool for Echos in the Scrap.
Audits external sound libraries without mutating source files or committing binaries to Git.
Extracts format, metadata, checksums, and suggested game categories with zero external dependencies.
"""

import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import sys
from typing import Any, Dict, List, Optional, Tuple

AUDIO_EXTENSIONS = {
    ".wav": "WAV",
    ".ogg": "OGG_VORBIS",
    ".mp3": "MP3",
    ".flac": "FLAC",
    ".aif": "AIF",
    ".aiff": "AIFF",
    ".m4a": "M4A",
    ".aac": "AAC",
    ".dat": "AUDIO_PAK_CONFIG",
    ".txt": "DOCUMENTATION",
    "": "AUDIO_CONTAINER_OR_RAW"
}

IGNORED_NAMES = {
    ".ds_store",
    "thumbs.db",
    "desktop.ini",
    ".git",
    ".gitignore",
    ".import"
}

DIRECTORY_DOMAIN_MAP = {
    "player": "PLAYER",
    "vehicle": "VEHICLE",
    "vehicles": "VEHICLE",
    "interaction": "INTERACTION",
    "interactions": "INTERACTION",
    "pursuit": "PURSUIT",
    "echo": "ECHO",
    "world": "WORLD",
    "ui": "UI",
    "radio": "RADIO",
    "sfx": None,
    "feet": "PLAYER",
    "genrl": "WORLD",
    "ambience": "WORLD",
    "adverts": "RADIO",
    "beats": "RADIO",
    "streams": "RADIO",
    "config": "UNCATEGORIZED"
}

DOMAIN_KEYWORDS = {
    "RADIO": ["radio", "station", "broadcast", "dj", "advert", "commercial", "jingle", "sweeper", "track", "yardline", "chatter", "streams", "adverts", "beats"],
    "PLAYER": ["footstep", "step", "walk", "run", "boot", "shoe", "jump", "land", "breath", "grunt", "feet", "pain"],
    "VEHICLE": ["engine", "motor", "rev", "idle", "rpm", "throttle", "brake", "screech", "skid", "tire", "tyre", "drift", "bike", "hauler", "chassis", "glance", "crash", "collision", "exhaust", "traction"],
    "INTERACTION": ["panel", "peel", "pry", "wire", "clip", "snip", "spark", "crackle", "battery", "insert", "core", "extract", "latch", "relay", "switch", "lever", "hiss", "hydraulic", "pneumatic"],
    "PURSUIT": ["siren", "alarm", "drone", "pursuit", "pursuer", "radar_sweep", "scanner", "alert", "intercept", "emp", "evade", "evasion", "gate_slam", "barrier", "lockdown"],
    "ECHO": ["echo", "shimmer", "resonance", "tuner", "frequency", "sine", "heterodyne", "interference", "harmonic", "crystal", "memory", "beacon", "precursor"],
    "WORLD": ["wind", "gust", "scrap", "settling", "metal_clink", "clink", "servo", "ambience", "ambient", "factory", "machinery", "industrial", "thrum", "debris", "genrl"],
    "UI": ["click", "tick", "button", "confirm", "back", "cancel", "reject", "menu", "navigate", "select", "toggle", "cassette"]
}


def compute_sha256(file_path: Path, chunk_size: int = 65536) -> str:
    """Compute SHA-256 hash using chunked streaming."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest()


def parse_wav_header(file_path: Path) -> Tuple[str, Optional[int], Optional[int], Optional[int], Optional[float]]:
    """
    Parse RIFF/WAVE header directly via binary reading.
    Returns (format_type, sample_rate, channels, bit_depth, duration_sec).
    """
    try:
        with open(file_path, "rb") as f:
            header = f.read(12)
            if len(header) < 12:
                return "UNKNOWN", None, None, None, None
            riff, file_size, wave = struct.unpack("<4sI4s", header)
            if riff != b"RIFF" or wave != b"WAVE":
                return "UNKNOWN", None, None, None, None

            audio_format = None
            channels = None
            sample_rate = None
            bit_depth = None
            data_bytes = None

            while True:
                chunk_header = f.read(8)
                if len(chunk_header) < 8:
                    break
                chunk_id, chunk_size = struct.unpack("<4sI", chunk_header)

                if chunk_id == b"fmt ":
                    fmt_data = f.read(chunk_size)
                    if len(fmt_data) >= 14:
                        audio_format, channels, sample_rate, byte_rate, block_align = struct.unpack("<HHIIH", fmt_data[:14])
                        if len(fmt_data) >= 16:
                            bit_depth = struct.unpack("<H", fmt_data[14:16])[0]
                    # Advance to even byte boundary if chunk_size is odd
                    if chunk_size % 2 != 0:
                        f.read(1)
                elif chunk_id == b"data":
                    data_bytes = chunk_size
                    # Skip data content to keep memory flat
                    f.seek(chunk_size, os.SEEK_CUR)
                    if chunk_size % 2 != 0:
                        f.read(1)
                else:
                    # Skip other chunks (JUNK, LIST, ID3, etc.)
                    f.seek(chunk_size, os.SEEK_CUR)
                    if chunk_size % 2 != 0:
                        f.read(1)

            if audio_format is None or sample_rate is None or channels is None:
                return "WAV_OTHER", None, None, None, None

            # Format classification
            if audio_format == 1:
                fmt_name = "WAV_PCM"
            elif audio_format == 3:
                fmt_name = "WAV_FLOAT"
            else:
                fmt_name = "WAV_OTHER"

            # Compute duration if data_bytes and bit_depth are valid
            duration_sec = None
            if data_bytes is not None and bit_depth and bit_depth > 0 and sample_rate > 0 and channels > 0:
                bytes_per_sample = bit_depth / 8.0
                total_samples = data_bytes / (channels * bytes_per_sample)
                duration_sec = round(total_samples / sample_rate, 4)

            return fmt_name, sample_rate, channels, bit_depth, duration_sec

    except Exception:
        return "UNKNOWN", None, None, None, None


def infer_domain(relative_path: str, filename: str) -> Optional[str]:
    """Suggest an audio domain based on directory components and filename keywords."""
    norm_rel = relative_path.replace("\\", "/").lower()
    path_parts = [p for p in norm_rel.split("/") if p]
    
    for part in path_parts:
        if part in DIRECTORY_DOMAIN_MAP and DIRECTORY_DOMAIN_MAP[part] is not None:
            return DIRECTORY_DOMAIN_MAP[part]

    combined = f"{norm_rel}/{filename.lower()}"
    normalized = re.sub(r"[^a-z0-9_]+", "_", combined)

    for domain, keywords in DOMAIN_KEYWORDS.items():
        for kw in keywords:
            if kw in normalized:
                return domain
    return "UNCATEGORIZED"


def scan_sound_library(
    root_dir: Path,
    library_name: Optional[str] = None
) -> Dict[str, Any]:
    """
    Recursively scans sound library directory and compiles standard inventory dictionary.
    Guarantees strictly relative paths with forward slashes and no machine-specific absolute roots.
    """
    root_dir = root_dir.resolve()
    if not root_dir.exists() or not root_dir.is_dir():
        raise ValueError(f"Specified sound library path is not a directory: {root_dir}")

    lib_name = library_name or root_dir.name
    files_list: List[Dict[str, Any]] = []
    total_bytes = 0

    # Collect and sort all matching audio files for deterministic ordering
    found_paths: List[Path] = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Filter out ignored directories
        dirnames[:] = [d for d in dirnames if d.lower() not in IGNORED_NAMES and not d.startswith("._")]
        for fname in filenames:
            if fname.lower() in IGNORED_NAMES or fname.startswith("._"):
                continue
            found_paths.append(Path(dirpath) / fname)

    found_paths.sort(key=lambda p: str(p.relative_to(root_dir)).lower())

    for fpath in found_paths:
        rel_path = fpath.relative_to(root_dir).as_posix()
        # Sanitize any literal backslashes in path segment names to clean forward slashes
        clean_rel_path = rel_path.replace("\\", "/")
        if clean_rel_path.startswith("/") or ".." in clean_rel_path:
            raise ValueError(f"Dangerous relative path encountered: {clean_rel_path}")

        file_size = fpath.stat().st_size
        total_bytes += file_size
        sha256_hash = compute_sha256(fpath)
        ext = fpath.suffix.lower().lstrip(".")

        format_type = "UNKNOWN"
        sample_rate: Optional[int] = None
        channels: Optional[int] = None
        bit_depth: Optional[int] = None
        duration_sec: Optional[float] = None

        if ext == "wav":
            format_type, sample_rate, channels, bit_depth, duration_sec = parse_wav_header(fpath)
        elif ext == "ogg":
            format_type = "OGG_VORBIS"
        elif ext == "mp3":
            format_type = "MP3"
        elif ext == "flac":
            format_type = "FLAC"
        else:
            format_type = "UNKNOWN"

        suggested_domain = infer_domain(clean_rel_path, fpath.name)

        record: Dict[str, Any] = {
            "relative_path": clean_rel_path,
            "filename": fpath.name,
            "extension": ext or "none",
            "file_size_bytes": file_size,
            "sha256": sha256_hash,
            "format": format_type,
            "sample_rate": sample_rate,
            "channels": channels,
            "bit_depth": bit_depth,
            "duration_sec": duration_sec,
            "suggested_domain": suggested_domain,
            "provenance_notes": None
        }
        files_list.append(record)

    inventory: Dict[str, Any] = {
        "schema_version": 1,
        "library_name": lib_name,
        "scanned_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "file_count": len(files_list),
        "total_bytes": total_bytes,
        "files": files_list
    }

    return inventory


def validate_inventory_schema(data: Dict[str, Any], schema_path: Optional[Path] = None) -> Tuple[bool, List[str]]:
    """
    Validates inventory data against schema.
    Uses jsonschema if installed; otherwise performs comprehensive manual assertion checking.
    """
    errors: List[str] = []

    # Check top-level required fields
    required_top = ["schema_version", "library_name", "scanned_at_utc", "file_count", "total_bytes", "files"]
    for field in required_top:
        if field not in data:
            errors.append(f"Missing required top-level field: '{field}'")

    if data.get("schema_version") != 1:
        errors.append(f"Invalid schema_version: {data.get('schema_version')}, expected 1")

    files = data.get("files")
    if not isinstance(files, list):
        errors.append("'files' must be an array")
        return False, errors

    if len(files) != data.get("file_count"):
        errors.append(f"file_count mismatch: header says {data.get('file_count')}, array has {len(files)}")

    calc_bytes = sum(f.get("file_size_bytes", 0) for f in files if isinstance(f, dict))
    if calc_bytes != data.get("total_bytes"):
        errors.append(f"total_bytes mismatch: header says {data.get('total_bytes')}, sum is {calc_bytes}")

    rel_path_regex = re.compile(r"^(?!/)(?!\\)(?!.*\.\.)[a-zA-Z0-9_./ -]+$")
    sha256_regex = re.compile(r"^[a-f0-9]{64}$")
    allowed_formats = {"WAV_PCM", "WAV_FLOAT", "WAV_OTHER", "OGG_VORBIS", "MP3", "FLAC", "UNKNOWN"}
    allowed_domains = {"PLAYER", "VEHICLE", "INTERACTION", "PURSUIT", "ECHO", "WORLD", "UI", "RADIO", "UNCATEGORIZED", None}

    for idx, f in enumerate(files):
        if not isinstance(f, dict):
            errors.append(f"files[{idx}] is not an object")
            continue

        rel_path = f.get("relative_path", "")
        if not isinstance(rel_path, str) or not rel_path_regex.match(rel_path):
            errors.append(f"files[{idx}] has invalid relative_path: '{rel_path}'")

        sha = f.get("sha256", "")
        if not isinstance(sha, str) or not sha256_regex.match(sha):
            errors.append(f"files[{idx}] has invalid sha256: '{sha}'")

        fmt = f.get("format")
        if fmt not in allowed_formats:
            errors.append(f"files[{idx}] has invalid format: '{fmt}'")

        dom = f.get("suggested_domain")
        if dom not in allowed_domains:
            errors.append(f"files[{idx}] has invalid suggested_domain: '{dom}'")

        if fmt in {"WAV_PCM", "WAV_FLOAT"} and f.get("sample_rate") is not None:
            if not isinstance(f.get("sample_rate"), int) or f.get("sample_rate") <= 0:
                errors.append(f"files[{idx}] has invalid sample_rate: {f.get('sample_rate')}")
            if not isinstance(f.get("channels"), int) or not (1 <= f.get("channels") <= 8):
                errors.append(f"files[{idx}] has invalid channels: {f.get('channels')}")

    # If jsonschema library is available and schema path exists, double check with standard validator
    if schema_path and schema_path.exists():
        try:
            import jsonschema
            with open(schema_path, "r", encoding="utf-8") as sf:
                schema_json = json.load(sf)
            validator = jsonschema.Draft7Validator(schema_json)
            for err in validator.iter_errors(data):
                errors.append(f"[jsonschema] {err.json_path}: {err.message}")
        except ImportError:
            pass  # Standard fallback is already executed

    return len(errors) == 0, errors


def print_summary(inventory: Dict[str, Any]) -> None:
    """Print readable summary of the scanned library."""
    print("=" * 60)
    print(f"SOUND LIBRARY INVENTORY SUMMARY: {inventory['library_name']}")
    print("=" * 60)
    print(f"Scanned at (UTC): {inventory['scanned_at_utc']}")
    print(f"Total audio files: {inventory['file_count']}")
    print(f"Total size: {inventory['total_bytes'] / (1024 * 1024):.2f} MB ({inventory['total_bytes']:,} bytes)")
    print("-" * 60)

    # Format breakdown
    format_counts: Dict[str, int] = {}
    domain_counts: Dict[str, int] = {}
    for f in inventory["files"]:
        fmt = f["format"]
        format_counts[fmt] = format_counts.get(fmt, 0) + 1
        dom = f.get("suggested_domain") or "UNCATEGORIZED"
        domain_counts[dom] = domain_counts.get(dom, 0) + 1

    print("FORMAT BREAKDOWN:")
    for fmt, count in sorted(format_counts.items(), key=lambda x: -x[1]):
        print(f"  {fmt:<16}: {count:>5} files")

    print("\nSUGGESTED DOMAIN CATEGORIZATION:")
    for dom, count in sorted(domain_counts.items(), key=lambda x: -x[1]):
        print(f"  {dom:<16}: {count:>5} files")
    print("=" * 60)


def main() -> int:
    parser = argparse.ArgumentParser(description="Inventory external sound library for Echos in the Scrap.")
    parser.add_argument("--scan-dir", required=True, type=Path, help="Directory path of the sound library to inventory.")
    parser.add_argument("--output", "-o", type=Path, help="Destination JSON path for inventory output.")
    parser.add_argument("--name", type=str, help="Optional custom name for the library.")
    parser.add_argument("--schema", type=Path, help="Optional schema path for validation.")
    parser.add_argument("--validate", action="store_true", help="Validate output against schema before exit.")
    parser.add_argument("--summary", action="store_true", help="Print summary table to stdout.")

    args = parser.parse_args()

    try:
        inventory = scan_sound_library(args.scan_dir, library_name=args.name)
    except Exception as e:
        print(f"[ERROR] Failed to scan sound library: {e}", file=sys.stderr)
        return 1

    if args.validate or args.schema:
        schema_file = args.schema
        if not schema_file:
            default_schema = Path(__file__).resolve().parents[2] / "contracts" / "sound-library-intake.schema.json"
            if default_schema.exists():
                schema_file = default_schema

        is_valid, errors = validate_inventory_schema(inventory, schema_file)
        if not is_valid:
            print("[ERROR] Inventory validation failed against schema:", file=sys.stderr)
            for err in errors:
                print(f"  - {err}", file=sys.stderr)
            return 1

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as out_file:
            json.dump(inventory, out_file, indent=2)
        print(f"[OK] Inventory written to: {args.output}")

    if args.summary or not args.output:
        print_summary(inventory)

    return 0


if __name__ == "__main__":
    sys.exit(main())
