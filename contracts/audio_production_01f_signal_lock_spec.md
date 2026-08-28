# Audio Production 01F — Signal Lock Pulse

**State:** CANDIDATE_SELECTION_REQUIRED  
**Baseline:** `main@6a9e42b0c12a1c357dd695138ce8e962cfa7e873`  
**Semantic slot:** `player.signal_lock_pulse`  
**Runtime event:** `AudioManager.SoundEvent.SIGNAL_LOCK`

## Objective

Replace the live Signal Tuner lock confirmation sweep with one owner-authorized GTA San Andreas production transient while preserving tuner gameplay timing, real world source position, transient voice budget, and procedural fallback.

This is one bounded production-audio replacement. It does not authorize tuner mechanic changes, new near-lock sounds, additional UI audio, another semantic slot, or audio-framework redesign.

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

## Candidate source restriction

Use only the locally stored GTA San Andreas audio library already accepted for owner-authorized production-audio slices.

Exact selected source identity must be recorded as:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Rejected candidates and GTA archive containers remain local/ignored.

## Listening target

The production sound should read as the Signal Tuner physically achieving lock while still carrying a slightly uncanny signature identity:

- compact and immediate confirmation;
- electrical/mechanical tuning lock rather than menu/UI click;
- clearly localized to the tuner mast/device;
- distinct from `interaction.wire_spark` and FB-13 resonance;
- not a gunshot, explosion, siren, musical victory sting, or magical beam;
- enough mid/high-frequency information for small speakers without becoming piercing;
- no strong low-frequency body that masks panel/vehicle ambience;
- clean under the tuning/static texture;
- low fatigue across repeated tuning retries.

Prefer roughly `0.08–0.45 s`. Duration is a listening target, not permission to time-stretch a source.

## Production asset contract

Canonical destination:

`res://audio/player/sfx_player_signal_lock_pulse.wav`

The selected production asset must:

- derive from the exact human-selected GTA source;
- be mono `AudioStreamWAV` suitable for `AudioStreamPlayer3D`;
- use 16-bit PCM;
- preserve native sample rate unless a concrete playback defect requires otherwise;
- preserve the natural envelope with only minimal boundary treatment;
- receive no speculative normalization, EQ, compression, reverb, or time stretching;
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
- canonical production path and exact source provenance;
- valid mono 16-bit production WAV;
- native sample rate/duration locked after candidate selection;
- `SIGNAL_LOCK -> player.signal_lock_pulse` mapping;
- production stream resolves through registry;
- production event creates a bounded `AudioStreamPlayer3D` at an arbitrary supplied test position;
- production voice preserves `unit_size = 10.0`;
- procedural fallback remains independently reachable;
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

01F reaches PASS only after one GTA source is human-selected and integrated, exact-head automated verification passes, exact-head native in-game listening passes, fresh Standards/Spec review passes, the PR merges, and exact-main verification is green.
