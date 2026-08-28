# Audio Production 01J — Memory Echo Arc Pack

**State:** CANDIDATE_SELECTION_REQUIRED  
**Baseline:** `main@7ac2233ff252ce9ba6e14b746daa386673f04b8e`

## Objective

Replace the three live procedural Memory Echo phase sounds as one coherent production arc:

1. `echo.onset` / `AudioManager.SoundEvent.ECHO_ONSET` — discovery rupture / low electrical crackle, `~0.28 s`;
2. `echo.bed_loop` / `AudioManager.SoundEvent.ECHO_PEAK` — fractured harmonic signal ghost during the peak reveal, `~1.10 s`;
3. `echo.completion` / `AudioManager.SoundEvent.ECHO_TAIL` — high-frequency electrical resolution tail, `~0.45 s`.

Use one batched GTA candidate search and human audition pass, then one source-lock/integration/asset/verification cycle.

Do not change Echo narrative payloads, authored-data validation, phase durations, player-control ownership, pursuit authorization, mission state, or replay-reset semantics.

## Runtime authority findings on baseline main

All three requested phase events are live.

### Echo lifecycle authority

`MemoryEchoController` owns the phase machine:

`IDLE -> ONSET -> PEAK -> RELEASE -> DONE`

Current phase timing is authoritative:

- ONSET: `0.28 s`;
- PEAK: `1.10 s`;
- RELEASE: `0.45 s`.

The original extraction Echo and authored later Echoes both use this same lifecycle. 01J must therefore work for both routes rather than special-case Mission 01.

### 1. `ECHO_ONSET` — live

`MemoryEchoController._enter_onset()` enters ONSET, emits the phase signal, then calls:

`AudioManager.set_mix_state(MixState.MEMORY_ECHO)`

That mix-state transition:

- shuts down tuning/static space;
- applies the existing `-16 dB` radio duck;
- calls `play_event(ECHO_ONSET, Vector3.ZERO)`.

`AudioManager` then plays the procedural onset through the dedicated shared non-spatial `_echo_voice` (`AudioStreamPlayer`).

Current procedural identity:

- `~0.28 s`;
- low electrical crackle / harmonic stack around 220/330 Hz;
- front-loaded/reversed-style envelope that opens the Echo window.

Registry slot `echo.onset` already matches current authority:

- ECHO domain;
- NON_DIEGETIC;
- NON_DIEGETIC_2D;
- SIGNATURE_ECHO;
- TRANSIENT;
- non-looping;
- max concurrency 1.

### 2. `ECHO_PEAK` — live, registry semantic mismatch exists

`MemoryEchoController._enter_peak()` fires exactly after the 0.28-second ONSET window and calls:

`play_event(ECHO_PEAK, Vector3.ZERO)`

`AudioManager._play_echo_peak()` swaps the same shared `_echo_voice` to a finite procedural `~1.10 s` fractured signal texture.

Current procedural identity:

- approximately 185/187 Hz detuned beating;
- ~3 Hz amplitude modulation;
- sparse noise corruption;
- finite rise/decay envelope across the 1.10-second PEAK phase.

The semantic slot intended for this phase is `echo.bed_loop`, but its registry metadata currently says:

- `CONTINUOUS_LOOP`;
- `is_looping = true`;
- nominal 4.0-second loop window.

That metadata does **not** match live runtime authority. The actual Echo peak is a bounded 1.10-second phase on a single shared 2D voice and is overwritten by the release cue at phase transition.

### 01J authority decision for `echo.bed_loop`

Candidate search and future 01J integration must follow the live bounded PEAK phase rather than invent a new continuous loop.

Therefore:

- audition `echo.bed_loop` candidates as finite `~0.8–1.25 s` one-shot peak textures;
- do not require seamless indefinite looping;
- do not create a second long-lived Echo bed player;
- preserve the semantic slot ID `echo.bed_loop` for compatibility;
- after source selection, implementation may align only its playback metadata to current runtime authority (`TRANSIENT`, non-looping, no loop window) if the exact contract is accepted;
- no phase-duration change is authorized.

This is a metadata/runtime-alignment repair, not a new gameplay feature.

### 3. `ECHO_TAIL` — live

`MemoryEchoController._enter_release()` fires exactly after the 1.10-second PEAK phase and calls:

`play_event(ECHO_TAIL, Vector3.ZERO)`

`AudioManager._play_echo_tail()` swaps the shared `_echo_voice` to a finite procedural `~0.45 s` high-frequency electrical shimmer.

Current procedural identity:

- high-frequency 3.4/5.1 kHz shimmer and light noise;
- exponential decay/dropout;
- completes before `DONE`, where disturbance may then be authorized by the Echo controller owner.

The semantic slot intended for this phase is `echo.completion`:

- ECHO domain;
- NON_DIEGETIC;
- NON_DIEGETIC_2D;
- SIGNATURE_ECHO;
- TRANSIENT;
- non-looping;
- max concurrency 1.

The slot name remains stable even though the current event enum is `ECHO_TAIL`; its semantic role is the Echo resolution/completion tail.

## Shared playback ownership

All three phase sounds use the same dedicated `_echo_voice: AudioStreamPlayer`.

01J must preserve that ownership model unless a verified defect requires otherwise:

- one non-spatial Echo voice;
- no 3D positioning for the arc;
- each phase replaces the stream on the same voice;
- phase transition owns timing;
- `reset_echo()` can stop the voice immediately;
- `reset_audio_instant()` also stops the voice;
- no leaked voice after replay reset or quiet aftermath.

Do not route these sounds through the generic 3D production-transient cache used by vehicle/interaction/pursuit one-shots.

## Candidate source restriction

Use only the owner-authorized local GTA San Andreas audio library already accepted for production-audio work.

For every candidate record exact provenance:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Candidate staging remains local/gitignored. No production WAV is authorized during the search phase.

## Target A — Echo Onset

Desired identity:

- discovery rupture / something electrically opening;
- low-mid electrical crackle, contact tear, unstable carrier, or compact reverse-feeling stress cue;
- front-loaded enough to synchronize with the initial exposure flash;
- uncanny and memory-like without becoming magic/fantasy;
- distinctly non-diegetic / inside-the-head;
- readable on laptop/phone speakers without requiring deep sub-bass;
- not a spark-only snap, UI alert, weapon shot, explosion, or mechanical impact.

Preferred natural duration:

`0.18–0.40 s`

Audition against:

- production Core Extracted;
- production Wire Spark;
- production Signal Lock;
- production Disturbance Alert.

Required distinction:

`Core Extracted = physical release`  
`Wire Spark = local electrical consequence`  
`Signal Lock = affirmative tuner confirmation`  
`Echo Onset = perceptual rupture / memory window opening`

## Target B — Echo Peak / `echo.bed_loop`

Desired identity:

- fractured harmonic signal ghost;
- reclaimed-radio / damaged-memory texture;
- unstable resonant beating, comb-like body, spectral flutter, or corrupted carrier;
- sustains perceptual interest for the entire 1.10-second reveal;
- not a conventional musical chord or pad;
- not a normal radio station clip or voice line;
- not an alarm/siren;
- enough texture to coexist with on-screen Echo text without distracting from it;
- should feel like a bounded signal apparition rather than an endless ambient loop.

Preferred natural duration:

`0.80–1.25 s`

Important audition rule:

Play this candidate as a **finite one-shot**, not an indefinite loop. Judge whether it naturally occupies the 1.10-second PEAK window. A source that only works by obvious time-stretching or repeated looping should be rejected.

If a candidate is shorter than ~0.80 s but has an exceptional identity, it may be retained as runner-up, but do not authorize time stretching during candidate selection.

## Target C — Echo Completion / Tail

Desired identity:

- electrical shimmer / harmonic resolution / signal dropout;
- airy or high-frequency decay that implies the apparition collapsing;
- clearly releases energy rather than starting a new event;
- finite natural tail compatible with the 0.45-second RELEASE window;
- should create a brief pocket of silence/absence before disturbance can take over;
- not a victory chime, UI confirmation, Signal Lock clone, Wire Spark clone, or bright magical sparkle.

Preferred natural duration:

`0.25–0.60 s`

Required distinction:

`Signal Lock = affirmative hardware lock`  
`Wire Spark = physical electrical snap`  
`Echo Tail = perceptual dissolve / memory dropout`

## Three-phase arc audition

Do not choose the three winners in isolation.

For every finalist set, audition the sequence at real phase timing:

1. ONSET winner;
2. wait/transition at ~0.28 s;
3. PEAK winner occupying ~1.10 s;
4. TAIL winner occupying ~0.45 s;
5. then immediate silence / representative Disturbance Alert onset.

The arc should read:

`rupture -> apparition -> dissolve -> threat returns`

not:

`three unrelated sound effects`.

Judge:

- spectral continuity;
- contrast without jarring loudness jumps;
- whether Peak has enough body to carry the reveal;
- whether Tail genuinely resolves Peak;
- whether Disturbance Alert remains clearly a new state after Echo completion;
- repeated-sequence fatigue across at least 5 full arcs.

## Search scope

Start with:

- `GENRL`;
- `SCRIPT`.

Prioritize source families resembling:

- radio/static/interference;
- electronics and signal equipment;
- electrical faults;
- scanner/carrier/modem-like textures;
- machinery resonance;
- short synthetic/electronic tones with organic noise;
- mission-specific signal/communication effects.

Likely useful banks may overlap prior electronics candidates around GENRL 138/143, but do not constrain the search to them.

Search broader SCRIPT banks for longer 0.8–1.25-second Peak textures.

Aim for:

- 4–6 credible Onset candidates;
- 4–6 credible Peak candidates;
- 4–6 credible Tail candidates.

Approximately 12–18 serious candidates total is sufficient.

## Audition quality gate

Human listening is authoritative.

For each candidate report:

- pak / bank / sound index;
- duration;
- native sample rate;
- channels;
- bit depth;
- raw bytes;
- raw SHA-256;
- PASS / REJECT;
- listening identity;
- role fit inside the Echo arc;
- distinction from neighboring production sounds;
- small-speaker readability;
- headphone harshness/fatigue if practical;
- 5-arc repetition fatigue result;
- boundary pop/truncation/PCM artifact status;
- gain change needed;
- boundary treatment needed;
- resampling needed;
- EQ/compression/reverb/time-stretch needed.

Prefer candidates requiring no gain, resampling, EQ, compression, reverb, or time stretching.

A minimal ~1.5 ms one-shot boundary taper may be proposed only when source-boundary behavior warrants it.

## Final selection report

### Echo Onset — Selected

Return exact source metadata plus:

- why it reads as perceptual rupture;
- distinction from Wire Spark;
- distinction from Signal Lock;
- compatibility with the 0.28-second flash;
- future production treatment.

### Echo Peak / `echo.bed_loop` — Selected

Return exact source metadata plus:

- why it works as a finite 1.10-second signal apparition;
- whether it naturally fills the phase without looping/time stretch;
- text-overlay readability;
- spectral continuity from Onset;
- resolution compatibility with Tail;
- future production treatment.

### Echo Completion / Tail — Selected

Return exact source metadata plus:

- why it reads as dissolve/dropout;
- distinction from Signal Lock and Wire Spark;
- compatibility with 0.45-second RELEASE;
- silence pocket before Disturbance Alert;
- future production treatment.

Also return one runner-up for each target.

## Pairwise / arc discrimination

Report:

- Onset vs Peak: PASS / FAIL;
- Peak vs Tail: PASS / FAIL;
- Tail vs Disturbance Alert: PASS / FAIL;
- full three-phase arc: PASS / FAIL;
- five-arc fatigue: PASS / FAIL;
- overall extraction integrity: PASS / FAIL.

## Planned canonical production paths after source lock

If winners pass:

- `echo.onset` -> `res://audio/echo/sfx_echo_onset.wav`;
- `echo.bed_loop` -> `res://audio/echo/sfx_echo_peak.wav`;
- `echo.completion` -> `res://audio/echo/sfx_echo_completion_tail.wav`.

Paths are planned only; candidate search must not create them.

## Expected integration after source lock

Future 01J integration should:

1. add exact event-to-slot authority for `ECHO_ONSET`, `ECHO_PEAK`, and `ECHO_TAIL`;
2. resolve production streams from `AudioRegistry` without hardcoded duplicate paths;
3. keep the dedicated shared 2D `_echo_voice` playback owner;
4. preserve phase timing exactly at 0.28 / 1.10 / 0.45 s;
5. preserve `MEMORY_ECHO` radio duck/mix ownership;
6. preserve all three procedural generators as independently reachable fallbacks;
7. align `echo.bed_loop` playback metadata with the actual bounded PEAK phase rather than creating a new indefinite loop;
8. preserve `reset_echo()` and `reset_audio_instant()` leak-free behavior;
9. preserve disturbance authorization only after Echo completion;
10. preserve authored Echo payload and Mission 01 extraction routes through the same audio lifecycle.

## Completion

01J candidate-search checkpoint is complete when one human-auditioned winner and runner-up exist for each live phase, the three winners pass a real-timing arc audition, and no production WAV or runtime mutation has been introduced during search.