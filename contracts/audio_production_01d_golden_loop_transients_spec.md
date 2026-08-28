# Audio Production 01D — Golden Loop Transients Pack

**State:** SOURCES_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@651b9fe7b6a45f1fc049c467b43a5b3c2450ba0`

## Objective

Replace six already-live short 3D procedural sounds in one production-audio batch using owner-authorized GTA San Andreas source audio. Preserve all gameplay timing, event routing, spatial positions, voice budgets, and procedural fallbacks.

This batch exists to accelerate production-audio replacement. It must complete as one audition session, one integration branch, one exact-head verification pass, one human in-game listening pass, and one PR/review/merge cycle.

## Locked selections

| Runtime event | Semantic slot | GTA source | Native duration | Native rate | Canonical production path |
| --- | --- | --- | ---: | ---: | --- |
| `PANEL_PEEL` | `interaction.panel_peel` | `GTA_SA:GENRL:BANK_76:SOUND_1` | `0.6595 s` | `18,000 Hz` | `res://audio/interaction/sfx_interaction_panel_peel.wav` |
| `SPARK` | `interaction.wire_spark` | `GTA_SA:GENRL:BANK_143:SOUND_26` | `0.2631 s` | `24,000 Hz` | `res://audio/interaction/sfx_interaction_wire_spark.wav` |
| `COMPLETION` | `interaction.core_extracted` | `GTA_SA:SCRIPT:BANK_260:SOUND_0` | `0.6313 s` | `22,050 Hz` | `res://audio/interaction/sfx_interaction_core_extracted.wav` |
| `BIKE_MOUNT` | `player.bike_mount` | `GTA_SA:GENRL:BANK_143:SOUND_57` | `0.3443 s` | `18,000 Hz` | `res://audio/player/sfx_player_bike_mount.wav` |
| `BIKE_DISMOUNT` | `player.bike_dismount` | `GTA_SA:GENRL:BANK_143:SOUND_41` | `0.2115 s` | `22,050 Hz` | `res://audio/player/sfx_player_bike_dismount.wav` |
| `BRAKE_SCREECH` | `vehicle.brake_screech` | `GTA_SA:GENRL:BANK_143:SOUND_28` | `0.4540 s` | `28,000 Hz` | `res://audio/vehicle/sfx_vehicle_brake_screech.wav` |

All six selections passed direct human audition and five-pulse fatigue checks. No selected source requires gain change or resampling. Each production asset receives only the approved ~1.5 ms boundary taper and no other processing.

`COMPLETION` is intentionally mapped to `interaction.core_extracted`: `CorrodedPanel.complete_extraction()` emits `COMPLETION` at the actual final extraction step. `CORE_PULL` is emitted earlier when the core is merely exposed and remains procedural in 01D.

These six were chosen because each already has a live gameplay event and procedural 3D playback path. Do not add speculative event seams for currently-unused semantic slots in 01D.

## Existing behavior retained

- Corroded Panel extraction state/timing remains unchanged.
- Spark particles and completion sequencing remain unchanged.
- Bike mount/dismount authority and timing remain unchanged.
- Brake behavior/traction physics remain unchanged.
- Existing event world positions remain authoritative.
- Existing transient voice budget remains authoritative.
- Existing procedural synthesis for every target remains independently reachable as fallback.
- FB-13 and Signal Gate production audio remain unchanged.

## Source restriction and provenance

Use only the locally stored GTA San Andreas audio library already accepted for owner-authorized production-audio slices.

Only the six locked production assets may enter the repository. GTA archive containers, rejected candidates, and audition copies remain local/ignored.

## Listening rationale

### Panel peel — `interaction.panel_peel`
Selected `GENRL / Bank 76 / Sound 1`: rich mechanical friction and corroded metal shear without harsh high-frequency fatigue.

### Wire spark — `interaction.wire_spark`
Selected `GENRL / Bank 143 / Sound 26`: compact, crisp electrical arc discharge that reads as electrical rather than gunshot-like.

### Core extracted — `interaction.core_extracted`
Selected `SCRIPT / Bank 260 / Sound 0`: pneumatic seal release plus mechanical latch disengage, satisfying without becoming a musical victory cue.

### Bike mount — `player.bike_mount`
Selected `GENRL / Bank 143 / Sound 57`: heavy chassis weight shift and solid frame latch engagement.

### Bike dismount — `player.bike_dismount`
Selected `GENRL / Bank 143 / Sound 41`: fast unlatch/spring release that pairs with mount while remaining clearly distinct.

### Brake screech — `vehicle.brake_screech`
Selected `GENRL / Bank 143 / Sound 28`: compact disc/pad friction bite that reads as courier-bike braking rather than generic tire burnout.

## Production asset contract

Each selected production WAV must:

- derive from the exact source listed in the locked selection table;
- be mono `AudioStreamWAV` suitable for `AudioStreamPlayer3D`;
- use 16-bit PCM;
- preserve the exact native sample rate listed above;
- retain natural duration within ±0.01 s of the listed duration;
- receive no gain normalization, resampling, EQ, compression, reverb, or time stretching;
- use only the approved ~1.5 ms boundary taper;
- be imported with non-destructive Godot settings and `compress/mode=0`.

`AudioRegistry` owns production path and source provenance. `AudioManager` must not duplicate production asset paths as independent constants.

## Runtime contract

1. Map the six runtime events to their semantic slots exactly as listed above.
2. Resolve selected streams through `AudioRegistry`.
3. Production playback remains `AudioStreamPlayer3D` at the exact position already supplied by gameplay.
4. Preserve the existing per-event spatial unit scale: panel peel/brake `10`, spark/mount/dismount `8`, completion `12`.
5. Existing transient concurrency and cleanup ownership remain in `AudioManager`.
6. If any individual production stream is missing/unavailable, only that event falls back to its previous procedural synthesis.
7. One missing asset must not disable the other five production streams.
8. Do not change procedural synthesis parameters except to route them behind fallback behavior.
9. Do not migrate another semantic slot in 01D.

## Automated verification

Exact-head verification must prove for all six targets:

- canonical semantic mapping;
- exact production path and exact GTA provenance;
- asset exists and loads as mono 16-bit `AudioStreamWAV`;
- exact native sample rate and selected duration tolerance;
- production stream resolves through registry;
- event creates a bounded 3D transient at an arbitrary supplied test position;
- production voice preserves the event's existing spatial unit scale;
- per-event procedural fallback remains independently reachable;
- removing one cached production stream does not disable the other five;
- FB-13 and Signal Gate production contracts remain green;
- semantic slot manifest remains internally consistent;
- Audio Runtime regression remains green;
- panel extraction, mount/dismount, vehicle/brake, replay/reset, and repository-required compatibility suites remain green.

## Human in-game verification

One exact-head native play session should cover the whole batch instead of six separate verification sessions:

1. approach powered Corroded Panel;
2. trigger panel peel;
3. complete extraction and hear spark + core completion;
4. mount Courier Bike;
5. brake repeatedly at representative speeds;
6. dismount;
7. repeat representative interactions once or twice for fatigue/artifact checks.

Judge each sound for:

- correct asset actually heard rather than fallback;
- gameplay/visual synchronization;
- 3D localization;
- level relative to ambience and nearby effects;
- no clipping, boundary pop, wrong pitch/speed, truncation, or obvious extraction artifact;
- repetition fatigue;
- production version is materially preferable to its procedural fallback.

## Completion

01D reaches PASS only when all six selected GTA sources are integrated on one exact candidate head, automated verification is green, one exact-head native batch listening pass is green, fresh Standards/Spec review passes, the PR merges, and exact-main CI/playtest provenance is green.
