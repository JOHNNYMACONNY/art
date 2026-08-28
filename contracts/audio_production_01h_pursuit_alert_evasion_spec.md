# Audio Production 01H — Pursuit Alert & Evasion Pack

**State:** SOURCES_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@306352950bb92047ba8cb2869e5312f750b92aec`

## Objective

Promote two live pursuit transients and retain one scanner candidate without runtime promotion:

1. `pursuit.disturbance_alert` / `AudioManager.SoundEvent.DISTURBANCE_ALERT`;
2. `pursuit.evaded_stinger` / `AudioManager.SoundEvent.EVASION_RELEASE`;
3. `pursuit.pursuer_sweep` remains retention-only in 01H.

Use the proven batched workflow: one GTA candidate search/audition pass, one source-lock phase, one repo-side implementation pass, one asset-ingestion pass, one exact-head verification/review cycle, and one PR/merge.

Do not change pursuit steering, chase thresholds, gate behavior, interception behavior, vehicle physics, or unrelated audio slots.

## Locked selections

### Disturbance Alert — promote

Selected source:

`GTA_SA:GENRL:BANK_138:SOUND_40`

Characteristics:

- duration: `0.2805 s`;
- native sample rate: `20,000 Hz`;
- mono 16-bit PCM;
- frames: `5,610`;
- raw bytes: `11,264`;
- raw SHA-256: `9984d10737f9527e39a86a08816f7bacc481fe90cfaf56ac7b99ab4bb8c9df39`;
- urgent electronic security chirp/buzz that reads before siren spin-up;
- no gain change, resampling, EQ, compression, reverb, or time stretching;
- approved treatment: only ~`1.5 ms` boundary taper.

Runner-up `GENRL / Bank 138 / Sound 39` remains audition evidence only.

Canonical production path:

`res://audio/pursuit/sfx_pursuit_disturbance_alert.wav`

### Evaded Stinger — promote

Selected source:

`GTA_SA:GENRL:BANK_143:SOUND_45`

Characteristics:

- duration: `0.5907 s`;
- native sample rate: `18,000 Hz`;
- mono 16-bit PCM;
- frames: `10,632`;
- raw bytes: `21,308`;
- raw SHA-256: `5d1c0a3af5025acf928cf6f8180e6416f4373e3ede0e0efd933fb9ce3f6b3c0e`;
- calm descending electronic de-escalation cue that blends into siren/tension decay;
- no gain change, resampling, EQ, compression, reverb, or time stretching;
- approved treatment: only ~`1.5 ms` boundary taper.

Runner-up `GENRL / Bank 138 / Sound 34` remains audition evidence only.

Canonical production path:

`res://audio/pursuit/sfx_pursuit_evaded_stinger.wav`

### Pursuer Sweep — retention only

Best audited candidate:

`GTA_SA:GENRL:BANK_138:SOUND_43`

Characteristics:

- duration: `0.3847 s`;
- native sample rate: `20,900 Hz`;
- raw SHA-256: `46a40bebd9f3b390863dc4e1c472bd4cf14800b46f510539696c2ed796312093`;
- repeated-loop seam is clean;
- 10-second repeated playback exposes rapid-cadence fatigue.

01H decision: **RETENTION ONLY**.

The scanner candidate must not receive:

- a production WAV under `godot/audio/`;
- a production path or final asset status;
- a new `SoundEvent`;
- an AudioManager playback player;
- a pursuer runtime caller;
- a semantic conversion from continuous loop to transient.

The existing `pursuit.pursuer_sweep` registry slot remains procedural/replacement-required until a dedicated periodic scanner subsystem or a better low-fatigue loop is authored.

## Runtime authority findings

### Disturbance alert — live

Current path:

- `set_mix_state(MixState.DISTURBANCE)` calls `play_event(DISTURBANCE_ALERT, Vector3.ZERO)`;
- procedural cue: `350 Hz -> 700 Hz`, `0.4 s`, volume `0.6`;
- generic synth playback is `AudioStreamPlayer3D` with `unit_size = 10.0`;
- the event also calls `set_siren_audio(true, pos)`.

Registry metadata remains:

- PURSUIT;
- NON_DIEGETIC;
- NON_DIEGETIC_2D;
- CRITICAL_THREAT;
- TRANSIENT;
- max concurrency 1.

The pre-existing semantic/reference 2D label must not be silently rewritten merely because shipping playback uses the existing 3D synth path.

**Critical invariant:** production playback must not bypass siren activation. `set_siren_audio(true, pos)` must execute for both production and procedural fallback paths.

### Evaded stinger — live

Current path:

- `set_mix_state(MixState.EVASION_RELEASE)` calls `play_event(EVASION_RELEASE, Vector3.ZERO)`;
- procedural cue: `500 Hz -> 1000 Hz`, `0.5 s`, volume `0.5`;
- generic synth playback is `AudioStreamPlayer3D` with `unit_size = 10.0`.

Registry metadata remains:

- PURSUIT;
- NON_DIEGETIC;
- NON_DIEGETIC_2D;
- SIGNATURE_ECHO;
- TRANSIENT;
- max concurrency 1.

Radio recovery remains owned by the existing pursuit-release decay envelope. 01H must not introduce a second radio-recovery owner or short-circuit the existing de-escalation flow.

## Production treatment

For both promoted WAVs:

- preserve mono 16-bit PCM;
- preserve exact native sample rate;
- preserve selected natural duration within ±0.01 s;
- no gain normalization;
- no resampling;
- no EQ, compression, reverb, or time stretching;
- apply only the approved ~1.5 ms boundary taper;
- Godot import remains non-destructive with `compress/mode=0`.

`AudioRegistry` remains canonical path/provenance authority. `AudioManager` must not hardcode independent production paths.

## Runtime integration contract

1. `DISTURBANCE_ALERT -> pursuit.disturbance_alert`.
2. `EVASION_RELEASE -> pursuit.evaded_stinger`.
3. Both production streams resolve through the existing registry-backed production-transient cache.
4. Shipping production playback preserves the existing bounded `AudioStreamPlayer3D` behavior with `unit_size = 10.0`.
5. Do not add a new `max_distance` override solely for production playback.
6. Preserve the old `350 -> 700 Hz / 0.4 s` disturbance fallback.
7. Preserve the old `500 -> 1000 Hz / 0.5 s` evasion fallback.
8. Disturbance siren activation executes exactly once whether production or fallback audio is used.
9. Evasion release does not create a second radio-recovery owner.
10. `pursuit.pursuer_sweep` remains unpromoted and unmapped in AudioManager.
11. One missing 01H production stream must not disable the other.
12. Existing 01G interception/collision, Gate, Signal Lock, Golden Loop, FB-13 and reset behavior remain unchanged.

## Automated verification

Exact-head 01H production verification must prove:

- exact two event/slot mappings;
- exact production paths and GTA provenance;
- mono 16-bit native WAV characteristics;
- disturbance `20,000 Hz / ~0.2805 s`;
- evasion `18,000 Hz / ~0.5907 s`;
- streams resolve through production cache;
- production playback creates bounded 3D voices at arbitrary supplied positions with `unit_size = 10.0` and no new max-distance override;
- each procedural fallback remains independently reachable;
- one missing production stream does not disable the other;
- disturbance production path still activates siren;
- disturbance fallback still activates siren;
- evasion playback leaves radio-recovery ownership unchanged;
- `pursuit.pursuer_sweep` remains procedural/replacement-required with no production path and no AudioManager event mapping;
- authoritative reset clears 01H transient voices.

Regression verification must include Audio Runtime, semantic manifest, pursuit/interception suites, 01G, 01F, 01D, 01C, 01B, and canonical Web compatibility.

## Human native verification

One exact-head pursuit session must cover:

- disturbance transition and selected alert before/with siren onset;
- active chase overlap to ensure alert does not mask critical pursuit layers;
- successful evasion and selected release stinger during tension/siren decay;
- quiet aftermath with no extra scanner voice;
- repeated retry/fatigue pass;
- pairwise distinction from Signal Lock, Intercept, Core Extracted and Gate where relevant.

Judge both promoted sounds for synchronization, mix, artifacts, fatigue, native-rate playback, and material improvement over fallback.

## Completion

01H reaches PASS only when the two promoted targets have exact-head automated proof, exact-head native listening, fresh Standards/Spec review, merged PR, exact-main CI, and current playtest provenance. The retained scanner candidate is not production-final and does not count as a promoted asset.
