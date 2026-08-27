#!/usr/bin/env python3
"""
Unit tests for Sound Library Indexer & Schema Validator.
"""

import json
import math
from pathlib import Path
import struct
import tempfile
import unittest
import wave

from sound_library_indexer import (
    scan_sound_library,
    validate_inventory_schema,
    compute_sha256,
    parse_wav_header,
    infer_domain
)

SCHEMA_PATH = Path(__file__).resolve().parents[2] / "contracts" / "sound-library-intake.schema.json"


class TestSoundLibraryIndexer(unittest.TestCase):

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)

    def tearDown(self):
        self.temp_dir.cleanup()

    def _create_sine_wav(self, path: Path, sample_rate: int = 44100, channels: int = 1, duration_sec: float = 0.2, freq: float = 440.0):
        path.parent.mkdir(parents=True, exist_ok=True)
        total_frames = int(sample_rate * duration_sec)
        with wave.open(str(path), "wb") as wf:
            wf.setnchannels(channels)
            wf.setsampwidth(2)  # 16-bit
            wf.setframerate(sample_rate)
            raw_data = bytearray()
            for i in range(total_frames):
                val = int(math.sin(2.0 * math.pi * freq * (i / sample_rate)) * 16000.0)
                for _ in range(channels):
                    raw_data.extend(struct.pack("<h", val))
            wf.writeframes(raw_data)

    def test_wav_16bit_mono_metadata_extraction(self):
        wav_path = self.root / "vehicles" / "sfx_bike_engine_rev.wav"
        self._create_sine_wav(wav_path, sample_rate=44100, channels=1, duration_sec=0.25, freq=220.0)

        fmt, sr, ch, bd, dur = parse_wav_header(wav_path)
        self.assertEqual(fmt, "WAV_PCM")
        self.assertEqual(sr, 44100)
        self.assertEqual(ch, 1)
        self.assertEqual(bd, 16)
        self.assertAlmostEqual(dur, 0.25, delta=0.01)

    def test_wav_stereo_metadata_extraction(self):
        wav_path = self.root / "ui" / "sfx_ui_nav_confirm.wav"
        self._create_sine_wav(wav_path, sample_rate=48000, channels=2, duration_sec=0.10, freq=880.0)

        fmt, sr, ch, bd, dur = parse_wav_header(wav_path)
        self.assertEqual(fmt, "WAV_PCM")
        self.assertEqual(sr, 48000)
        self.assertEqual(ch, 2)
        self.assertEqual(bd, 16)
        self.assertAlmostEqual(dur, 0.10, delta=0.01)

    def test_compressed_formats_have_null_metadata(self):
        ogg_path = self.root / "radio" / "rad_station_id.ogg"
        ogg_path.parent.mkdir(parents=True, exist_ok=True)
        ogg_path.write_bytes(b"OggS\x00\x02fake_dummy_ogg_header_stream")

        mp3_path = self.root / "radio" / "track_music.mp3"
        mp3_path.write_bytes(b"\xFF\xFB\x90\x64dummy_mp3_payload_data")

        inventory = scan_sound_library(self.root, library_name="TestCompressed")
        file_map = {f["filename"]: f for f in inventory["files"]}

        self.assertIn("rad_station_id.ogg", file_map)
        self.assertEqual(file_map["rad_station_id.ogg"]["format"], "OGG_VORBIS")
        self.assertIsNone(file_map["rad_station_id.ogg"]["sample_rate"])
        self.assertIsNone(file_map["rad_station_id.ogg"]["channels"])
        self.assertIsNone(file_map["rad_station_id.ogg"]["bit_depth"])
        self.assertIsNone(file_map["rad_station_id.ogg"]["duration_sec"])

        self.assertIn("track_music.mp3", file_map)
        self.assertEqual(file_map["track_music.mp3"]["format"], "MP3")
        self.assertIsNone(file_map["track_music.mp3"]["sample_rate"])

    def test_relative_paths_never_contain_absolute_roots(self):
        wav_path = self.root / "interactions" / "sfx_panel_peel.wav"
        self._create_sine_wav(wav_path)

        inventory = scan_sound_library(self.root, library_name="TestPaths")
        self.assertEqual(len(inventory["files"]), 1)
        rel = inventory["files"][0]["relative_path"]

        self.assertEqual(rel, "interactions/sfx_panel_peel.wav")
        self.assertFalse(rel.startswith("/"))
        self.assertFalse(rel.startswith("\\"))
        self.assertNotIn("..", rel)
        self.assertNotIn(str(self.root), rel)

    def test_sha256_integrity(self):
        wav_path = self.root / "player" / "sfx_footstep_metal.wav"
        self._create_sine_wav(wav_path)

        expected_hash = compute_sha256(wav_path)
        inventory = scan_sound_library(self.root, library_name="TestHash")
        self.assertEqual(inventory["files"][0]["sha256"], expected_hash)
        self.assertEqual(len(expected_hash), 64)

    def test_domain_inference_keywords(self):
        self.assertEqual(infer_domain("vehicles", "bike_engine_rev.wav"), "VEHICLE")
        self.assertEqual(infer_domain("player", "footstep_metal_01.wav"), "PLAYER")
        self.assertEqual(infer_domain("interactions", "panel_pry_stress.wav"), "INTERACTION")
        self.assertEqual(infer_domain("pursuit", "police_siren_drone.wav"), "PURSUIT")
        self.assertEqual(infer_domain("echo", "crystal_shimmer_harmonic.wav"), "ECHO")
        self.assertEqual(infer_domain("world", "scrap_valley_wind_gust.wav"), "WORLD")
        self.assertEqual(infer_domain("ui", "button_confirm_tick.wav"), "UI")
        self.assertEqual(infer_domain("radio", "dj_station_sweeper.wav"), "RADIO")
        self.assertEqual(infer_domain("random", "untitled_file_123.wav"), "UNCATEGORIZED")

    def test_schema_validation_passes_cleanly(self):
        self._create_sine_wav(self.root / "sfx_engine.wav")
        self._create_sine_wav(self.root / "sfx_footstep.wav")

        inventory = scan_sound_library(self.root, library_name="ValidLib")
        is_valid, errors = validate_inventory_schema(inventory, SCHEMA_PATH)
        self.assertTrue(is_valid, f"Validation failed with errors: {errors}")
        self.assertEqual(len(errors), 0)

    def test_schema_validation_catches_tampered_inventory(self):
        self._create_sine_wav(self.root / "sfx_engine.wav")
        inventory = scan_sound_library(self.root, library_name="TamperedLib")

        # Tamper total_bytes
        tampered = json.loads(json.dumps(inventory))
        tampered["total_bytes"] += 9999
        is_valid, errors = validate_inventory_schema(tampered, SCHEMA_PATH)
        self.assertFalse(is_valid)
        self.assertTrue(any("total_bytes mismatch" in e for e in errors))

        # Tamper relative_path with absolute path
        tampered2 = json.loads(json.dumps(inventory))
        tampered2["files"][0]["relative_path"] = "/absolute/system/path.wav"
        is_valid2, errors2 = validate_inventory_schema(tampered2, SCHEMA_PATH)
        self.assertFalse(is_valid2)
        self.assertTrue(any("invalid relative_path" in e for e in errors2))


if __name__ == "__main__":
    unittest.main()
