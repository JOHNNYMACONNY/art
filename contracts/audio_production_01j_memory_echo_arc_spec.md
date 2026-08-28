# Audio Production 01J — Memory Echo Arc Pack

**State:** SOURCES_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@7ac2233ff252ce9ba6e14b746daa386673f04b8e`

## Objective

Replace the three live procedural Memory Echo phase sounds as one coherent production arc while preserving the existing shared non-spatial Echo voice and authored phase timing:

1. `echo.onset` / `AudioManager.SoundEvent.ECHO_ONSET` — discovery rupture;
2. `echo.bed_loop` / `AudioManager.SoundEvent.ECHO_PEAK` — bounded fractured signal apparition;
3. `echo.completion` / `AudioManager.SoundEvent.ECHO_TAIL` — electrical resolution tail.

Do not change Echo narrative payloads, authored-data validation, phase durations, player-control ownership, pursuit authorization, mission state, or replay-reset semantics.

## Locked production selections

### Echo Onset

Selected source:

`GTA_SA:GENRL:BANK_143:SOUND_37`

Characteristics:

- duration: `0.2018 s`;
- native sample rate: `22,050 Hz`;
- mono 16-bit PCM;
- raw bytes: `8,942`;
- raw SHA-256: `74c854b96856bc0280dd2366b09f7a3afc72692bfb9c08a924ce610e321fd6ee`;
- sharp electrical carrier rupture / memory-window fracture;
- distinct from Wire Spark and Signal Lock;
- excellent small-speaker attack definition;
- no gain, resampling, EQ, compression, reverb, or time stretching;
- approved treatment: only ~`1.5 ms` boundary taper.

Runner-up `SCRIPT / Bank 352 / Sound 0` remains audition evidence only.

Canonical production path:

`res://audio/echo/sfx_echo_onset.wav`

### Echo Peak / `echo.bed_loop`

Selected source:

`GTA_SA:SCRIPT:BANK_356:SOUND_78`

Characteristics:

- duration: `1.0727 s`;
- native sample rate: `15,000 Hz`;
- mono 16-bit PCM;
- raw bytes: `32,224`;
- raw SHA-256: `4d8d67859130310ec4ed299bd4f277ec03ed52654a3f7a54b4ee4f007ec97f3c`;
- fractured harmonic beating / comb-like signal apparition;
- naturally fills the live 1.10-second PEAK window without looping or time stretch;
- no gain, resampling, EQ, compression, reverb, or time stretching;
- approved treatment: only ~`1.5 ms` boundary taper.

Runners-up `SCRIPT / Bank 356 / Sound 1` and `SCRIPT / Bank 356 / Sound 84` remain audition evidence only.

Canonical production path:

`res://audio/echo/sfx_echo_peak.wav`

### Echo Completion / Tail

Selected source:

`GTA_SA:SCRIPT:BANK_356:SOUND_60`

Characteristics:

- duration: `0.4420 s`;
- native sample rate: `12,000 Hz`;
- mono 16-bit PCM;
- raw bytes: `10,652`;
- raw SHA-256: `85a606ab940c9c07ffecd9108e08f705afdbd3c4e47fc607e47f5332ace67f6a`;
- delicate high-frequency electrical shimmer / dissolve;
- naturally occupies the 0.45-second RELEASE window and resolves to silence before disturbance;
- no gain, resampling, EQ, compression, reverb, or time stretching;
- approved treatment: only ~`1.5 ms` boundary taper.

Runners-up `SCRIPT / Bank 356 / Sound 81` and `SCRIPT / Bank 357 / Sound 21` remain audition evidence only.

Canonical production path:

`res://audio/echo/sfx_echo_completion_tail.wav`

## Human arc audition result

The selected trio was auditioned at real phase timing on exact candidate-search head `b8da1981a6831b279c73d8e767f9eaf288ef524b`:

`Onset -> Peak -> Tail -> silence -> production Disturbance Alert`

Result: **PASS**.

The sequence reads as one coherent psychological apparition:

`rupture -> apparition -> dissolve -> threat returns`.

No production asset is considered integrated until exact repository verification and native gameplay listening pass after asset ingestion.

## Runtime authority

`MemoryEchoController` owns the live phase machine:

`IDLE -> ONSET -> PEAK -> RELEASE -> DONE`

Authoritative phase timing:

- ONSET: `0.28 s`;
- PEAK: `1.10 s`;
- RELEASE: `0.45 s`.

All three phase events are live and all three currently use the same dedicated non-spatial `_echo_voice: AudioStreamPlayer` in `AudioManager`.

### ECHO_ONSET

`MemoryEchoController._enter_onset()` calls `AudioManager.set_mix_state(MixState.MEMORY_ECHO)`, which preserves the existing `-16 dB` radio duck and triggers `ECHO_ONSET`.

Procedural fallback remains `_create_echo_onset_wav()` with the existing phase volume `-8 dB`.

### ECHO_PEAK / `echo.bed_loop`

`MemoryEchoController._enter_peak()` calls `play_event(ECHO_PEAK, Vector3.ZERO)` exactly after the ONSET phase.

Live runtime is a finite ~1.10-second one-shot on the shared Echo voice. The current registry metadata for `echo.bed_loop` incorrectly says `CONTINUOUS_LOOP`, `is_looping = true`, with a 4-second loop window.

01J must align this slot metadata to actual authority:

- semantic slot ID remains `echo.bed_loop`;
- playback type becomes `TRANSIENT`;
- `is_looping = false`;
- loop window becomes `0.0 / 0.0`;
- spatial/diegetic/mix identity remains NON_DIEGETIC / NON_DIEGETIC_2D / SIGNATURE_ECHO.

This is metadata/runtime alignment only. Do not create a new long-lived loop player or change the 1.10-second phase duration.

Procedural fallback remains `_create_echo_peak_wav()` with the existing phase volume `-4 dB`.

### ECHO_TAIL / `echo.completion`

`MemoryEchoController._enter_release()` calls `play_event(ECHO_TAIL, Vector3.ZERO)` after PEAK.

Procedural fallback remains `_create_echo_tail_wav()` with the existing phase volume `-12 dB`.

## Shared playback ownership

01J must preserve:

- one shared non-spatial `MemoryEchoVoice` (`AudioStreamPlayer`);
- no generic 3D production-transient routing;
- each phase replaces the stream on the same voice;
- phase controller remains timing authority;
- production and procedural paths use the same existing phase volume levels;
- `reset_audio_instant()` stops the shared Echo voice and leaves no leaked playback;
- replay/quiet-aftermath behavior remains unchanged.

## Production treatment

For all three selected WAVs:

- preserve mono 16-bit PCM;
- preserve exact native sample rate;
- preserve selected natural duration within ±0.01 s;
- no gain normalization;
- no resampling;
- no EQ, compression, reverb, or time stretching;
- only approved ~1.5 ms boundary taper;
- non-destructive Godot import with `compress/mode=0`.

`AudioRegistry` remains canonical production path/provenance authority. `AudioManager` must not hardcode independent production asset paths.

## Runtime integration contract

1. Add exact event-to-slot mappings:
   - `ECHO_ONSET -> echo.onset`;
   - `ECHO_PEAK -> echo.bed_loop`;
   - `ECHO_TAIL -> echo.completion`.
2. Resolve the three selected streams from `AudioRegistry` into a dedicated Echo production stream cache.
3. Keep playback on the existing shared 2D `_echo_voice` rather than the generic 3D transient cache.
4. Preserve phase volumes exactly: Onset `-8 dB`, Peak `-4 dB`, Tail `-12 dB`.
5. Preserve all three procedural generators as independently reachable fallbacks when the corresponding production stream is missing.
6. One missing production Echo stream must not disable the other two.
7. Preserve `MixState.MEMORY_ECHO` radio/tuning ownership.
8. Preserve `MemoryEchoController` timing at 0.28 / 1.10 / 0.45 seconds.
9. Preserve authored payload and Mission 01 extraction routes through the same lifecycle.
10. Preserve reset behavior with no leaked Echo playback.
11. Do not alter disturbance authorization timing after Echo completion.

## Automated verification

Exact-head 01J production contract must prove:

- exact three event/slot mappings;
- exact production paths and GTA provenance;
- mono PCM16 characteristics;
- Onset `22,050 Hz / ~0.2018 s`;
- Peak `15,000 Hz / ~1.0727 s`;
- Tail `12,000 Hz / ~0.4420 s`;
- all three production streams resolve from registry;
- each event uses the same existing `_echo_voice` `AudioStreamPlayer`;
- phase volume is preserved for production playback;
- each procedural fallback remains independently reachable;
- removing one production stream does not disable another phase;
- `echo.bed_loop` is now metadata-aligned as a non-looping TRANSIENT while keeping its semantic ID;
- controller timing constants remain 0.28 / 1.10 / 0.45 seconds;
- authoritative reset stops the Echo voice.

Regression verification must include Audio Runtime, authored Memory Echo contracts, reset/replay contracts, 01H pursuit, 01G impacts, 01F, 01D, 01C, 01B, semantic manifest, and canonical Web compatibility.

## Human native verification

One exact-head gameplay session must cover the full Echo lifecycle:

- Onset synchronization with exposure flash;
- Peak under Echo text reveal;
- Tail dissolution into silence;
- transition into Disturbance Alert;
- repeated full-arc fatigue;
- reset/retry with no leaked Echo voice;
- both Mission 01 extraction Echo and an authored later Echo route if practical.

Judge production sample identity, timing, mix, phase-to-phase continuity, artifacts, fatigue, and material improvement over procedural fallbacks.

## Completion

01J reaches PASS only after three selected production assets are integrated, exact-head automated verification passes, exact-head native arc listening passes, fresh Standards/Spec review passes, PR merge completes, and exact-main verification/playtest provenance is green.
