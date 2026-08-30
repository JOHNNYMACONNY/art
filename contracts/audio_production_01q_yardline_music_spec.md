# Audio Production 01Q — Yardline Radio Music Track Pack

**State:** PRODUCTION_MEDIA_INGESTED__LICENSED_FINAL_PROMOTED  
**Baseline:** `main@4fa7029d2d0ec72581ac62f5630dd8346a4c9563`

## Intent

Complete the final Yardline radio music production slice by promoting all six previously locked music track segment slots across the four authored songs on YARDLINE 88.3:
- `radio.yardline.song_01.intro`: High-energy snare/kick pickup and beat kickoff for "Scrap Pulse".
- `radio.yardline.song_01.body`: Core driving electronic techno beat groove for "Scrap Pulse".
- `radio.yardline.song_01.outro`: Rhythmic decay and tail resolve for "Scrap Pulse".
- `radio.yardline.song_02.body`: Driving electro synth groove for "Neon Drift".
- `radio.yardline.song_03.body`: Gritty midtempo industrial bass groove for "Rust Groove".
- `radio.yardline.song_04.body`: Resonant broken electro / tech rhythm for "Signal Loss".

Human candidate audition and source selection are complete. The six collision-free winners below are locked and production ingestion is authorized and complete. Their WAV files and non-destructive `.import` sidecars are committed at the locked production paths, and all six registry slots are promoted to `LICENSED_FINAL` with `replacement_required=false`.

## Locked and promoted target set

Exactly these six slots are in scope:

| Slot | Production path | Locked winner | Format / frames | Container File SHA-256 | Raw PCM SHA-256 | Runner-up |
| --- | --- | --- | --- | --- | --- | --- |
| `radio.yardline.song_01.intro` | `res://audio/radio/yardline/music/sfx_radio_song01_intro.wav` | `GTA_SA:GENRL:BANK_81:SOUND_2` | 18000 Hz mono PCM16 / 15393 | `463d61099f4210a4472f349b08e9f2b1d11d03a57860c45cbb2215b1ceb93d4a` | `7148e41f97a8306476ac33309a7f9b772be1365b60ad3955fadb17d85dfc7e2d` | `GTA_SA:GENRL:BANK_85:SOUND_3` |
| `radio.yardline.song_01.body` | `res://audio/radio/yardline/music/sfx_radio_song01_body.wav` | `GTA_SA:GENRL:BANK_81:SOUND_0` | 18000 Hz mono PCM16 / 49756 | `0c4b46c7ce33871bf55aa120605f1a07a64752eb9f4ae3e9dec109e210b544cb` | `45eac308b2f4482581be0a2b7b92fe032a4a6d051786ac6df638fbef2d3312e6` | `GTA_SA:GENRL:BANK_73:SOUND_0` |
| `radio.yardline.song_01.outro` | `res://audio/radio/yardline/music/sfx_radio_song01_outro.wav` | `GTA_SA:GENRL:BANK_81:SOUND_1` | 18000 Hz mono PCM16 / 28699 | `71871186feaf1c379fc05ad6c68e0fd9d818fef54e521c3ad0bb7c65dc8f0ecc` | `c52ce1a17a7287ba85aa246830bbb632483c623f7077284d2cfdf8f8bb04f345` | `GTA_SA:GENRL:BANK_87:SOUND_1` |
| `radio.yardline.song_02.body` | `res://audio/radio/yardline/music/sfx_radio_song02_body.wav` | `GTA_SA:GENRL:BANK_87:SOUND_0` | 18000 Hz mono PCM16 / 70756 | `9983f5a3fc405249cbd4c8869ab07e20e800ef8f583ccee2c56fb0d03983a2d5` | `ae4890dcbd4107b0d831c146dbeacb6b31d5a0c65436f9dc00079db9bab0ee72` | `GTA_SA:GENRL:BANK_103:SOUND_0` |
| `radio.yardline.song_03.body` | `res://audio/radio/yardline/music/sfx_radio_song03_body.wav` | `GTA_SA:GENRL:BANK_89:SOUND_0` | 18000 Hz mono PCM16 / 50596 | `ae362bb8ed4532df469790ad91578a8e9f5efb625e2a3a2939b5a8a297d95708` | `856218a9fa55c79faedafc9a64c505ff09a5796147b67d5df2d972dd06541690` | `GTA_SA:GENRL:BANK_123:SOUND_1` |
| `radio.yardline.song_04.body` | `res://audio/radio/yardline/music/sfx_radio_song04_body.wav` | `GTA_SA:GENRL:BANK_99:SOUND_0` | 18000 Hz mono PCM16 / 54852 | `03256ce856bafbfdfdfb742993c82cf34d8e99b48363a9b154e8d44c955f08b1` | `50f51523c7066d3497dcbe86b8f505976b4b2f005dc208983f61b75c9b906d64` | `GTA_SA:GENRL:BANK_95:SOUND_0` |

The executable source of truth for exact winner/runner-up metadata is `res://tests/yardline_music_selection_lock.gd`. Runner-ups remain provenance/audition history only and are not production substitutes.

## Production completion invariants

- All six 01Q registry entries are `LICENSED_FINAL` with `replacement_required=false`.
- Each slot exposes exactly the locked `production_asset_path` and `source_provenance`.
- The committed WAV container SHA-256 and raw PCM SHA-256 match the accepted selection lock exactly.
- Loaded production streams remain native 18000 Hz mono PCM16 with the exact locked frame counts, byte counts, and durations.
- `.import` sidecars are non-destructive: no 8-bit conversion, forced mono, max-rate resampling, trimming, normalization, loop editing, or compression.
- `LICENSED_FINAL` slots reject local reference overrides; procedural synthesis remains available as the independent fallback path when production resolution fails.
- The six production winners remain collision-free by provenance and raw PCM identity against one another and the 43 previously promoted production assets.
- Radio program rotation, finished-signal phase transitions, pause/resume state, ducking policies, and catalog sequencing remain unchanged.
- The combined semantic audio catalog is now 49/49 `LICENSED_FINAL`; the replacement backlog is empty.

## Verification contract

`res://tests/yardline_music_audio_production_contract.gd` is the media-stage executable guard. It must verify:
- exact six-slot agreement with `res://tests/yardline_music_selection_lock.gd`;
- 49 combined semantic slots, all 49 `LICENSED_FINAL`, zero `PROCEDURAL_FALLBACK`, and an empty replacement backlog;
- exact registry path/provenance and fail-closed local-reference policy for every 01Q slot;
- production WAV existence, container/raw PCM hashes, native stream format, exact sample rate/frame/byte/duration identity, and non-destructive import settings.

`res://tests/audio_runtime_output_contract_test.gd` must execute the 01Q production contract as part of Audio Runtime 31. Legacy registry, radio-director, and vehicle-radio suites must remain green with the 49/49 production-final state.
