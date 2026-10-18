# Burnside audio recording intake — pilot #197

This is a **measurement and source-candidate intake**, not an automatic production-asset importer. Issue #31 separately owns the current native/windowed owner-listening requalification.

## Source gate

Read audio_mix_pilot_01_candidates.json. The links are CC0 **page claims**, independently looked up on 2026-10-18; all are CANDIDATE, NOT_AUDITIONED and un-ingested.

Before replacing any existing procedural fallback:

1. Obtain the **original** sound only through a lawful permitted source. Never rely on a low-quality preview, synthetic placeholder, an unverified third-party mirror, or previously committed GTA/Rockstar content.
2. Reopen the source and license page at ingestion time. Verify that the **source/derivative binary may be redistributed in a public Git repository**, not merely streamed or used in a commercial game.
3. Record creator, title, source URL, license URL/text, retrieval date, original SHA-256, original format, editor notes, audible suitability, processing steps, processed SHA-256, derived WAV path, assigned semantic slots, and who auditioned it.
4. Prepare lossless edited masters. Trim handles, remove DC offset/noise only where useful, preserve attack/decay, inspect loop boundaries and phase. For interactive Foley, create several natural variations.
5. Only then convert from CANDIDATE to an **independently approved** media manifest and adapt the Release Integrity 01 shipping boundary intentionally. The current RI01 CI prohibits all files of type WAV/OGG/MP3 under godot/audio. Simply copying a CC0 file there before adding verified manifest support **must fail**.
6. Compare output with the existing procedural fallback and other cues **at constant monitoring gain**, not merely by matching sample peaks. Only owner listening can qualify the perceptual mix.

## Offline numerical inspection

Standard library, no required third-party Python packages:

    python3 code/audio_intake/audio_loudness.py path/to/source.wav
    python3 code/audio_intake/audio_loudness.py path/to/source.wav --output /tmp/footstep-metrics.json
    python3 code/audio_intake/audio_loudness.py path/to/source.wav --fail-on-technical-warning

Reports duration, sample rate, channel count, PCM depth, SHA-256, sample peak, global RMS, above-threshold 50-ms-window RMS, maximum 50-ms-window RMS, per-channel peak/RMS, DC, and counts at PCM full scale. Warnings identify near-silence, apparent clipping, severe DC and peaks approaching 0 dBFS. They do **not** automatically make a sound suitable or unsuitable for gameplay.

**Limits:**
- Supported: uncompressed little-endian integer RIFF PCM WAV in 8/16/24/32-bit and 1–8 channels. An OGG, M4A, MP3, float WAV, or 24-bit WAVE_FORMAT_EXTENSIBLE may require a carefully verified PCM conversion first.
- RIFF unsigned PCM8 differs from Godot AudioStreamWAV.FORMAT_8_BITS's signed internal PCM. This tool deliberately interprets normal RIFF files correctly.
- integrated_lufs and true_peak_dbtp are null, never guessed. Use a verified BS.1770 loudness/true-peak analyzer (e.g., ffmpeg with EBU R128 oversampled true-peak enabled) for programme-length material and captured mixes. Do not use LUFS as a universal per-footstep/UI-tick normalization target.
- Sample peak within one PCM source is not a guarantee against **summed** game-mix peaks, codec intersample peaks, spatial attenuation, or masking.

Run tests:

    python3 -m unittest discover -s code/audio_intake -p 'test_audio_*.py' -v

## Mix plan

The 49-slot inventory, priorities and candidate map are in #196; the bounded first five-family routing/loudness acceptance is in #197. Current production routing and #31 remain authoritative until a bounded reviewed bus migration passes existing radio ducking, UI gain, semantic/reset, Web and physical-playback gates. No sound files are included with this patch.
