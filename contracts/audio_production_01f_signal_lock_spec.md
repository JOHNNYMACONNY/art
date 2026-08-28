# Audio Production 01F — Signal Lock Pulse

**State:** SOURCE_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@6a9e42b0c12a1c357dd695138ce8e962cfa7e873`  
**Semantic slot:** `player.signal_lock_pulse`  
**Runtime event:** `AudioManager.SoundEvent.SIGNAL_LOCK`

## Objective

Replace the live Signal Tuner lock confirmation sweep with one owner-authorized GTA San Andreas production transient while preserving tuner gameplay timing, real world source position, transient voice budget, and procedural fallback.

This is one bounded production-audio replacement. It does not authorize tuner mechanic changes, new near-lock sounds, additional UI audio, another semantic slot, or audio-framework redesign.

## Selected source

Human audition selected exactly:

`GTA_SA:GENRL:BANK_143:SOUND_31`

Selected source characteristics:

- native duration: `0.3780 s`;
- native sample rate: `23,000 Hz`;
- mono 16-bit linear PCM;
- raw SHA-256: `f9af33195ae58ad822cf9addee870f61c1e1fb0f365d267346a0a99f2b75a936`;
- resonant electronic harmonic lock confirmation with physical tuner-cavity ring;
- clear above tuning/static texture on laptop and phone transducers;
- perceptually distinct from the abrasive `interaction.wire_spark` transient and the low FB-13 resonance;
- five rapid retry auditions passed without fatigue;
- extraction integrity PASS with no truncation, wrong pitch/speed, PCM artifacts, or audible boundary pop.

Production treatment is intentionally minimal:

- no gain change;
- preserve native 23 kHz sample rate;
- preserve natural duration;
- apply only ~1.5 ms boundary taper;
- no EQ, compression, reverb, time stretching, or other processing.

Candidate B (`GENRL / Bank 138 / Sound 38`) remains runner-up audition evidence only and must not enter the production tree.

## Runtime authority

`SignalTuner._lock_signal()` currently emits:

`audio_event_triggered.emit("SIGNAL_LOCK", global_position)`

The current `AudioManager` implementation plays `SIGNAL_LOCK` via `_play_synth_sweep(pos, 440.0, 880.0, 0.35, 0.5)`, which creates an `AudioStreamPlayer3D` with `unit_size = 10.0` at the supplied tuner world position.

Therefore the authoritative live behavior is spatialized 3D playback at the tuner.

## Semantic metadata repair

The registry currently labels `player.signal_lock_pulse` as:

- `diegesis = HYBRID`
- `spatial_type = NON_DIEGETIC_2D`

That spatial label contradicts the live runtime behavior.

01F must:

- preserve `diegesis = HYBRID`;
- repair `spatial_type` to `DIEGETIC_3D`;
- preserve `mix_group = SIGNATURE_ECHO`;
- preserve transient/non-looping lifecycle;
- preserve current cooldown/concurrency semantics.

This is a metadata correction to match existing gameplay, not a gameplay behavior change.

## Production asset contract

Canonical destination:

`res://audio/player/sfx_player_signal_lock_pulse.wav`

The selected production asset must:

- derive from exactly `GTA_SA:GENRL:BANK_143:SOUND_31`;
- be mono `AudioStreamWAV` suitable for `AudioStreamPlayer3D`;
- use 16-bit PCM;
- preserve native `23,000 Hz` sample rate;
- preserve natural duration at approximately `0.3780 s`;
- receive no gain normalization, resampling, EQ, compression, reverb, or time stretching;
- use only the approved ~1.5 ms boundary taper;
- use non-destructive Godot import settings with `compress/mode=0`.

`AudioRegistry` remains canonical path/provenance authority. `AudioManager` must not duplicate the production asset path as an independent constant.

## Runtime contract

1. `AudioManager.event_to_slot_id(SIGNAL_LOCK)` returns `player.signal_lock_pulse`.
2. `AudioManager` resolves the production stream through `AudioRegistry`.
3. Production playback remains one bounded `AudioStreamPlayer3D` at the exact position supplied by gameplay.
4. Preserve `unit_size = 10.0` from the existing procedural path.
5. Do not add a new `max_distance` override solely for production playback.
6. If the production stream is absent/unloaded, the existing `440 Hz -> 880 Hz`, `0.35 s`, volume `0.5` sweep remains independently reachable.
7. Near-lock enter/exit behavior is unchanged.
8. Tuner state, dwell timing, target frequency, lock tolerance, input behavior, and visual response remain unchanged.
9. No second semantic slot is migrated in 01F.

## Automated verification

Exact-head verification must prove:

- slot metadata repair: HYBRID diegesis + DIEGETIC_3D spatiality;
- canonical production path `res://audio/player/sfx_player_signal_lock_pulse.wav`;
- exact source provenance `GTA_SA:GENRL:BANK_143:SOUND_31`;
- production WAV is mono 16-bit PCM at 23,000 Hz and approximately 0.3780 s;
- `SIGNAL_LOCK -> player.signal_lock_pulse` mapping;
- production stream resolves through registry;
- production event creates a bounded `AudioStreamPlayer3D` at an arbitrary supplied test position;
- production voice preserves `unit_size = 10.0`;
- procedural fallback remains independently reachable and retains ~0.35 s sweep duration;
- Signal Tuner gameplay contract remains green;
- Audio Runtime, semantic manifest, 01B/01C/01D production contracts, and repository-required compatibility remain green.

## Human in-game verification

On the exact clean candidate SHA, perform real Signal Tuner interactions and judge:

- selected production sample actually plays rather than fallback;
- lock confirmation aligns with the moment the tuner enters `LOCKED`;
- sound localizes to the tuner mast/device rather than player/camera;
- tuning/static texture remains intelligible before lock;
- no accidental resemblance to the wire-spark production transient;
- no clipping, boundary pop, pitch/speed error, or truncation;
- repeated tuning attempts remain low-fatigue;
- production sample is materially preferable to the procedural sweep.

## Completion

01F reaches PASS only after the selected GTA source is integrated, exact-head automated verification passes, exact-head native in-game listening passes, fresh Standards/Spec review passes, the PR merges, and exact-main verification is green.
