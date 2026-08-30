# Audio Production 01Q — Yardline Radio Music Track Pack

**State:** SOURCES_SELECTED__PRODUCTION_INGESTION_NOT_YET_AUTHORIZED  
**Baseline:** `main@9da2e880977f6ee49f1a2724add36532b8b769f7`

## Intent

Lock all six remaining procedural-fallback music track segment slots across the 4 authored songs on YARDLINE 88.3:
- `radio.yardline.song_01.intro`: High-energy snare/kick pickup and beat kickoff for "Scrap Pulse".
- `radio.yardline.song_01.body`: Core driving electronic techno beat groove for "Scrap Pulse".
- `radio.yardline.song_01.outro`: Rhythmic decay and tail resolve for "Scrap Pulse".
- `radio.yardline.song_02.body`: Driving electro synth groove for "Neon Drift".
- `radio.yardline.song_03.body`: Gritty midtempo industrial bass groove for "Rust Groove".
- `radio.yardline.song_04.body`: Resonant broken electro / tech rhythm for "Signal Loss".

Human candidate audition is complete. The six winners below are locked. All selections are strictly distinct from existing promoted station adverts and UI/SFX assets. No production WAV ingestion or registry path promotion is authorized at this stage.

## Locked target set

Exactly these six slots are in scope:

| Slot | Planned production path | Locked winner | Format / frames | Container File SHA-256 | Raw PCM SHA-256 | Runner-up |
| --- | --- | --- | --- | --- | --- | --- |
| `radio.yardline.song_01.intro` | `res://audio/radio/yardline/music/sfx_radio_song01_intro.wav` | `GTA_SA:GENRL:BANK_81:SOUND_2` | 18000 Hz mono PCM16 / 15393 | `463d61099f4210a4472f349b08e9f2b1d11d03a57860c45cbb2215b1ceb93d4a` | `7148e41f97a8306476ac33309a7f9b772be1365b60ad3955fadb17d85dfc7e2d` | `GTA_SA:GENRL:BANK_85:SOUND_3` |
| `radio.yardline.song_01.body` | `res://audio/radio/yardline/music/sfx_radio_song01_body.wav` | `GTA_SA:GENRL:BANK_81:SOUND_0` | 18000 Hz mono PCM16 / 49756 | `0c4b46c7ce33871bf55aa120605f1a07a64752eb9f4ae3e9dec109e210b544cb` | `45eac308b2f4482581be0a2b7b92fe032a4a6d051786ac6df638fbef2d3312e6` | `GTA_SA:GENRL:BANK_73:SOUND_0` |
| `radio.yardline.song_01.outro` | `res://audio/radio/yardline/music/sfx_radio_song01_outro.wav` | `GTA_SA:GENRL:BANK_81:SOUND_1` | 18000 Hz mono PCM16 / 28699 | `71871186feaf1c379fc05ad6c68e0fd9d818fef54e521c3ad0bb7c65dc8f0ecc` | `c52ce1a17a7287ba85aa246830bbb632483c623f7077284d2cfdf8f8bb04f345` | `GTA_SA:GENRL:BANK_87:SOUND_1` |
| `radio.yardline.song_02.body` | `res://audio/radio/yardline/music/sfx_radio_song02_body.wav` | `GTA_SA:GENRL:BANK_87:SOUND_0` | 18000 Hz mono PCM16 / 70756 | `9983f5a3fc405249cbd4c8869ab07e20e800ef8f583ccee2c56fb0d03983a2d5` | `ae4890dcbd4107b0d831c146dbeacb6b31d5a0c65436f9dc00079db9bab0ee72` | `GTA_SA:GENRL:BANK_103:SOUND_0` |
| `radio.yardline.song_03.body` | `res://audio/radio/yardline/music/sfx_radio_song03_body.wav` | `GTA_SA:GENRL:BANK_89:SOUND_0` | 18000 Hz mono PCM16 / 50596 | `ae362bb8ed4532df469790ad91578a8e9f5efb625e2a3a2939b5a8a297d95708` | `856218a9fa55c79faedafc9a64c505ff09a5796147b67d5df2d972dd06541690` | `GTA_SA:GENRL:BANK_123:SOUND_1` |
| `radio.yardline.song_04.body` | `res://audio/radio/yardline/music/sfx_radio_song04_body.wav` | `GTA_SA:GENRL:BANK_99:SOUND_0` | 18000 Hz mono PCM16 / 54852 | `03256ce856bafbfdfdfb742993c82cf34d8e99b48363a9b154e8d44c955f08b1` | `50f51523c7066d3497dcbe86b8f505976b4b2f005dc208983f61b75c9b906d64` | `GTA_SA:GENRL:BANK_95:SOUND_0` |

The executable source of truth for exact winner/runner-up metadata is `res://tests/yardline_music_selection_lock.gd`.

## Audition decision record

- `radio.yardline.song_01.intro`: 0.8552s 18kHz pickup from BANK_81; sharp snare/kick roll that launches the 3-phase segmented track.
- `radio.yardline.song_01.body`: 2.7642s 18kHz driving electronic techno beat from BANK_81; cohesive paired groove with intro/outro for "Scrap Pulse".
- `radio.yardline.song_01.outro`: 1.5944s 18kHz decay and filtering tail from BANK_81; resolves the 3-phase track smoothly before station interstitials or DJ links.
- `radio.yardline.song_02.body`: 3.9309s 18kHz electro synth track from BANK_87; driving arpeggiated bassline with high-energy top-end groove for "Neon Drift".
- `radio.yardline.song_03.body`: 2.8109s 18kHz gritty industrial bass groove from BANK_89; heavy low-slung breakbeat for "Rust Groove".
- `radio.yardline.song_04.body`: 3.0473s 18kHz resonant tech groove from BANK_99; syncopated glitch percussion for "Signal Loss".

The six winners are locked. Runner-ups are retained only as provenance/audition history and must not be substituted without a new accepted source-selection decision.

## Frozen invariants at candidate-selection stage

- All six registry entries remain `PROCEDURAL_FALLBACK` / `replacement_required=true`.
- No WAV or `.import` files are committed at this stage.
- No production paths or provenance added to AudioRegistry.
- No playback behavior or spatial routing changes.
- Runner-ups are audition evidence only; cannot silently substitute for winners.
- Current fallback generation remains independently reachable.
- Native formats retained without normalization, resampling, trimming, EQ, compression, pitch/time modification, or fades.
- Production ingestion (WAV commit + registry promotion) requires explicit authorization after this spec is reviewed.

## Runtime contract to be promoted at media stage

Six slots will transition from `PROCEDURAL_FALLBACK` -> `LICENSED_FINAL` exactly, bringing the semantic slot catalog to 100% (49/49) `LICENSED_FINAL`. All other 43 slots remain unchanged. Radio program rotation, finished-signal phase transitions, pause/resume state, ducking policies, and fallback synthesis remain unmodified.
