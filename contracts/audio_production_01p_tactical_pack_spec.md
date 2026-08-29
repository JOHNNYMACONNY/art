# Audio Production 01P — Interaction, Pursuit & World Tactical Pack

**State:** SOURCES_SELECTED__PRODUCTION_INGESTION_NOT_YET_AUTHORIZED  
**Baseline:** `main@0c1d189f862deb9fb2c7236d74249f9bc5387982`

## Intent

Lock five remaining procedural-fallback tactical audio slots spanning player object interaction, pursuer scanning, and ambient radio dispatch chatter:
- `interaction.panel_pry`: Transient mechanical strain and crack as corroded junction panel is forced open.
- `interaction.wire_clip`: Transient sharp cutter snip as bypass wire is snipped.
- `interaction.battery_insert`: Transient heavy mechanical seat and latch as power cell locks into junction slot.
- `pursuit.pursuer_sweep`: Threat radar scanner sweep loop tracking player proximity.
- `world.radio_chatter`: Transient corrupted courier radio transmission / dispatch burst.

Human candidate audition is complete. The five winners below are locked. No production WAV ingestion or registry path promotion is authorized at this stage.

## Locked target set

Exactly these five slots are in scope:

| Slot | Planned production path | Locked winner | Format / frames | Container File SHA-256 | Raw PCM SHA-256 | Runner-up |
| --- | --- | --- | --- | --- | --- | --- |
| `interaction.panel_pry` | `res://audio/interaction/sfx_interaction_panel_pry.wav` | `GTA_SA:GENRL:BANK_76:SOUND_2` | 18000 Hz mono PCM16 / 17463 | `dbe6ee0c8eb57018e4b43ad2ebb40602bce45e21a3592061a0800c2a76f4a13b` | `2b39bb47f1da6a037c3ddd9c16f07f3e1a657a2e7d7ea4937cb8d5ac62277fc8` | `GTA_SA:GENRL:BANK_68:SOUND_1` |
| `interaction.wire_clip` | `res://audio/interaction/sfx_interaction_wire_clip.wav` | `GTA_SA:GENRL:BANK_143:SOUND_17` | 23000 Hz mono PCM16 / 1999 | `8957d4026569878f41d08ff1bcfa63906214d4c5701c083646841935d034d50b` | `1418770fc0089bf5e309c13c1efe0f275c967ae4dc5feb433b104b560d64263d` | `GTA_SA:GENRL:BANK_143:SOUND_18` |
| `interaction.battery_insert` | `res://audio/interaction/sfx_interaction_battery_insert.wav` | `GTA_SA:GENRL:BANK_45:SOUND_1` | 18000 Hz mono PCM16 / 13804 | `ff79a2e2810579ce890cd1af208dcd48f38be5cf5212423d099211b380e79f1d` | `495f76eaab687d1036d7424138c400724ec1a629c2cdfff5df931697bebd49ca` | `GTA_SA:GENRL:BANK_44:SOUND_0` |
| `pursuit.pursuer_sweep` | `res://audio/pursuit/loop_pursuit_scanner_sweep.wav` | `GTA_SA:GENRL:BANK_138:SOUND_43` | 20900 Hz mono PCM16 / 8041 | `46a40bebd9f3b390863dc4e1c472bd4cf14800b46f510539696c2ed796312093` | `5e4808d31142881192f1273dfef7cb304a694bb597c9e2fac6afc6d56edb4d80` | `GTA_SA:GENRL:BANK_138:SOUND_44` |
| `world.radio_chatter` | `res://audio/world/sfx_world_radio_chatter.wav` | `GTA_SA:SCRIPT:BANK_356:SOUND_16` | 15000 Hz mono PCM16 / 9909 | `93358b3a23f17aeefdc8b5d10f4608e4c7f2c1fa507564d12bb32688ca147b49` | `621aa1348b7d2e9bcdf40d10658e97b456ef594c925e983102a83342e5cc3c0b` | `GTA_SA:SCRIPT:BANK_356:SOUND_1` |

The executable source of truth for exact winner/runner-up metadata is `res://tests/tactical_pack_selection_lock.gd`.

## Audition decision record

- `interaction.panel_pry`: 0.97s 18kHz metal strain and groaning pry crack from BANK_76; shares acoustic material signature with `interaction.panel_peel` (`BANK_76:SOUND_1`) ensuring tactile coherence.
- `interaction.wire_clip`: 0.087s 23kHz sharp cutter snip; distinct, high-clarity transient without mud or post-ring.
- `interaction.battery_insert`: 0.77s 18kHz solid mechanical relay/seating click; conveys physical mass and solid electrical locking.
- `pursuit.pursuer_sweep`: 0.38s 20.9kHz electronic scanner sweep tone; matches candidate evidence from retention ledger (`GENRL:BANK_138:SOUND_43`); gives distinct rhythmic threat scanning pulse.
- `world.radio_chatter`: 0.66s 15kHz transmission burst; concise distorted dispatch squelch that conveys ambient radio communication without masking gameplay audio cues.

The five winners are locked. Runner-ups are retained only as provenance/audition history and must not be substituted without a new accepted source-selection decision.

## Frozen invariants at candidate-selection stage

- All five registry entries remain `PROCEDURAL_FALLBACK` / `replacement_required=true`.
- No WAV or `.import` files are committed at this stage.
- No production paths or provenance added to AudioRegistry.
- No playback behavior or spatial routing changes.
- Runner-ups are audition evidence only; cannot silently substitute for winners.
- Current fallback generation remains independently reachable.
- Native formats retained without normalization, resampling, trimming, EQ, compression, pitch/time modification, or fades.
- Production ingestion (WAV commit + registry promotion) requires explicit authorization after this spec is reviewed.

## Runtime contract to be promoted at media stage

Five slots will transition from `PROCEDURAL_FALLBACK` -> `LICENSED_FINAL` exactly. All other 44 slots remain unchanged. Interaction mechanics, pursuer scanning loops, ambient chatter timers, volume policy, and fallback architecture remain unmodified.
