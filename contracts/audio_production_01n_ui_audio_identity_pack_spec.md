# Audio Production 01N — UI Audio Identity Pack

**State:** SOURCES_SELECTED__PRODUCTION_INGESTION_AUTHORIZED  
**Baseline:** `main@0c9b90692a1a5b3f3f259953829f0e599984be89`

## Intent

Replace the seven procedural incidental UI semantic cues owned by `UIAudioIdentityLayer` / `UIAudioSemanticRegistry` with a coherent production GTA SA UI identity pack, while preserving the current UI playback, suppression, concurrency, lifecycle, and fallback architecture.

Human candidate audition is complete. The seven winners below are locked and production ingestion of exactly those winners into `res://audio/ui/` is authorized.

## Locked target set

Exactly these seven slots are in scope:

| Slot | Planned production path | Locked winner | Format / frames | Container File SHA-256 | Raw PCM SHA-256 | Runner-up |
| --- | --- | --- | --- | --- | --- | --- |
| `ui.nav_move` | `res://audio/ui/sfx_ui_nav_move.wav` | `GTA_SA:GENRL:BANK_143:SOUND_76` | 44100 Hz mono PCM16 / 1302 | `15f58f00f0fc0ed737aa3ce70c7bc15836e146b1d296e16d989ae5d1eaaa7fe9` | `aa2141c9430efe3b245ee5b44157ab077ddd89d934655fa7961ffe275e41805c` | `GTA_SA:GENRL:BANK_138:SOUND_29` |
| `ui.nav_confirm` | `res://audio/ui/sfx_ui_nav_confirm.wav` | `GTA_SA:GENRL:BANK_143:SOUND_77` | 44100 Hz mono PCM16 / 2824 | `6790e442ce044678298174b0b028a4ced0e5cc72d3a165d478b4d12e92448be5` | `0c669ad54e911728ab16b883cc555df3067c50e29ddc2910734f4b0c93d2bf27` | `GTA_SA:GENRL:BANK_143:SOUND_55` |
| `ui.nav_back` | `res://audio/ui/sfx_ui_nav_back.wav` | `GTA_SA:GENRL:BANK_143:SOUND_44` | 18000 Hz mono PCM16 / 623 | `b4f9abb16fd1e79407904dc44b55c4803f6ceb653c88c57986763cfd78835de7` | `061b9cc26d1e6af092267fc0b949d2573c81b0d8a57dbdf772de6485539faab2` | `GTA_SA:GENRL:BANK_143:SOUND_34` |
| `ui.mode_switch` | `res://audio/ui/sfx_ui_mode_switch.wav` | `GTA_SA:GENRL:BANK_143:SOUND_17` | 23000 Hz mono PCM16 / 1999 | `8957d4026569878f41d08ff1bcfa63906214d4c5701c083646841935d034d50b` | `1418770fc0089bf5e309c13c1efe0f275c967ae4dc5feb433b104b560d64263d` | `GTA_SA:GENRL:BANK_143:SOUND_18` |
| `ui.reject` | `res://audio/ui/sfx_ui_reject.wav` | `GTA_SA:GENRL:BANK_143:SOUND_4` | 22000 Hz mono PCM16 / 2143 | `24fff4d27aaf2f4125f7ef2acb93450596fb10042e28f41e1442a492dc33287b` | `04964bf39958d7a8489e05a177de7a36c466415b121524e3584043d01f0b09f5` | `GTA_SA:GENRL:BANK_143:SOUND_71` |
| `ui.radio_station_step` | `res://audio/ui/sfx_ui_radio_step.wav` | `GTA_SA:GENRL:BANK_143:SOUND_47` | 24000 Hz mono PCM16 / 2381 | `f8c28c58a46875cfc6b4b50c515356332e2e4b03412243ba7d5f5dbc32ff6451` | `283cd247c21b3e3e6f05fab00d2aaf843bbbc87e6a8ba87569023894cc5e9d2f` | `GTA_SA:GENRL:BANK_143:SOUND_50` |
| `ui.replay_retry_confirm` | `res://audio/ui/sfx_ui_replay_retry_confirm.wav` | `GTA_SA:GENRL:BANK_143:SOUND_73` | 26000 Hz mono PCM16 / 2697 | `8df5b3b1fc615648b39ed2080cb5562252555c11ad7c00d9bbf66bc16cd7dc80` | `eaff3fbad94ab16329f976307d94b6220452f4933cca4d847d67ed68afdf3c02` | `GTA_SA:GENRL:BANK_143:SOUND_84` |

The executable source of truth for exact winner/runner-up metadata is `res://tests/ui_audio_identity_selection_lock.gd`.

## Audition decision record

- `ui.nav_move`: crisp, non-fatiguing dry navigation tick for fast traversal.
- `ui.nav_confirm`: positive latch confirmation paired with navigation movement.
- `ui.nav_back`: soft descending release tick for cancel/back.
- `ui.mode_switch`: two-position mechanical toggle identity.
- `ui.reject`: distinct low-mid warning/reject pulse for invalid actions.
- `ui.radio_station_step`: quick relay/tuner detent for station changes.
- `ui.replay_retry_confirm`: heavier commitment latch for retry/replay.

The seven winners are locked. Runner-ups are retained only as provenance/audition history and must not be substituted without a new accepted source-selection decision.

## Runtime contract promoted at media stage

All seven slots are promoted to:

- `domain=UI`
- `diegesis=NON_DIEGETIC`
- `spatial_type=NON_DIEGETIC_2D`
- `mix_group=INCIDENTAL_UI`
- `playback_type=TRANSIENT`
- `asset_status=LICENSED_FINAL`
- `replacement_required=false`

Existing cooldown, gain, max-concurrency, `critical_essential`, suppression, and reset behavior remain identical. `UIAudioIdentityLayer` remains the sole UI audio playback owner and `AudioManager.reset_audio_instant()` remains the authoritative voice-lifecycle reset.

The independently reachable procedural fallback for each slot remains intact in `_create_fallback_stream()`. Local reference audio fails closed when `LICENSED_FINAL`.

## Production verification requirements

The production contract verifies for all seven assets:

- exact provenance and canonical path;
- exact native sample rate, mono PCM16 format, frame count, raw byte count, duration, and raw PCM SHA-256 cross-validated from the selection lock;
- final repository container WAV SHA-256;
- non-looping playback and uncompressed import settings (`compress/mode=0`);
- final-slot local-reference fail-closed behavior;
- independently reachable procedural fallback per slot;
- unchanged cooldown/concurrency/gain/suppression/critical-essential policy;
- authoritative AudioManager reset removes all UI voices;
- `ui_audio_identity_audio_production_contract_test.gd`, `ui_audio_identity_candidate_selection_contract_test.gd`, `ui_audio_identity_contract_test.gd`, Audio Runtime 31, and canonical Web compatibility remain green.

Native listening on the exact production head exercises rapid navigation repetition, confirm/back/reject semantic distinction, mode/radio switching, replay/retry confirmation, small-speaker/headphone readability, pursuit pressure suppression, Memory Echo suppression/recovery, and reset/replay behavior.
