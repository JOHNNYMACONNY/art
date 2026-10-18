"""Tests for source PCM statistics and non-approval behavior."""
from __future__ import annotations

import math
from pathlib import Path
import struct
import tempfile
import unittest
import wave

from audio_loudness import dbfs, inspect_wav, intake_verdict, pcm_samples


class AudioIntakeMetricsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.wav = Path(self.directory.name) / "fixture.wav"

    def write_wav(self, samples: list[int], width: int = 2, channels: int = 1, rate: int = 48000):
        with wave.open(str(self.wav), "wb") as writer:
            writer.setnchannels(channels)
            writer.setsampwidth(width)
            writer.setframerate(rate)
            if width == 1:
                data = bytes(samples)
            else:
                data = b"".join(int(x).to_bytes(width, "little", signed=True) for x in samples)
            writer.writeframes(data)

    def test_16_bit_bipolar_signal_and_sha(self):
        self.write_wav([16384, -16384] * 2400)
        stats = inspect_wav(self.wav)
        self.assertEqual(stats["pcm_bit_depth"], 16)
        self.assertEqual(stats["sample_rate_hz"], 48000)
        self.assertEqual(stats["duration_seconds"], 0.1)
        self.assertAlmostEqual(stats["sample_peak_dbfs"], -6.02, places=2)
        self.assertAlmostEqual(stats["rms_dbfs"], -6.02, places=2)
        self.assertEqual(stats["mean_dc_offset"], 0.0)
        self.assertFalse(stats["silent"])
        self.assertEqual(stats["clipped_samples"], 0)
        self.assertEqual(int(stats["sha256"], 16).bit_length() > 0, True)
        self.assertIsNone(stats["integrated_lufs"])
        self.assertIsNone(stats["true_peak_dbtp"])
        self.assertEqual(intake_verdict(stats), [])

    def test_stereo_keeps_channel_levels_distinct(self):
        samples = []
        for _ in range(4800):
            samples.extend([8192, -16384])
        self.write_wav(samples, channels=2)
        stats = inspect_wav(self.wav)
        self.assertEqual(stats["channels"], 2)
        self.assertAlmostEqual(stats["per_channel_peak_dbfs"][0], -12.04, places=2)
        self.assertAlmostEqual(stats["per_channel_peak_dbfs"][1], -6.02, places=2)
        self.assertEqual(stats["per_channel_dc_offset"], [0.25, -0.5])

    def test_8_bit_riff_unsigned_is_centered_at_128(self):
        self.write_wav([128, 192, 64, 128] * 1200, width=1)
        stats = inspect_wav(self.wav)
        self.assertEqual(stats["pcm_bit_depth"], 8)
        self.assertAlmostEqual(stats["mean_dc_offset"], 0.0, places=6)
        self.assertAlmostEqual(stats["sample_peak_dbfs"], -6.02, places=2)

    def test_signed_24_bit_pcm(self):
        self.write_wav([0, 4194304, -4194304] * 1600, width=3)
        stats = inspect_wav(self.wav)
        self.assertEqual(stats["pcm_bit_depth"], 24)
        self.assertAlmostEqual(stats["sample_peak_dbfs"], -6.02, places=2)
        self.assertEqual(stats["clipped_samples"], 0)

    def test_silence_and_all_full_scale_flagged(self):
        self.write_wav([0] * 4800)
        silent = inspect_wav(self.wav)
        self.assertIn("SILENT_OR_NEAR_SILENT", intake_verdict(silent))
        self.assertIsNone(silent["sample_peak_dbfs"])
        self.write_wav([32767, -32768] * 2400)
        clipped = inspect_wav(self.wav)
        self.assertIn("PCM_SAMPLE_CLIPPING", intake_verdict(clipped))
        self.assertIn("PEAK_NEAR_0_DBFS", intake_verdict(clipped))

    def test_dc_offset_is_reported_not_normalized(self):
        self.write_wav([5000] * 4800)
        stats = inspect_wav(self.wav)
        self.assertIn("HIGH_DC_OFFSET", intake_verdict(stats))
        self.assertAlmostEqual(stats["mean_dc_offset"], 5000 / 32768.0, places=5)

    def test_empty_source_rejected(self):
        self.write_wav([])
        with self.assertRaisesRegex(ValueError, "Empty audio"):
            inspect_wav(self.wav)

    def test_sample_decoder_rejects_partial_bytes(self):
        with self.assertRaisesRegex(ValueError, "Partial PCM"):
            list(pcm_samples(b"\x01", 2))
        self.assertIsNone(dbfs(0.0))


if __name__ == "__main__":
    unittest.main()
