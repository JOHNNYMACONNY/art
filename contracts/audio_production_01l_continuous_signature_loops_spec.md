# Audio Production 01L — Continuous Signature Loops Pack

**State:** SOURCES_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@978f13a6d8d6908b1e571d1be573de3c8cd0d1f5`

## Objective

Replace three live procedural continuous-loop identities with production media while preserving their existing runtime owners and modulation logic:

1. `vehicle.engine_rev` — active vehicle propulsion loop;
2. `pursuit.siren_alarm` — spatial pursuer threat loop;
3. `echo.radio_interference` — hybrid precursor-Echo radio contamination loop.

No new player nodes, gameplay mechanics, pursuit rules, radio rules, vehicle physics, timers, schedulers, or reset owners are authorized.

## Locked production selections

### Vehicle Engine Rev

Selected source:

`GTA_SA:GENRL:BANK_8:SOUND_1`

- mono PCM16;
- native sample rate: `18,000 Hz`;
- frame count: `21,531`;
- duration: `1.1962 s`;
- raw bytes: `43,106`;
- raw SHA-256: `60ed5448461756a7bbcb527c1e0768004164464e01b186abff336bfe646cb72b`;
- reclaimed electric/mechanical drivetrain turbine whir;
- passed 60 s loop fatigue and runtime pitch tests at `0.72 / 0.90 / 1.00 / 1.30 / 1.60 / 2.12x`;
- no low-pitch mud or high-pitch comedy/harshness;
- proposed treatment: only ~`40 ms` equal-power circular seam blend (`~720` frames), preserving duration/sample rate;
- forward loop; no normalization, resampling, EQ, compression, reverb, or time stretching.

Runner-up `GTA_SA:GENRL:BANK_8:SOUND_0` remains audition evidence only.

Canonical production path:

`res://audio/vehicle/loop_vehicle_engine_rev.wav`

### Pursuit Siren Alarm

Selected source:

`GTA_SA:GENRL:BANK_39:SOUND_8`

- mono PCM16;
- native sample rate: `18,000 Hz`;
- frame count: `13,989`;
- duration: `0.7772 s`;
- raw bytes: `28,022`;
- raw SHA-256: `c1c4c8fe1fb754e46d85a9ea6e40786de95da88f9bab361bb5fd6ed929f84bcf`;
- autonomous pursuer electronic alarm warble;
- passed 45 s fatigue and `1.00 -> 1.45x` pursuit-pressure modulation;
- distinct from Disturbance Alert, Evasion Release, Signal Lock, and Intercept;
- proposed treatment: only ~`30 ms` equal-power circular seam blend (`~540` frames), preserving duration/sample rate;
- forward loop; no normalization, resampling, EQ, compression, reverb, or time stretching.

Runner-up `GTA_SA:SCRIPT:BANK_353:SOUND_0` remains audition evidence only.

Canonical production path:

`res://audio/pursuit/loop_pursuit_siren_alarm.wav`

### Echo Radio Interference

Selected source:

`GTA_SA:SCRIPT:BANK_356:SOUND_12`

- mono PCM16;
- native sample rate: `15,000 Hz`;
- frame count: `14,369`;
- duration: `0.9579 s`;
- raw bytes: `28,782`;
- raw SHA-256: `b354523d6aa0ccd7e320f7799641561e10a59c641d6eb6f45d2306fe4e8c10e6`;
- fractured RF carrier contamination / digital telemetry flutter;
- passed 45 s loop fatigue at approximate `-30 / -21 / -12 dB` proximity levels;
- sits beneath Yardline radio and remains distinct from the 01J Memory Echo arc;
- suppresses cleanly under Memory Echo/reset/critical priority;
- proposed treatment: only ~`30 ms` equal-power circular seam blend (`~450` frames), preserving duration/sample rate;
- forward loop; no normalization, resampling, EQ, compression, reverb, or time stretching.

Runner-up `GTA_SA:SCRIPT:BANK_356:SOUND_30` remains audition evidence only.

Canonical production path:

`res://audio/echo/loop_echo_radio_interference.wav`

## Pack-level audition result

Human candidate audition on exact search head `2268a347ce704a05c1315c50bc2695264190930b`:

- Engine vs Siren: PASS;
- Engine vs Interference: PASS;
- Siren vs Interference: PASS;
- all-three spectral separation: PASS;
- combined loop fatigue: PASS;
- extraction/staging integrity: PASS.

This audition selects source identity only. Final production integration still requires exact-head automated proof and native gameplay listening after asset ingestion.

## Runtime authority to preserve

### `vehicle.engine_rev`

Existing owner: one `AudioStreamPlayer3D` named `EngineRevPlayer`.

Preserve exactly:

- Master bus;
- `unit_size = 12.0`;
- `max_distance = 30.0`;
- live vehicle world-position updates;
- rich vehicle-feedback pitch formula `clamp(0.76 + speed*1.05 + load*0.28, 0.72, 2.12)`;
- rich feedback gain formula `clamp(-25 + speed*11 + load*7, -25, -6)`;
- priority-state gain cap at `-12 dB`;
- legacy speed-responsive path for other vehicles;
- stop/start ownership;
- reset restoration to pitch `1.0` / gain `0.0`;
- existing procedural `0.5 s` noise loop as independently reachable fallback.

### `pursuit.siren_alarm`

Existing owner: one `AudioStreamPlayer3D` named `SirenAlarmPlayer`.

Preserve exactly:

- Master bus;
- `unit_size = 15.0`;
- `max_distance = 35.0`;
- pursuit position ownership;
- pressure formula `clamp((20 - distance) / 15, 0, 1)`;
- pitch `1.0 -> 1.45`;
- gain `-4 dB -> +3 dB` during pursuit;
- release-decay ownership and stop behavior;
- Disturbance Alert side effect behavior;
- reset restoration to pitch `1.0` / gain `0.0`;
- existing procedural `440 Hz / 0.6 s` loop as independently reachable fallback.

### `echo.radio_interference`

Existing owner: one `AudioStreamPlayer3D` named `RadioInterferencePlayer3D`.

Preserve exactly:

- Master bus;
- `unit_size = 8.0`;
- `max_distance = 25.0`;
- source-position ownership;
- outer/inner radii `18 m / 3 m`;
- base gain `-30 -> -12 dB` by proximity;
- radio contamination up to `-4 dB`;
- pursuit/disturbance attenuation;
- full suppression during Memory Echo and critical interception;
- reset/intercept clearing;
- existing eligibility gates in the prototype controller;
- existing procedural `1.0 s` fractured-carrier loop as independently reachable fallback.

## Registry promotion

After integration, promote only these three slots to project-internal `LICENSED_FINAL`, clear `replacement_required`, add exact production paths/provenance, and align loop windows to selected natural durations:

- engine: `0.0 -> 1.1962`;
- siren: `0.0 -> 0.7772`;
- interference: `0.0 -> 0.9579`.

All domain/diegesis/spatial/mix/concurrency metadata stays unchanged.

Internal `LICENSED_FINAL` is not an independent legal/license-clearance claim.

## Runtime integration contract

1. Resolve the three production streams from `AudioRegistry` in `AudioManager._ready()`.
2. If a production stream exists, use it on the existing corresponding player.
3. If absent, use the exact existing procedural fallback for that player.
4. Production and fallback streams must both be forward-loop enabled.
5. One missing production loop must not disable or alter either other production loop.
6. Do not add any player, event, scheduler, timer, or gameplay-state owner.
7. Do not change `VehicleFeedbackLayer` formulas.
8. Do not change pursuit pressure formulas or interference proximity/suppression formulas.
9. `reset_audio_instant()` behavior and post-reset Wind re-arm remain unchanged.

## Automated verification

Exact-head 01L contract must prove:

- exact registry path/provenance/status/loop metadata for all three;
- WAV existence, mono PCM16, exact native rates and durations;
- each production stream is forward-loop enabled;
- `EngineRevPlayer` uses exact engine stream and preserves unit_size/max_distance;
- `SirenAlarmPlayer` uses exact siren stream and preserves unit_size/max_distance;
- `RadioInterferencePlayer3D` uses exact interference stream and preserves unit_size/max_distance;
- vehicle feedback at representative telemetry preserves expected pitch/gain and selected stream;
- pursuit pressure at far/mid/near positions preserves expected pitch/gain and selected stream;
- interference at outer/mid/inner distances preserves expected gain/radio contamination and selected stream;
- Memory Echo / critical suppression still stops or silences interference as before;
- each procedural fallback remains independently reachable when only that production path is unavailable;
- one missing production stream does not affect the other two;
- authoritative reset stops all three loop voices and restores base pitch/gain values.

Regression verification must include Audio Runtime, Vehicle Feedback, pursuit/intercept, 01K, 01J, 01H, 01G, 01F, 01D, 01C, 01B, semantic manifest, replay/reset, and canonical Web compatibility.

## Human native verification

Exact-head native gameplay listening must cover:

- low/medium/high-load vehicle acceleration and 60+ s driving;
- engine under Wind/Yardline and during pursuit;
- Siren far/near and repeated pressure changes for 45+ s;
- Disturbance Alert -> Siren -> Intercept -> Evasion transitions;
- Interference far/mid/near under active Yardline;
- Interference suppression into Memory Echo and critical pursuit;
- reset/replay with no stale loop or doubled voice;
- small-speaker/headphone harshness and loop seam/fatigue checks.

## Completion

01L reaches PASS only after exact production assets are integrated, exact-head automated verification and native gameplay listening pass, fresh Standards/Spec review passes, PR merges, and exact-main Audio Runtime/Web/public playtest provenance is current.