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

Human candidate audition is complete. The six winners below are locked. No production WAV ingestion or registry path promotion is authorized at this stage.

## Locked target set

Exactly these six slots are in scope:

| Slot | Planned production path | Locked winner | Format / frames | Container File SHA-256 | Raw PCM SHA-256 | Runner-up |
| --- | --- | --- | --- | --- | --- | --- |
| `radio.yardline.song_01.intro` | `res://audio/radio/yardline/music/sfx_radio_song01_intro.wav` | `GTA_SA:GENRL:BANK_81:SOUND_2` | 18000 Hz mono PCM16 / 15393 | `463d61099f4210a4472f349b08e9f2b1d11d03a57860c45cbb2215b1ceb93d4a` | `7148e41f97a8306476ac33309a7f9b772be1365b60ad3955fadb17d85dfc7e2d` | `GTA_SA:GENRL:BANK_85:SOUND_3` |
| `radio.yardline.song_01.body` | `res://audio/radio/yardline/music/sfx_radio_song01_body.wav` | `GTA_SA:GENRL:BANK_82:SOUND_0` | 28000 Hz mono PCM16 / 277088 | `b1117029ce70e68e113416837790952cb34ed8ca2d9bc708306cc750e11c47f9` | `e4d4d6da12ce7672ba48e55f3313fad7996d4fcf151d3021b19d666cb731dd1c` | `GTA_SA:GENRL:BANK_81:SOUND_0` |
| `radio.yardline.song_01.outro` | `res://audio/radio/yardline/music/sfx_radio_song01_outro.wav` | `GTA_SA:GENRL:BANK_81:SOUND_1` | 18000 Hz mono PCM16 / 28699 | `71871186feaf1c379fc05ad6c68e0fd9d818fef54e521c3ad0bb7c65dc8f0ecc` | `c52ce1a17a7287ba85aa246830bbb632483c623f7077284d2cfdf8f8bb04f345` | `GTA_SA:GENRL:BANK_87:SOUND_1` |
| `radio.yardline.song_02.body` | `res://audio/radio/yardline/music/sfx_radio_song02_body.wav` | `GTA_SA:GENRL:BANK_82:SOUND_2` | 28000 Hz mono PCM16 / 277172 | `a20ad7c0899a485854e2dfb2e08190f6260349acb31044810a5bdae9ab723dd9` | `b0e33ae7a1afd10eb437b5663c08b69c058b06b5062a2b91f22b28c05743fd87` | `GTA_SA:GENRL:BANK_87:SOUND_0` |
| `radio.yardline.song_03.body` | `res://audio/radio/yardline/music/sfx_radio_song03_body.wav` | `GTA_SA:GENRL:BANK_82:SOUND_4` | 28000 Hz mono PCM16 / 277116 | `4d81f826a4ee7822139edcf29dbc3533395b9fa944add9c0f47f01a47c32d747` | `2d3b2a11053b8aa57903d88a5bba0362e527712ac60f5024dfd1baf990084063` | `GTA_SA:GENRL:BANK_89:SOUND_0` |
| `radio.yardline.song_04.body` | `res://audio/radio/yardline/music/sfx_radio_song04_body.wav` | `GTA_SA:GENRL:BANK_82:SOUND_6` | 28000 Hz mono PCM16 / 276724 | `a96386652a9d6013ec993a6571ada8ce89cef508b9f5a2010b77e4a5ae92d822` | `47c7020daa5169acde8cca103709581afcd9cd197e199acbb5a3536d338498ef` | `GTA_SA:GENRL:BANK_99:SOUND_0` |

The executable source of truth for exact winner/runner-up metadata is `res://tests/yardline_music_selection_lock.gd`.

## Audition decision record

- `radio.yardline.song_01.intro`: 0.8552s 18kHz pickup from BANK_81; sharp snare/kick roll that launches the 3-phase segmented track.
- `radio.yardline.song_01.body`: 9.8960s 28kHz driving electronic techno beat from BANK_82; deep sub kick and resonant perc loop that anchors "Scrap Pulse".
- `radio.yardline.song_01.outro`: 1.5944s 18kHz decay and filtering tail from BANK_81; resolves the 3-phase track smoothly before station interstitials or DJ links.
- `radio.yardline.song_02.body`: 9.8990s 28kHz electro synth track from BANK_82; driving arpeggiated bassline with high-energy top-end groove for "Neon Drift".
- `radio.yardline.song_03.body`: 9.8970s 28kHz gritty industrial bass groove from BANK_82; heavy low-slung breakbeat for "Rust Groove".
- `radio.yardline.song_04.body`: 9.8830s 28kHz resonant tech groove from BANK_82; syncopated glitch percussion for "Signal Loss".

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
