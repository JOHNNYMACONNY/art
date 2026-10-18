"""Rights-safety and provenance gates for #197's candidate ledger.

These tests do not turn claimed CC0 web pages into approved audio files.
All source binaries must be independently obtained, hashed and auditioned.
"""
from __future__ import annotations

import json
from pathlib import Path
import unittest
from urllib.parse import urlparse

LEDGER = Path(__file__).with_name("audio_mix_pilot_01_candidates.json")


class CandidateLedgerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads(LEDGER.read_text(encoding="utf-8"))

    def test_source_ledger_is_explicitly_candidate_only(self):
        self.assertEqual(self.data["schema_version"], 1)
        self.assertEqual(self.data["pilot_issue"], 197)
        self.assertEqual(self.data["status"], "CANDIDATES_ONLY_NOT_INGESTED")
        self.assertEqual(len(self.data["candidates"]), 6)

    def test_no_unreviewed_media_is_marked_final(self):
        slots = set()
        for asset in self.data["candidates"]:
            with self.subTest(slot=asset["slot"]):
                self.assertNotIn(asset["slot"], slots)
                slots.add(asset["slot"])
                self.assertEqual(asset["license_declared"], "CC0")
                self.assertEqual(asset["audition_status"], "NOT_AUDITIONED")
                self.assertEqual(asset["ingestion_status"], "CANDIDATE")
                self.assertIsNone(asset["raw_sha256"])
                self.assertIsNone(asset["processed_sha256"])
                url = urlparse(asset["source_url"])
                self.assertEqual(url.scheme, "https")
                self.assertEqual(url.hostname, "freesound.org")
                self.assertTrue(url.path.startswith("/people/"))
                self.assertGreater(asset["source_duration_seconds"], 0.0)
                self.assertTrue(asset["creator"])
                self.assertTrue(asset["design_intent"])

    def test_5_gameplay_families_have_source_candidate(self):
        slots = {x["slot"] for x in self.data["candidates"]}
        self.assertTrue({
            "player.footstep",
            "interaction.panel_peel",
            "echo.radio_interference",
            "vehicle.engine_rev",
            "pursuit.siren_alarm",
        }.issubset(slots))


if __name__ == "__main__":
    unittest.main()
