# Audio Production 01G — Impacts & Collisions Pack

**State:** SOURCES_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@289c15f33def99063b1658fe85e9c03c64edbd36`

## Objective

Replace three already-live physical-impact procedural transients in one production-audio batch using owner-authorized GTA San Andreas source audio:

1. `pursuit.intercepted_impact` / `AudioManager.SoundEvent.PURSUIT_INTERCEPTED`;
2. `vehicle.collision_glance` / `AudioManager.SoundEvent.COLLISION_GLANCE`;
3. `vehicle.collision_hard` / `AudioManager.SoundEvent.COLLISION_HEAD_ON`.

This batch mirrors the proven 01D workflow: one candidate search/audition session, one integration branch, one asset-ingestion pass, one exact-head automated verification pass, one native gameplay listening pass, and one PR/review/merge cycle.

Do not add a fourth audio slot, alter vehicle handling, change pursuit state logic, or redesign the audio framework.

## Locked selections

| Runtime event | Semantic slot | GTA source | Native duration | Native rate | Canonical production path |
| --- | --- | --- | ---: | ---: | --- |
| `PURSUIT_INTERCEPTED` | `pursuit.intercepted_impact` | `GTA_SA:GENRL:BANK_40:SOUND_1` | `0.5382 s` | `18,000 Hz` | `res://audio/pursuit/sfx_pursuit_intercepted_impact.wav` |
| `COLLISION_GLANCE` | `vehicle.collision_glance` | `GTA_SA:GENRL:BANK_51:SOUND_2` | `0.2846 s` | `18,900 Hz` | `res://audio/vehicle/sfx_vehicle_collision_glance.wav` |
| `COLLISION_HEAD_ON` | `vehicle.collision_hard` | `GTA_SA:GENRL:BANK_58:SOUND_2` | `0.5700 s` | `18,000 Hz` | `res://audio/vehicle/sfx_vehicle_collision_hard.wav` |

All three selections passed direct human audition and pairwise identity checks. No selected source requires gain change, resampling, EQ, compression, reverb, or time stretching. Each selected production source receives only the approved ~1.5 ms boundary taper.

Raw audition evidence:

- intercept raw SHA-256: `fa397ff477444218f522fe238e9b00a4d581f7b2ed998feb65520d914760918d`;
- glance raw SHA-256: `9e083cd761437322937eb4b9594270c4680a1ea1705db5565481a48df0acc77e`;
- hard raw SHA-256: `75c07d75cc878cb9a2360806f7e2035de9232636b4a3d7dbbcbfc75017f7fda4`.

Runner-ups remain audition evidence only and must not enter the production tree:

- intercept runner-up: `GENRL / Bank 88 / Sound 1`;
- glance runner-up: `GENRL / Bank 59 / Sound 14`;
- hard runner-up: `GENRL / Bank 58 / Sound 0`.

## Current runtime authority

All three targets are live and use bounded 3D transient playback at the world position supplied by gameplay.

### Pursuer intercepted impact

Current event branch:

- event: `PURSUIT_INTERCEPTED`;
- semantic slot: `pursuit.intercepted_impact`;
- procedural sound: `_play_synth_sweep(pos, 400.0, 100.0, 0.5, 0.7)`;
- existing synth spatial scale: `unit_size = 10.0`;
- registry: PURSUIT / DIEGETIC / DIEGETIC_3D / CRITICAL_THREAT / TRANSIENT / max concurrency 1;
- live side effects: cancel active pursuit-pressure decay and immediately set radio duck to `-24 dB` over `0.05 s`.

**Critical invariant:** production playback must not bypass the interception side effects. The current generic production-transient early return occurs before the `match` branch, so 01G implementation must move/preserve the interception side effects outside the fallback-only branch or otherwise guarantee they execute exactly once for both production and fallback playback.

### Vehicle collision glance

Current event:

- event: `COLLISION_GLANCE`;
- semantic slot: `vehicle.collision_glance`;
- procedural sound: `_play_synth_sweep(pos, 750.0, 350.0, 0.12, 0.35)`;
- existing synth spatial scale: `unit_size = 10.0`;
- registry: VEHICLE / DIEGETIC / DIEGETIC_3D / VEHICLE_FEEDBACK / TRANSIENT;
- event cooldown: `120 ms`;
- `on_collision_contact()` classifies glance when `head_on_ratio < 0.35` and impact speed is at least `1.0`;
- after event creation, `_apply_collision_output_gain()` applies energy-derived gain to the newly-created transient.

`COLLISION_GLANCE` is also an existing M21 dev-reference tracer event. Production promotion must not broaden or redesign that developer-only reference seam; canonical compatibility remains authoritative.

### Vehicle collision hard

Current event:

- event: `COLLISION_HEAD_ON`;
- semantic slot: `vehicle.collision_hard`;
- procedural sound: `_play_synth_sweep(pos, 150.0, 40.0, 0.35, 0.65)`;
- existing synth spatial scale: `unit_size = 10.0`;
- registry: VEHICLE / DIEGETIC / DIEGETIC_3D / VEHICLE_FEEDBACK / TRANSIENT;
- event cooldown: `200 ms`;
- `on_collision_contact()` selects hard/head-on when `head_on_ratio >= 0.35` and impact speed is at least `3.0`;
- after event creation, `_apply_collision_output_gain()` applies energy-derived gain to the newly-created transient.

The retained vehicle-feedback contract already proves hard impact energy/gain is materially stronger than glance at matched speed and that hard-impact gain scales with impact speed. 01G must preserve that behavior with production media.

## Candidate source restriction

Use only the local GTA San Andreas audio library already accepted for owner-authorized production-audio slices.

For each selected source, record exact provenance as:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Only the three selected production WAVs may enter Git. GTA archives, candidate pools, rejected candidates, normalized audition copies, and analysis artifacts remain local/ignored.

## Selected listening identities

### Pursuer intercept — `GTA_SA:GENRL:BANK_40:SOUND_1`

Massive vehicle-body slam with dense mechanical crunch and metal deformation. The selection reads as a larger-mass critical interception than the normal hard collision and differs from the Signal Gate by emphasizing chassis crumple/friction rather than resonant barrier clang.

### Collision glance — `GTA_SA:GENRL:BANK_51:SOUND_2`

Abrasive lateral metal scrape/body-panel rub with immediate attack and fast decay. It remains compact/repeatable and intentionally lighter/frictional compared with the structural hard collision.

### Collision hard — `GTA_SA:GENRL:BANK_58:SOUND_2`

Heavy direct metal crumple and structural frame crash with substantial low-mid body. It remains materially heavier than glance while avoiding the larger catastrophic-mass identity reserved for pursuer interception.

## Production treatment

For each selected WAV:

- preserve mono 16-bit PCM;
- preserve the exact native sample rate listed in the locked selection table;
- preserve natural duration within ±0.01 s of the selected source;
- no gain normalization;
- no EQ, compression, reverb, resampling, or time stretching;
- apply only ~1.5 ms boundary taper;
- Godot import must remain non-destructive with `compress/mode=0`.

Any gain differences required by collision severity remain runtime-owned by the existing collision-energy path rather than being baked into destructive source processing.

## Runtime integration contract

1. Add exact event-to-slot mappings for all three targets.
2. Resolve selected streams through `AudioRegistry` and the existing bounded production-transient cache.
3. Preserve `AudioStreamPlayer3D` playback at the exact supplied gameplay position.
4. Preserve `unit_size = 10.0` for all three production voices.
5. Do not add new `max_distance` overrides solely for production playback.
6. Preserve current event cooldowns and global transient budget.
7. Preserve each old procedural synth branch as independently reachable fallback.
8. Preserve `PURSUIT_INTERCEPTED` side effects exactly once whether production or fallback media is used:
   - `_is_decaying_pursuit_pressure = false`;
   - `set_radio_duck(-24.0, 0.05)`.
9. Preserve collision classification thresholds and vehicle physics unchanged.
10. Preserve `_apply_collision_output_gain()` behavior on the newly-created production collision voice.
11. A missing production stream for one target must not disable the other two.
12. Do not alter FB-13, Gate, 01D Golden Loop, or 01F Signal Lock behavior.

## Automated verification after selection/integration

The exact-head production contract must prove for all three targets:

- semantic slot and exact runtime event mapping;
- exact production path and exact GTA source provenance;
- selected WAV exists and loads as mono 16-bit `AudioStreamWAV`;
- exact native sample rate and selected duration are preserved within ±0.01 s;
- stream resolves through the registry-backed production cache;
- event creates a bounded `AudioStreamPlayer3D` at an arbitrary supplied world position;
- `unit_size = 10.0` and no unauthorized max-distance override;
- individual procedural fallback remains independently reachable;
- removing one cached production stream does not disable the other two.

Additional behavior proof:

- `PURSUIT_INTERCEPTED` production playback still cancels pursuit decay and applies `-24 dB` radio duck;
- interception fallback performs the same side effects exactly once;
- glance/hard production paths still receive collision-energy-derived output gain;
- matched-speed hard impact remains materially stronger than glance;
- higher-speed hard impact remains materially stronger than lower-speed hard impact;
- pursuit siren/tension layers remain active during collision overlap;
- transient voice budget remains bounded;
- authoritative reset clears all impact voices.

Regression verification must include:

- Audio Runtime;
- vehicle-feedback contract;
- pursuit/interception contract and retained pursuit suites;
- semantic slot manifest;
- FB-13 01B;
- Gate Slam 01C;
- Golden Loop 01D;
- Signal Lock 01F;
- repository-required canonical Web compatibility matrix.

## Human native verification

One exact-head native session should cover the full pack:

1. trigger low/mid-speed glancing contacts;
2. trigger moderate and high-speed hard/head-on impacts;
3. verify repeated collisions during normal engine/traction playback;
4. verify representative collision overlap during active pursuit;
5. allow a pursuer interception and hear the production intercept impact under full threat mix;
6. retry/repeat representative events for artifact/fatigue checks.

Judge:

- correct production sample actually heard for each event;
- glance vs hard event identity is unmistakable;
- hard impact reads materially heavier than glance;
- collision intensity/gain scaling remains perceptually natural;
- interception remains critical and readable under siren/tension;
- radio/threat mix transitions correctly at interception;
- source localization tracks real collision/interception position;
- no clipping, boundary pops, wrong pitch/speed, truncation, or obvious extraction artifacts;
- no problematic masking with engine, traction, brake, gate, or pursuit layers;
- repeated impacts are not excessively fatiguing;
- each production sound is materially preferable to its procedural fallback.

## Completion

01G reaches PASS only after three selected GTA sources are integrated, exact-head automated verification passes, exact-head native batch listening passes, fresh Standards/Spec review passes, the PR merges, and exact-main verification/playtest provenance is green.
