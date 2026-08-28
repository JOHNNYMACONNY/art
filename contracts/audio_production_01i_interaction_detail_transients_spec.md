# Audio Production 01I — Interaction Detail Transients Pack

**State:** RETENTION_PASS__RUNTIME_AUTHORITY_GATED  
**Baseline:** `main@ca7f9643150ade9e83c7cdd47684d8f2ddde59ee`

## Objective

Batch candidate search and perceptual identity work for three reserved interaction-detail slots:

1. `interaction.panel_pry` — initial crowbar leverage / corroded metal stress;
2. `interaction.wire_clip` — precision wire-cutter snip / mechanical clip;
3. `interaction.battery_insert` — solid power-cell insertion / bay lock.

01I is intentionally authority-gated. Human candidate audition is complete, but production promotion remains unauthorized until each slot has a real gameplay event and timing point. No placeholder mechanic may be invented solely to justify using an audio asset.

## Runtime authority findings on baseline main

### `interaction.panel_pry` — not live

Registry intent remains DIEGETIC / DIEGETIC_3D / TRANSIENT / replacement-required.

Actual gameplay authority:

- `CorrodedPanel` has no separate pry state or pry audio event;
- active sequence is `IDLE -> APPROACHED -> PEELING -> EXPOSED -> EXTRACTED`;
- `trigger_action()` immediately enters `PEELING` and emits `PANEL_PEEL`;
- no `PANEL_PRY` `SoundEvent` exists in `AudioManager`;
- no `EVENT_TO_SLOT_MAP` entry maps to `interaction.panel_pry`;
- no procedural fallback branch exists for a pry event.

Production disposition: **RETENTION ONLY** until a real pry interaction step exists.

### `interaction.wire_clip` — not live

Registry intent remains DIEGETIC / DIEGETIC_3D / TRANSIENT / replacement-required.

Actual gameplay authority:

- current extraction flow exposes core and completes extraction without a separate wire-cut state;
- current completion path emits existing `COMPLETION` and `SPARK` semantics;
- no `WIRE_CLIP` `SoundEvent` exists in `AudioManager`;
- no `EVENT_TO_SLOT_MAP` entry maps to `interaction.wire_clip`;
- no procedural wire-clip branch exists.

Production disposition: **RETENTION ONLY** until a real wire-cut interaction step exists.

### `interaction.battery_insert` — not live

Registry intent remains DIEGETIC / DIEGETIC_3D / TRANSIENT / replacement-required.

Actual gameplay authority:

- current interaction tree contains no power-cell insertion mechanic;
- no battery-insert gameplay signal is emitted;
- no `BATTERY_INSERT` `SoundEvent` exists in `AudioManager`;
- no `EVENT_TO_SLOT_MAP` entry maps to `interaction.battery_insert`;
- no procedural battery-insert branch exists.

Production disposition: **RETENTION ONLY** until a real battery-insertion mechanic exists.

## 01E historical retained incumbents

Historical repository evidence remains preserved:

### Panel Pry

- source: `GTA_SA:GENRL:BANK_143:SOUND_40`;
- duration: `0.1547 s`;
- native sample rate: `22,050 Hz`;
- mono 16-bit PCM;
- raw SHA-256: `3205a8aa7708517f6b036dfa89b66def9c4cf997efae790675e4657024b56127`.

### Wire Clip

- source: `GTA_SA:GENRL:BANK_143:SOUND_48`;
- duration: `0.0751 s`;
- native sample rate: `22,050 Hz`;
- mono 16-bit PCM;
- raw SHA-256: `c98b758a7463f8667be351cf9a16181e1c04b5ea0a57b9a20aa25345c62846e9`.

### Battery Insert

- source: `GTA_SA:GENRL:BANK_100:SOUND_0`;
- duration: `0.3132 s`;
- native sample rate: `17,968 Hz`;
- mono 16-bit PCM;
- raw SHA-256: `0668e15e846ce1cae9e2b77fc5955219bb5393745385ecfe84721a7d31682db6`.

## 01I human-audition outcome

Candidate audition completed on exact opening head `f8d8822db55819cc8a0b26a5d167e031973588d5` with clean Git status and extraction integrity PASS.

### Panel Pry — incumbent confirmed

Selected source:

`GTA_SA:GENRL:BANK_143:SOUND_40`

Characteristics:

- duration: `0.1547 s`;
- native sample rate: `22,050 Hz`;
- mono 16-bit PCM;
- raw bytes: `6,868`;
- raw SHA-256: `3205a8aa7708517f6b036dfa89b66def9c4cf997efae790675e4657024b56127`.

Perceptual identity:

- crisp initial metal pry strain / crowbar leverage bite;
- reads as the first resistance-breaking action rather than sustained removal;
- remains clearly distinct from production `interaction.panel_peel` (`GTA_SA:GENRL:BANK_76:SOUND_1`) because pry is the sharp leverage onset while peel is the prolonged shearing groan;
- strong small-speaker readability.

Disposition: **RETENTION WINNER — INCUMBENT CONFIRMED**.

### Wire Clip — new 01I winner

Selected source:

`GTA_SA:GENRL:BANK_143:SOUND_29`

Characteristics:

- duration: `0.0431 s`;
- native sample rate: `26,400 Hz`;
- mono 16-bit PCM;
- raw bytes: `2,320`;
- raw SHA-256: `d7c6b8a4de4dc497ffc43bd8ef17b4568f434ce965ba951131aedb48fecbaf77`.

Perceptual identity:

- ultra-short mechanical cutter snip / metallic shear click;
- dry tool action rather than electrical discharge;
- distinct from production `interaction.wire_spark` (`GTA_SA:GENRL:BANK_143:SOUND_26`).

Disposition: **RETENTION WINNER — NEW 01I SELECTION**.

Evidence caveat: the audition report's prose compared this winner against a different locally referenced “incumbent” source than the historical 01E repository incumbent (`BANK_143:SOUND_48`). The final 01I winner selection is authoritative human evidence, but this spec does **not** claim a verified direct A/B superiority over the historical 01E source unless that exact comparison is rerun later.

### Battery Insert — new 01I winner

Selected source:

`GTA_SA:GENRL:BANK_143:SOUND_12`

Characteristics:

- duration: `0.1422 s`;
- native sample rate: `14,364 Hz`;
- mono 16-bit PCM;
- raw bytes: `4,130`;
- raw SHA-256: `b079fe9af2c9a0bc5ec6be180b5ee9a52d6774ee66fcc937eab832a056ea5288`.

Perceptual identity:

- tactile module insertion snap with a solid locking click;
- reads as contained cell seating/lock rather than rider hardware or a core release;
- distinct from Bike Mount/Dismount and `interaction.core_extracted`.

Disposition: **RETENTION WINNER — NEW 01I SELECTION**.

Evidence caveat: the audition report's prose compared this winner against a different locally referenced “incumbent” source than the historical 01E repository incumbent (`BANK_100:SOUND_0`). The final 01I winner selection is authoritative human evidence, but this spec does **not** claim a verified direct A/B superiority over the historical 01E source unless that exact comparison is rerun later.

## Three-way identity outcome

The retained winners form a clear intended mechanic family:

- Panel Pry = initial leverage/stress bite;
- Wire Clip = precise tool sever;
- Battery Insert = contained weighted insertion/lock.

No production asset is shipped from this retention checkpoint.

## Production boundary

01I does **not** authorize integration.

Until runtime authority exists, do not:

- add production WAVs under `godot/audio/interaction/`;
- add `.wav.import` files;
- promote registry status;
- add source provenance or production paths to these slots;
- add `SoundEvent` values;
- add AudioManager mappings or playback branches;
- add fake pry/wire/battery mechanics;
- alter the current Corroded Panel sequence.

## Completion

01I is complete as a **RETENTION PASS** when the three selected sources are recorded in repository retention evidence and review confirms that no production/runtime promotion occurred.
