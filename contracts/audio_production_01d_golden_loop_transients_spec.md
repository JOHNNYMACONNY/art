# Audio Production 01D — Golden Loop Transients Pack

**State:** CANDIDATE_SELECTION_REQUIRED  
**Baseline:** `main@651b9fe7b6a45f1fc049c467b43a5b3c2450ba0b`

## Objective

Replace six already-live short 3D procedural sounds in one production-audio batch using owner-authorized GTA San Andreas source audio. Preserve all gameplay timing, event routing, spatial positions, voice budgets, and procedural fallbacks.

This batch exists to accelerate production-audio replacement. It must complete as one audition session, one integration branch, one exact-head verification pass, one human in-game listening pass, and one PR/review/merge cycle.

## Batch targets

| Runtime event | Semantic slot | Canonical production path |
| --- | --- | --- |
| `PANEL_PEEL` | `interaction.panel_peel` | `res://audio/interaction/sfx_interaction_panel_peel.wav` |
| `SPARK` | `interaction.wire_spark` | `res://audio/interaction/sfx_interaction_wire_spark.wav` |
| `COMPLETION` | `interaction.core_extracted` | `res://audio/interaction/sfx_interaction_core_extracted.wav` |
| `BIKE_MOUNT` | `player.bike_mount` | `res://audio/player/sfx_player_bike_mount.wav` |
| `BIKE_DISMOUNT` | `player.bike_dismount` | `res://audio/player/sfx_player_bike_dismount.wav` |
| `BRAKE_SCREECH` | `vehicle.brake_screech` | `res://audio/vehicle/sfx_vehicle_brake_screech.wav` |

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

Every selected asset must record exact identity:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Only the six selected production assets may enter the repository. GTA archive containers, rejected candidates, and audition copies remain local/ignored.

## Candidate listening targets

### Panel peel — `interaction.panel_peel`
- corroded metal stress / peel / shear;
- tactile, not a huge crash;
- should support the existing peel gesture without dictating a new animation length;
- approximately 0.20–1.20 s preferred.

### Wire spark — `interaction.wire_spark`
- compact electrical crack/spark;
- bright enough to read, not gunshot-like;
- low fatigue when paired with extraction FX;
- approximately 0.05–0.45 s preferred.

### Core extracted — `interaction.core_extracted`
- mechanical/pneumatic release or lock disengage;
- satisfying completion identity without becoming a musical victory sting;
- approximately 0.15–0.90 s preferred.

### Bike mount — `player.bike_mount`
- chassis latch / seat / mechanism engagement;
- immediate confirmation, compact and physical;
- approximately 0.05–0.50 s preferred.

### Bike dismount — `player.bike_dismount`
- related but distinguishable release/unlatch action;
- should pair naturally with mount without sounding identical;
- approximately 0.05–0.50 s preferred.

### Brake screech — `vehicle.brake_screech`
- pneumatic/disc/tire friction appropriate to the courier bike;
- readable under engine feedback without harsh repeated fatigue;
- approximately 0.15–1.20 s preferred;
- avoid long uncontrollable loops in this transient batch.

Duration ranges are shortlist guidance only. Do not time-stretch a bad source to fit them.

## Production asset contract

Each selected production WAV must:

- be mono `AudioStreamWAV` suitable for `AudioStreamPlayer3D`;
- use 16-bit PCM;
- retain native source sample rate unless a concrete playback defect requires resampling;
- retain natural envelope with only minimal boundary taper/gain treatment justified by listening;
- avoid baked reverb, speculative EQ, normalization, time stretching, or compression unless the exact candidate has a demonstrated defect requiring it;
- be imported with non-destructive Godot settings and `compress/mode=0` unless a specific asset requires a different verified setting.

`AudioRegistry` owns production path and source provenance. `AudioManager` must not duplicate production asset paths as independent constants.

## Runtime contract

1. Map the six runtime events to their semantic slots exactly as listed above.
2. Resolve selected streams through `AudioRegistry`.
3. Production playback remains `AudioStreamPlayer3D` at the exact position already supplied by gameplay.
4. Existing transient concurrency and cleanup ownership remain in `AudioManager`.
5. If any individual production stream is missing/unavailable, only that event falls back to its previous procedural synthesis.
6. One missing asset must not disable the other five production streams.
7. Do not change procedural synthesis parameters except to route them behind fallback helpers.
8. Do not migrate another semantic slot in 01D.

## Automated verification

Exact-head verification must prove for all six targets:

- canonical semantic mapping;
- production path and exact GTA provenance;
- asset exists and loads as mono 16-bit `AudioStreamWAV`;
- expected source sample rate/duration once selection is locked;
- production stream resolves through registry;
- event creates a bounded 3D transient at an arbitrary supplied test position;
- per-event procedural fallback remains independently reachable;
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
