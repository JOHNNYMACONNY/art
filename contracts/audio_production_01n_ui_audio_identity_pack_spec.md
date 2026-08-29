# Audio Production 01N — UI Audio Identity Pack

State: `CANDIDATE_SELECTION_LOCKED__PRODUCTION_INGESTION_NOT_AUTHORIZED`

Baseline: `main@d66771805277838bd9c7c05329307f701e1f06b2`

## Intent

Replace the seven procedural incidental UI semantic cues owned by `UIAudioIdentityLayer` / `UIAudioSemanticRegistry` with a coherent production GTA SA UI identity pack, while preserving the current UI playback, suppression, concurrency, lifecycle, and fallback architecture.

This checkpoint locks source selections only. It does **not** authorize production WAV ingestion, registry promotion, runtime production-stream resolution, retention-summary promotion, or any unrelated UI/gameplay mutation.

## Locked target set

Exactly these seven slots are in scope:

| Slot | Planned production path | Locked winner | Format / frames | Raw PCM SHA-256 | Runner-up |
| --- | --- | --- | --- | --- | --- |
| `ui.nav_move` | `res://audio/ui/sfx_ui_nav_move.wav` | `GTA_SA:GENRL:BANK_143:SOUND_76` | 44100 Hz mono PCM16 / 1302 | `aa2141c9430efe3b245ee5b44157ab077ddd89d934655fa7961ffe275e41805c` | `GTA_SA:GENRL:BANK_138:SOUND_29` |
| `ui.nav_confirm` | `res://audio/ui/sfx_ui_nav_confirm.wav` | `GTA_SA:GENRL:BANK_143:SOUND_77` | 44100 Hz mono PCM16 / 2824 | `0c669ad54e911728ab16b883cc555df3067c50e29ddc2910734f4b0c93d2bf27` | `GTA_SA:GENRL:BANK_143:SOUND_55` |
| `ui.nav_back` | `res://audio/ui/sfx_ui_nav_back.wav` | `GTA_SA:GENRL:BANK_143:SOUND_44` | 18000 Hz mono PCM16 / 623 | `061b9cc26d1e6af092267fc0b949d2573c81b0d8a57dbdf772de6485539faab2` | `GTA_SA:GENRL:BANK_143:SOUND_34` |
| `ui.mode_switch` | `res://audio/ui/sfx_ui_mode_switch.wav` | `GTA_SA:GENRL:BANK_143:SOUND_17` | 23000 Hz mono PCM16 / 1999 | `1418770fc0089bf5e309c13c1efe0f275c967ae4dc5feb433b104b560d64263d` | `GTA_SA:GENRL:BANK_143:SOUND_18` |
| `ui.reject` | `res://audio/ui/sfx_ui_reject.wav` | `GTA_SA:GENRL:BANK_143:SOUND_4` | 22000 Hz mono PCM16 / 2143 | `04964bf39958d7a8489e05a177de7a36c466415b121524e3584043d01f0b09f5` | `GTA_SA:GENRL:BANK_143:SOUND_71` |
| `ui.radio_station_step` | `res://audio/ui/sfx_ui_radio_step.wav` | `GTA_SA:GENRL:BANK_143:SOUND_47` | 24000 Hz mono PCM16 / 2381 | `283cd247c21b3e3e6f05fab00d2aaf843bbbc87e6a8ba87569023894cc5e9d2f` | `GTA_SA:GENRL:BANK_143:SOUND_50` |
| `ui.replay_retry_confirm` | `res://audio/ui/sfx_ui_replay_retry_confirm.wav` | `GTA_SA:GENRL:BANK_143:SOUND_73` | 26000 Hz mono PCM16 / 2697 | `eaff3fbad94ab16329f976307d94b6220452f4933cca4d847d67ed68afdf3c02` | `GTA_SA:GENRL:BANK_143:SOUND_84` |

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

## Baseline runtime contract frozen at candidate stage

All seven slots must remain:

- `domain=UI`
- `diegesis=NON_DIEGETIC`
- `spatial_type=NON_DIEGETIC_2D`
- `mix_group=INCIDENTAL_UI`
- `playback_type=TRANSIENT`
- `asset_status=PROCEDURAL_FALLBACK`
- `replacement_required=true`

Existing cooldown, gain, max-concurrency, `critical_essential`, suppression, and reset behavior are frozen. `UIAudioIdentityLayer` remains the sole UI audio playback owner and `AudioManager.reset_audio_instant()` remains the authoritative voice-lifecycle reset.

The current independently reachable procedural fallback for each slot must remain intact during candidate selection. Local reference audio remains dev-only and may continue to resolve only under the existing fail-closed resolver policy.

## Candidate-stage media boundary

No production files may exist at the seven planned `res://audio/ui/` paths during this checkpoint. No `.import` sidecars, production paths, source provenance fields, or final-status promotion are authorized yet.

Source archive/candidate media remains local and gitignored. The project must not vendor GTA SA source archives or audition workfiles.

## Future production-ingestion constraints

A later explicitly authorized ingestion change may only:

1. add the seven locked winner WAVs at the canonical paths above;
2. add non-destructive Godot import sidecars;
3. promote only these seven UI semantic slots to project-internal `LICENSED_FINAL`, clear `replacement_required`, and record exact production path/provenance;
4. add the narrowest production-stream resolution seam in `UIAudioIdentityLayer` while retaining the exact procedural fallback independently;
5. fail closed against dev-local reference override once a slot is final;
6. preserve all existing cooldown, concurrency, gain, suppression, critical-essential, event hooks, manager registration, reset, and mix ownership.

No normalization, resampling, pitch shifting, time stretching, EQ, compression, reverb, layering, trimming, or fades are implied by this candidate lock. Any processing requires a new accepted production decision.

## Production verification requirements

When ingestion is later authorized, the production contract must verify for all seven assets:

- exact provenance and canonical path;
- exact native sample rate, mono PCM16 format, frame count, raw byte count, duration, and raw PCM SHA-256 from the selection lock;
- final repository WAV/container SHA-256 recorded separately after ingestion;
- non-looping playback and non-destructive import settings;
- final-slot local-reference fail-closed behavior;
- independently reachable procedural fallback per slot;
- unchanged cooldown/concurrency/gain/suppression/critical-essential policy;
- authoritative AudioManager reset removes all UI voices;
- existing `ui_audio_identity_contract_test.gd`, Audio Runtime 31, and canonical Web compatibility remain green.

Native listening on the exact production head must exercise rapid navigation repetition, confirm/back/reject semantic distinction, mode/radio switching, replay/retry confirmation, small-speaker/headphone readability, pursuit pressure suppression, Memory Echo suppression/recovery, and reset/replay behavior.

## Candidate-selection checkpoint PASS criteria

This checkpoint passes when:

- all seven winner and runner-up identities are locked in an executable selection lock;
- the candidate contract proves the exact target set and source metadata;
- the UI registry remains fallback-only with production media absent;
- procedural fallbacks remain independently reachable;
- Audio Runtime 31 and canonical Web compatibility are green on the exact PR head;
- fresh Standards and Spec review have no material findings.

The next workflow state after this checkpoint is **production ingestion authorization**, not automatic media ingestion.
