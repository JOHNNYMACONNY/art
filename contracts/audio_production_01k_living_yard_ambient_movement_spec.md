# Audio Production 01K — Living Yard Ambient Life & Courier Movement Pack

**State:** CANDIDATE_SELECTION_REQUIRED__MIXED_RUNTIME_AUTHORITY  
**Baseline:** `main@3c8ceb6f59c5a3fbe1ee5da15da3da0b33917be3`

## Objective

Batch source search and perceptual identity work for three living-yard / courier movement slots:

1. `player.footstep` — courier industrial-yard movement transient;
2. `world.ambient_wind` — continuous dry scrapyard/desert wind bed;
3. `world.radio_chatter` — sporadic intercepted telemetry / yard-radio burst.

The three slots do **not** currently have equal runtime authority. Candidate search may cover all three now, but promotion must follow the authority boundary documented below rather than inventing fake callers.

Do not change courier locomotion, movement speed, step cadence, vehicle physics, living-yard actor behavior, pursuit state, Memory Echo behavior, or Yardline program logic merely to justify an audio asset.

## Runtime authority findings on baseline main

### 1. `player.footstep` — live end-to-end

`PlayerRunner` owns the movement cadence:

- while unmounted, unlocked, and moving, `_step_timer` accumulates by `delta * velocity.length()`;
- every `> 3.0` accumulated movement units it emits `footstep_triggered`;
- cadence therefore already scales with actual movement speed;
- the signal is reset when standing still.

`ScrapTestBlock._ready()` connects:

`player.footstep_triggered -> _on_player_footstep()`

and `_on_player_footstep()` calls:

`audio_mgr.play_event(AudioManager.SoundEvent.FOOTSTEP, player.global_position)`.

`AudioManager` authority:

- `SoundEvent.FOOTSTEP` exists;
- `EVENT_TO_SLOT_MAP` maps it to `player.footstep`;
- cooldown: `120 ms`;
- current procedural fallback: `320 Hz`, `0.04 s`, volume `0.25` synth click;
- fallback playback uses the existing bounded 3D transient path with `unit_size = 8.0`.

Registry intent:

- domain: PLAYER;
- DIEGETIC;
- DIEGETIC_3D;
- mix group: INCIDENTAL_UI;
- TRANSIENT;
- non-looping;
- cooldown: 120 ms;
- max concurrency: 4;
- PROCEDURAL_FALLBACK / replacement-required.

**Disposition:** fully eligible for production-media replacement in 01K after source lock.

Important scope boundary: main has **no surface-material footstep classifier**. 01K must therefore select one versatile scrapyard/industrial-yard footstep identity unless a separate surface-authority feature is explicitly authored later. Do not add material detection as a hidden side effect of this audio slice.

### 2. `world.ambient_wind` — registered continuous bed, no live playback owner

Registry intent:

- domain: WORLD;
- DIEGETIC;
- spatial type: NON_DIEGETIC_2D;
- mix group: AMBIENT_TEXTURE;
- CONTINUOUS_LOOP;
- `is_looping = true`;
- nominal loop window `0.0–5.0 s`;
- max concurrency: 1;
- PROCEDURAL_FALLBACK / replacement-required.

Baseline runtime has:

- no `AMBIENT_WIND` SoundEvent;
- no event-to-slot mapping;
- no dedicated wind `AudioStreamPlayer`;
- no wind stream in `AudioManager`;
- no `ambient_wind` caller in `ScrapTestBlock`;
- no authored wind player in the prototype scene.

Existing living-yard ambient behavior instead comes from concrete actors: Scrap Workers emit `AMBIENT_WORK_CLINK`, and the Utility Crawler emits `AMBIENT_SERVO_HUM`.

**Disposition:** candidate audition is authorized now. Runtime promotion is a narrow presentation-feature activation, not a simple media swap.

If the selected source passes the real loop/fatigue gate, 01K may later activate this slot using one bounded registry-backed non-spatial ambient player owned by `AudioManager`, with no gameplay-state authority and no duplicate wind voices. Exact mix-state duck/suppression behavior must be test-first and native-listened before merge. If no low-fatigue loop candidate passes, retain the best evidence without forcing production.

### 3. `world.radio_chatter` — registry-only, no source/caller authority

Registry intent:

- domain: WORLD;
- DIEGETIC;
- DIEGETIC_3D;
- mix group: RADIO_MUSIC;
- TRANSIENT;
- non-looping;
- cooldown: `3000 ms`;
- max concurrency: 1;
- PROCEDURAL_FALLBACK / replacement-required.

Baseline runtime has:

- no `RADIO_CHATTER` SoundEvent;
- no event-to-slot mapping;
- no procedural fallback branch;
- no chatter scheduler;
- no world position/source anchor for a chatter burst;
- no caller in Scrap Workers, Utility Crawler, missions, or the prototype controller.

Existing Yardline vehicle radio is a separate authored radio subsystem and must not be conflated with this world diegetic slot.

**Disposition:** candidate audition / retention is authorized now. Production promotion remains gated until a real world source and deterministic scheduling authority exist. Do not attach chatter arbitrarily to a worker/crawler or add a random timer merely to make the selected WAV audible.

## Candidate source restriction

Use only the owner-authorized local GTA San Andreas audio library already accepted for production-audio work.

Record exact source provenance as:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Candidate copies remain local/gitignored. Candidate search does not authorize production WAV ingestion.

## Target A — Courier Footstep

Desired identity:

- compact work-boot / reinforced courier step;
- believable on salvage tarmac, dusty industrial ground, and occasional metal plating without requiring a surface classifier;
- some hard sole / grit / light metal character is useful, but avoid a huge resonant clang every step;
- clear enough to read beneath wind, bike staging, and ambient worker sounds;
- small-speaker friendly;
- short decay so running cadence does not smear;
- neutral enough for repeated traversal over long play sessions.

Preferred natural duration:

`0.07–0.24 s`

Current fallback to beat:

- 320 Hz procedural click;
- 0.04 s;
- volume 0.25;
- 3D at courier position;
- unit_size 8.

Audition against existing production cues:

- Bike Mount / Dismount;
- Panel Peel;
- Collision Glance;
- Wire Spark.

Reject candidates that read as:

- a generic UI click;
- a gunshot;
- a collision impact;
- a door/latch;
- a heavy hollow clang that becomes exhausting every step;
- a long gravel scrape that piles up at running cadence.

### Footstep repetition gate

Do not select from isolated one-shot listening alone.

For every serious finalist:

- audition at approximately the existing runtime cadence;
- run at least 20–30 consecutive steps;
- test both slower movement and full-speed running cadence;
- check harshness, machine-gun repetition, resonant buildup, and masking;
- test on laptop/phone-class speakers if practical.

One primary sample is being selected. Do not create a multi-sample randomizer or surface system during candidate search.

## Target B — Scrapyard Ambient Wind

Desired identity:

- dry open-yard wind / desert industrial air;
- dusty, broad-band texture with subtle movement;
- enough low-mid body to make the yard feel exposed, but not deep rumble that masks engine or dialogue/radio;
- may contain faint distant metal-air resonance if non-rhythmic and non-identifying;
- must remain unobtrusive over long traversal;
- no obvious musical pitch center;
- no strong one-shot gust every cycle.

Preferred natural source/loop length:

`3.0–8.0 s`

The registry's nominal historical loop window is 5.0 s, but candidate quality is more important than forcing an exact 5.0-second source. Do not resample or time-stretch solely to hit five seconds.

Reject:

- rain;
- ocean/surf;
- engine idle;
- siren-like wind tones;
- music pads;
- loud sandstorm blasts;
- loop candidates with obvious rhythmic cycling.

### Wind loop gate

For every serious finalist:

- loop continuously for at least 30 seconds;
- listen for seam clicks/pops;
- listen for periodic pumping or obvious repeated gust landmarks;
- test long-term fatigue;
- verify it sits beneath vehicle engine, footsteps, ambient worker clinks, pursuit alert, and Yardline radio;
- note whether a minimal loop crossfade is required.

Do **not** apply a one-shot boundary taper blindly to a loop candidate. Loop treatment must follow actual seam behavior.

## Target C — World Radio Chatter

Desired identity:

- short intercepted telemetry / damaged yard-radio burst;
- narrow-band, filtered, electrically imperfect communication texture;
- diegetic-world identity rather than in-head Echo or polished vehicle music radio;
- brief enough to remain incidental;
- preferably partially unintelligible / abstract enough not to import recognizable GTA-world character identity into Echos;
- may include carrier crackle, clipped syllabic texture, data-like chatter, or dispatch residue;
- should feel like a remote industrial communication, not a mission instruction.

Preferred natural duration:

`0.35–2.0 s`

Audition against:

- Yardline vehicle radio program;
- Echo radio interference texture / Memory Echo arc;
- Disturbance Alert;
- Signal Lock.

Reject:

- clearly recognizable named-character dialogue;
- long intelligible mission/police speech;
- comedic GTA-specific lines;
- music or station IDs;
- sirens;
- pure static with no communication identity;
- loud alert beeps that resemble Disturbance Alert.

### Chatter fatigue gate

For finalists:

- audition 5–8 bursts with at least ~3 seconds separation;
- verify no burst becomes narratively distracting;
- verify voice texture does not conflict with Yardline DJ/content;
- verify small-speaker intelligibility of the *radio texture* without requiring semantic word comprehension.

Because no live chatter source/caller exists, do not invent positional assumptions during audition. Judge the source itself for future 3D use and report whether its spectral content should survive normal 3D attenuation.

## Search scope

Start with:

- `GENRL`;
- `SCRIPT`.

Expand deliberately if the indexed GTA library contains more appropriate banks for:

- footsteps / boots / impacts;
- wind / exterior ambience;
- radio communication / dispatch / telemetry.

For radio chatter, prefer short generic filtered communication textures over recognizable authored dialogue.

Aim for approximately:

- 4–6 Footstep candidates;
- 3–5 serious Wind loop candidates;
- 4–6 Radio Chatter candidates.

Approximately 12–17 serious audition assets are sufficient. Do not bulk-extract hundreds of files.

## Candidate report requirements

For every serious candidate return:

- candidate ID;
- target slot;
- pak;
- bank;
- sound index;
- duration;
- native sample rate;
- channels;
- bit depth;
- raw bytes;
- raw SHA-256;
- PASS / REJECT;
- listening identity;
- neighboring-production distinction;
- small-speaker readability;
- repetition / long-loop fatigue result;
- boundary integrity;
- gain change needed;
- resampling needed;
- boundary/loop treatment needed;
- EQ/compression/reverb/time-stretch needed.

Prefer sources requiring no gain, resampling, EQ, compression, reverb, or time stretching.

## Final selection report

### Footstep — Selected

Return exact source metadata plus:

- industrial-yard identity;
- slower vs running cadence result;
- 20–30 step fatigue result;
- distinction from Bike Mount/Dismount and Collision Glance;
- small-speaker readability;
- recommended production treatment.

Runner-up:

- source;
- reason not selected.

### Ambient Wind — Selected

Return exact source metadata plus:

- 30-second loop test;
- seam quality;
- repeated-gust periodicity;
- engine/radio/footstep masking result;
- long-term fatigue;
- continuous-loop suitable: YES / NO;
- exact proposed loop treatment.

Runner-up:

- source;
- reason not selected.

### World Radio Chatter — Selected

Return exact source metadata plus:

- telemetry/radio identity;
- recognizable GTA-specific speech risk: LOW / MEDIUM / HIGH;
- distinction from Yardline radio;
- distinction from Echo/interference;
- 5–8 burst fatigue result;
- expected 3D readability;
- recommended future production treatment.

Runner-up:

- source;
- reason not selected.

## Three-way pack discrimination

Report:

- Footstep vs ambient life bed: PASS / FAIL;
- Wind vs Chatter: PASS / FAIL;
- Chatter vs Yardline/Echo radio identity: PASS / FAIL;
- overall extraction integrity: PASS / FAIL.

## Production boundary after audition

Candidate search itself must not:

- add production WAVs or imports;
- promote registry status;
- add SoundEvents;
- add ambient players/schedulers;
- change player step cadence;
- add a surface classifier;
- attach chatter to arbitrary actors;
- modify Yardline program behavior.

After source selection:

- Footstep may proceed directly to production integration;
- Wind may proceed only if the loop candidate passes and the bounded ambient-player feature contract is implemented test-first;
- Radio Chatter remains retention-only until a real source/scheduling authority is authored.

## Candidate-search completion

The 01K candidate-search checkpoint is complete when one human-auditioned winner and runner-up exist for each target, Footstep passes real cadence repetition, Wind passes a 30-second loop test or is explicitly retained-only, Chatter is evaluated for future 3D readability without inventing a caller, and no production/runtime mutation has occurred during search.