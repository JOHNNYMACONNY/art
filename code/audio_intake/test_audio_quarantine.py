"""Bounds and fail-closed rights rules for quarantined source acquisition."""
from __future__ import annotations

import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
import wave
import zipfile

from audition_quarantine import safe_archive_members, safe_url, stage_sources

CATALOG = Path(__file__).with_name("audio_production_02_sources.json")


def make_wav():
    buf = io.BytesIO()
    with wave.open(buf, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(48000)
        f.writeframes(struct.pack("<100h", *([1000] * 100)))
    return buf.getvalue()


class QuarantineTests(unittest.TestCase):
    def test_catalog_has_cc0_provenance_for_recorded_material(self):
        src = json.loads(CATALOG.read_text())
        self.assertEqual(len(src["sources"]), 3)
        for item in src["sources"]:
            self.assertTrue(safe_url(item["download_url"]))
            self.assertEqual(item["license"], "CC0-1.0")
            self.assertTrue(item["source_page"].startswith("https://opengameart.org/content/"))

    def test_reject_other_origins_and_credentials(self):
        for url in ["http://opengameart.org/a", "https://127.0.0.1/a", "https://opengameart.org.evil.test/a", "https://test@opengameart.org/a"]:
            self.assertFalse(safe_url(url))

    def test_reject_unsafe_zip_member(self):
        for filename in ["../bad.wav", "/bad.wav", "dir\\bad.wav"]:
            buf = io.BytesIO()
            with zipfile.ZipFile(buf, "w") as z:
                z.writestr(filename, make_wav())
            with self.assertRaises(ValueError):
                safe_archive_members(buf.getvalue())

    def test_no_approval_issued_by_staging(self):
        src = json.loads(CATALOG.read_text())
        src["sources"] = src["sources"][:1]
        with tempfile.TemporaryDirectory() as p:
            report = stage_sources(src, Path(p) / "audition", fetch_fn=lambda _: make_wav(), convert=False)
            self.assertEqual(report["approval"], "NONE_NOT_AUDITIONED")
            self.assertEqual(report["sources"][0]["audition_status"], "NOT_AUDITIONED")
            self.assertEqual(report["sources"][0]["files"][0]["file_sha256"], report["sources"][0]["source_sha256"])

    def test_reject_disguised_license(self):
        src = json.loads(CATALOG.read_text())
        src["sources"] = src["sources"][:1]
        src["sources"][0]["license"] = "CC-BY-NC"
        with tempfile.TemporaryDirectory() as p:
            with self.assertRaises(ValueError):
                stage_sources(src, Path(p) / "audition", fetch_fn=lambda _: make_wav(), convert=False)


if __name__ == "__main__":
    unittest.main()
