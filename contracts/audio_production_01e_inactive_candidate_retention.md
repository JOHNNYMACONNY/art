# Audio Production 01E — Inactive Slot Candidate Retention

**State:** CANDIDATES_RETAINED__RUNTIME_INACTIVE  
**Baseline:** `main@4143df7de151e8cb5d672c2dea8f85c433b647ef`

## Purpose

Preserve human-auditioned GTA San Andreas candidate identities for three semantic interaction slots that currently have no authoritative gameplay event or procedural runtime path.

This document is retention evidence only. It does **not** authorize production promotion, asset ingestion, `AudioManager` event mapping, registry status changes, or new gameplay seams.

## Runtime authority inspection

### `interaction.panel_pry`

- Live gameplay event: **NO**
- Current Corroded Panel behavior enters the existing panel-peel path directly; there is no separate authoritative pry audio event.
- Procedural fallback: **NONE**
- Production disposition: **DEFER** until an actual pry gameplay step exists.

Retained candidate:

- source: `GTA_SA:GENRL:BANK_143:SOUND_40`
- raw duration: `0.1547 s`
- native sample rate: `22,050 Hz`
- format: mono 16-bit PCM
- raw SHA-256: `3205a8aa7708517f6b036dfa89b66def9c4cf997efae790675e4657024b56127`

### `interaction.wire_clip`

- Live gameplay event: **NO**
- Current extraction flow emits the existing completion and spark semantics; there is no separate authoritative wire-cut event.
- Procedural fallback: **NONE**
- Production disposition: **DEFER** until an actual wire-cut gameplay step exists.

Retained candidate:

- source: `GTA_SA:GENRL:BANK_143:SOUND_48`
- raw duration: `0.0751 s`
- native sample rate: `22,050 Hz`
- format: mono 16-bit PCM
- raw SHA-256: `c98b758a7463f8667be351cf9a16181e1c04b5ea0a57b9a20aa25345c62846e9`

### `interaction.battery_insert`

- Live gameplay event: **NO**
- No current power-cell insertion mechanic emits a battery-insert audio event.
- Procedural fallback: **NONE**
- Production disposition: **DEFER** until an actual battery insertion mechanic exists.

Retained candidate:

- source: `GTA_SA:GENRL:BANK_100:SOUND_0`
- raw duration: `0.3132 s`
- native sample rate: `17,968 Hz`
- format: mono 16-bit PCM
- raw SHA-256: `0668e15e846ce1cae9e2b77fc5955219bb5393745385ecfe84721a7d31682db6`

## Retention boundary

- No production WAVs for these three candidates enter Git in 01E.
- No `.wav.import` files are added.
- Their `AudioRegistry` slots remain unchanged and replacement-required.
- No `SoundEvent` values are added or remapped for them.
- No placeholder gameplay mechanic may be invented solely to justify using a selected sound.
- When a real mechanic/event exists, re-check the retained candidate against the actual gameplay timing and mix before production ingestion.

## Next live production target

Runtime inspection confirms `player.signal_lock_pulse` is already live: `SignalTuner._lock_signal()` emits `SIGNAL_LOCK` at the tuner's authoritative `global_position`.

That live semantic is a valid candidate for a subsequent production-audio slice; it is intentionally out of scope for this retention-only 01E checkpoint.
