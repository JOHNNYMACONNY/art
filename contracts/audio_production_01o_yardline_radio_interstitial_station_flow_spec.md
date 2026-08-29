# Audio Production 01O — Yardline Radio Interstitial & Station Flow Pack

**State:** SOURCES_SELECTED__PRODUCTION_INGESTION_NOT_YET_AUTHORIZED  
**Baseline:** `main@591ed118d1ac39dfd2eb747898d55b7fd63f5775`

## Intent

Lock six remaining procedural-fallback Yardline Radio interstitial and station-flow slots. The six targets are transient/non-looping, domain `RADIO`, mix group `RADIO_MUSIC`, max concurrency 1. They must function as a coherent station flow sequence — intro opener → content → outro hand-off — while the two adverts remain mutually distinct and the two world-event bulletins communicate urgency differences without colliding perceptually with gameplay threat cues.

Human candidate audition is complete. The six winners below are locked. No production WAV ingestion or registry path promotion is authorized at this stage.

## Locked target set

Exactly these six slots are in scope:

| Slot | Planned production path | Locked winner | Format / frames | Container File SHA-256 | Raw PCM SHA-256 | Runner-up |
| --- | --- | --- | --- | --- | --- | --- |
| `radio.yardline.dj_link_intro` | `res://audio/radio/rad_yardline_dj_link_intro.wav` | `GTA_SA:GENRL:BANK_84:SOUND_0` | 11025 Hz mono PCM16 / 54096 | `a57fdf9505a477e1481862a2cb39e30ad8bd128e3571aee3a1db699fbe8fb932` | `8d1b2f2d7f6fdef285619f5092642dfff17fd85b7d1b2091ad546e865c35b526` | `GTA_SA:GENRL:BANK_65:SOUND_0` |
| `radio.yardline.dj_link_outro` | `res://audio/radio/rad_yardline_dj_link_outro.wav` | `GTA_SA:GENRL:BANK_84:SOUND_1` | 11025 Hz mono PCM16 / 30855 | `441127de705099889ef45a489f2362f3f9306467a4a6afdf26e53b50ce21690b` | `8aae0b29afb325f841a404fd8925ce1e9cd58510dd1eada70d13fd0c3290b0f0` | `GTA_SA:GENRL:BANK_130:SOUND_0` |
| `radio.yardline.advert_01` | `res://audio/radio/rad_yardline_advert_01.wav` | `GTA_SA:GENRL:BANK_82:SOUND_0` | 28000 Hz mono PCM16 / 277088 | `b1117029ce70e68e113416837790952cb34ed8ca2d9bc708306cc750e11c47f9` | `e4d4d6da12ce7672ba48e55f3313fad7996d4fcf151d3021b19d666cb731dd1c` | `GTA_SA:GENRL:BANK_82:SOUND_2` |
| `radio.yardline.advert_02` | `res://audio/radio/rad_yardline_advert_02.wav` | `GTA_SA:GENRL:BANK_82:SOUND_4` | 28000 Hz mono PCM16 / 277116 | `4d81f826a4ee7822139edcf29dbc3533395b9fa944add9c0f47f01a47c32d747` | `2d3b2a11053b8aa57903d88a5bba0362e527712ac60f5024dfd1baf990084063` | `GTA_SA:GENRL:BANK_82:SOUND_6` |
| `radio.yardline.world_pursuit` | `res://audio/radio/rad_yardline_world_pursuit.wav` | `GTA_SA:GENRL:BANK_91:SOUND_0` | 18000 Hz mono PCM16 / 17303 | `99a7acb0437ba59c22a645f6563201f57b44a6fd636b6fd2853754e0cec6831d` | `30384854c45363f4bd599ddecb65f7bbaf8df4a975319a7e44f5e12847f0cfc4` | `GTA_SA:GENRL:BANK_81:SOUND_0` |
| `radio.yardline.world_gate` | `res://audio/radio/rad_yardline_world_gate.wav` | `GTA_SA:GENRL:BANK_91:SOUND_1` | 18000 Hz mono PCM16 / 58550 | `43bb8e9092381dbc49e0d8538b2926d2b9116e2d5b1bdbd8e15a7f21c20e85a0` | `3b2069e92b5c5bac4722550e62054094eaf7d34e022858985e10a3ce5f08f8ee` | `GTA_SA:GENRL:BANK_115:SOUND_1` |

The executable source of truth for exact winner/runner-up metadata is `res://tests/yardline_radio_interstitial_selection_lock.gd`.

## Audition decision record

- `radio.yardline.dj_link_intro`: 4.9s musical station opener at 11025Hz; establishes station continuity without duplicating the station IDs; distinct from BANK_65 runner-up in cadence and entry character.
- `radio.yardline.dj_link_outro`: 2.8s exit tag from same BANK_84 family as intro; paired acoustic identity ensures coherent station flow handoff.
- `radio.yardline.advert_01`: 9.9s 28kHz voice-over spot; loudest of BANK_82 group (peak -0.8dB) giving it clear assertive broadcast character for primary advert slot.
- `radio.yardline.advert_02`: 9.9s 28kHz voice-over spot (SOUND_4); clearly distinct voice/content texture from SOUND_0 ensuring pair mutual recognizability; SOUND_6 runner-up retained as audition history.
- `radio.yardline.world_pursuit`: 0.96s urgent 18kHz stinger (BANK_91 SOUND_0); peak -0.5dB, short burst — urgency without confusion with gameplay siren.
- `radio.yardline.world_gate`: 3.25s lower-urgency 18kHz bulletin (BANK_91 SOUND_1); distinctly longer and softer than world_pursuit, communicating perimeter-activity versus active-pursuit semantic.

The six winners are locked. Runner-ups are retained only as provenance/audition history and must not be substituted without a new accepted source-selection decision.

## Frozen invariants at candidate-selection stage

- All six registry entries remain `PROCEDURAL_FALLBACK` / `replacement_required=true`.
- No WAV or `.import` files are committed at this stage.
- No production paths or provenance added to AudioRegistry.
- No playback behavior or radio sequencing changes.
- Runner-ups are audition evidence only; cannot silently substitute for winners.
- Current fallback generation remains independently reachable.
- Native formats retained without normalization, resampling, trimming, EQ, compression, pitch/time modification, or fades.
- Production ingestion (WAV commit + registry promotion) requires explicit authorization after this spec is reviewed.

## Runtime contract to be promoted at media stage

Six slots will transition from `PROCEDURAL_FALLBACK` -> `LICENSED_FINAL` exactly. All other 43 slots remain unchanged. Radio sequencing, director logic, volume policy, concurrency limit (max 1), and fallback architecture remain unmodified.
