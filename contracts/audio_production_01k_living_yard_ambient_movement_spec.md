# Audio Production 01K — Living Yard Ambient Life & Courier Movement Pack

**State:** SOURCES_SELECTED__IMPLEMENTATION_PENDING  
**Baseline:** `main@3c8ceb6f59c5a3fbe1ee5da15da3da0b33917be3`

## Objective

Promote two selected living-yard sounds and retain one future world-radio candidate:

1. `player.footstep` — live courier movement transient;
2. `world.ambient_wind` — activate one bounded continuous ambient bed;
3. `world.radio_chatter` — retention-only until a real source/scheduler exists.

Do not change courier locomotion, movement speed, step cadence, add a surface classifier, alter vehicle physics, attach chatter to arbitrary actors, change Yardline programming, or create random world-radio scheduling.

## Locked selections

### Courier Footstep — promote

Selected source:

`GTA_SA:FEET:BANK_0:SOUND_4`

Characteristics:

- duration: `0.1655 s`;
- native sample rate: `17,000 Hz`;
- mono 16-bit PCM;
- raw bytes: `5,672`;
- frames: `2,814`;
- raw SHA-256: `14fd68f67bf5208f5a2ed47eb858eed0cae68605892d28f881714ba2ec58ccc7`;
- reinforced courier work boot on salvage tarmac / dusty industrial ground;
- 25-step cadence audition passed at both ~0.35 s and ~0.20 s intervals;
- no machine-gun buildup, hollow ringing, or fatigue;
- approved treatment: only ~`1.5 ms` boundary taper;
- no gain normalization, resampling, EQ, compression, reverb, or time stretching.

Runners-up `FEET:BANK_0:SOUND_1` and `FEET:BANK_3:SOUND_3` remain audition evidence only.

Canonical production path:

`res://audio/player/sfx_player_footstep.wav`

### Scrapyard Ambient Wind — promote and activate

Selected source:

`GTA_SA:SCRIPT:BANK_350:SOUND_0`

Characteristics:

- duration: `4.4999 s`;
- native sample rate: `23,300 Hz`;
- mono 16-bit PCM;
- raw bytes: `209,740`;
- frames: `104,848`;
- raw SHA-256: `94783a84f5a8fe8a3e707b80412dc8b2ecd75cb63e933704de94837987a22cc4`;
- open dry scrapyard/desert air-flow identity;
- no musical pitch center or strong gust landmark;
- 30+ second continuous-loop audition passed with low fatigue;
- candidate judged suitable beneath traversal and living-yard activity;
- approved treatment: preserve native rate/duration and apply one subtle **80 ms equal-power circular seam blend** only;
- no normalization, resampling, EQ, compression, reverb, or time stretching.

Runner-up `GENRL:BANK_137:SOUND_0` remains audition evidence only.

Canonical production path:

`res://audio/world/amb_world_scrapyard_wind.wav`

### World Radio Chatter — retention only

Selected source:

`GTA_SA:SCRIPT:BANK_358:SOUND_26`

Characteristics:

- duration: `0.7623 s`;
- native sample rate: `15,000 Hz`;
- mono 16-bit PCM;
- raw bytes: `22,912`;
- raw SHA-256: `c255bfe681acc0c1bc7febbf8c64448513595190f3d39cf25075b66204093321`;
- narrow-band intercepted telemetry / clipped dispatcher residue;
- non-narrative and unintelligible in audition;
- approved future one-shot treatment: ~`1.5 ms` boundary taper only.

Runners-up `SCRIPT:BANK_358:SOUND_32` and `SCRIPT:BANK_359:SOUND_9` remain audition evidence only.

01K decision: **RETENTION ONLY**.

Do not create a production WAV, source path, `SoundEvent`, scheduler, random timer, actor attachment, or 3D source anchor for `world.radio_chatter` in 01K.

## Runtime authority

### Footstep

Footstep is live end-to-end:

`PlayerRunner.footstep_triggered -> ScrapTestBlock._on_player_footstep() -> AudioManager.play_event(FOOTSTEP, player.global_position)`.

Existing authority must remain unchanged:

- PlayerRunner cadence threshold remains 3 accumulated movement units;
- `SoundEvent.FOOTSTEP` ordinal remains unchanged;
- `EVENT_TO_SLOT_MAP` remains `FOOTSTEP -> player.footstep`;
- cooldown remains 120 ms;
- fallback remains 320 Hz / 0.04 s / volume 0.25;
- shipping production playback remains bounded 3D at supplied courier position;
- `unit_size = 8.0`;
- no new `max_distance` override;
- one sample only; no randomizer or surface classifier.

### Ambient Wind

Baseline main has no wind `SoundEvent` or player. 01K activates the already-registered continuous semantic slot as a narrow presentation layer.

Runtime ownership:

- one `AudioStreamPlayer` named `AmbientWindPlayer` owned by `AudioManager`;
- non-spatial 2D playback, matching registry metadata;
- registry-backed production path only;
- no Wind `SoundEvent` and no event-to-slot mapping;
- stream loops continuously with imported/loaded forward-loop semantics;
- player starts during AudioManager ready when production media is available;
- base mix level: `-18 dB`;
- priority-duck level: `-30 dB` during `DISTURBANCE`, `PURSUIT_PRESSURE`, and `MEMORY_ECHO`;
- returns to `-18 dB` in non-critical states;
- no per-frame tween churn and no second wind voice.

Reset ownership:

- `AudioManager.reset_audio_instant()` must stop Wind synchronously so the authoritative reset is immediately silent;
- because the guarded repository API cannot safely patch the 8k-line prototype controller without whole-file replacement, AudioManager owns one deferred, idempotent post-reset `start_ambient_wind()` re-arm on the next process turn;
- the re-arm uses no timer and creates no new player node;
- repeated resets/restarts must preserve exactly one `AmbientWindPlayer`;
- there is no gameplay-state mutation or caller-specific Wind event.

This is presentation-layer activation only. Wind has no gameplay-state authority.

### World Radio Chatter

Runtime remains unchanged:

- no `RADIO_CHATTER` SoundEvent;
- no AudioManager mapping/player;
- no scheduler;
- no world source anchor;
- registry remains `PROCEDURAL_FALLBACK`, replacement-required, without a production path.

## Registry changes

### `player.footstep`

Promote to:

- `LICENSED_FINAL` internal production status;
- `replacement_required = false`;
- path `res://audio/player/sfx_player_footstep.wav`;
- provenance `GTA_SA:FEET:BANK_0:SOUND_4`.

All other semantic metadata remains unchanged.

### `world.ambient_wind`

Promote to:

- `LICENSED_FINAL` internal production status;
- `replacement_required = false`;
- path `res://audio/world/amb_world_scrapyard_wind.wav`;
- provenance `GTA_SA:SCRIPT:BANK_350:SOUND_0`;
- `CONTINUOUS_LOOP`, `is_looping = true` retained;
- loop metadata aligned to selected natural source: `loop_start_sec = 0.0`, `loop_end_sec = 4.4999`.

### `world.radio_chatter`

No promotion. Record candidate only in retention evidence.

`LICENSED_FINAL` is the project-internal production status and is not an independent legal/license-clearance claim.

## Production treatment

### Footstep WAV

- mono PCM16;
- 17,000 Hz;
- ~0.1655 s;
- same frame count/length as selected source;
- only ~1.5 ms one-shot boundary taper;
- no gain normalization/resampling/EQ/compression/reverb/time stretching.

### Wind WAV

- mono PCM16;
- 23,300 Hz;
- ~4.4999 s;
- preserve frame count and natural duration;
- apply only an 80 ms equal-power circular seam blend to the loop boundary;
- no one-shot taper;
- no normalization/resampling/EQ/compression/reverb/time stretching;
- Godot import loop mode must be enabled for the full stream.

## Automated verification

Exact-head 01K contract must prove:

### Footstep

- exact event/slot mapping;
- exact path/provenance;
- mono PCM16, 17,000 Hz, ~0.1655 s;
- stream resolves through existing production transient cache;
- production playback creates one `AudioStreamPlayer3D` at supplied world position;
- `unit_size = 8.0`;
- no new max-distance override;
- old 320 Hz / 0.04 s procedural fallback remains independently reachable;
- cooldown/voice budget semantics remain unchanged.

### Wind

- exact path/provenance;
- mono PCM16, 23,300 Hz, ~4.4999 s;
- slot remains continuous/non-spatial;
- stream is loop-enabled;
- exactly one AudioManager-owned `AmbientWindPlayer` uses the selected stream;
- player is non-spatial `AudioStreamPlayer`, Master bus, and playing after ready;
- CALM/non-critical level is `-18 dB`;
- DISTURBANCE/PURSUIT_PRESSURE/MEMORY_ECHO level is `-30 dB` while playback continues;
- return to CALM restores `-18 dB`;
- direct `reset_audio_instant()` stops Wind synchronously;
- explicit/idempotent `start_ambient_wind()` restarts cleanly with no duplicate player;
- deferred post-reset re-arm uses the same player authority.

### Chatter retention

- `world.radio_chatter` remains procedural/replacement-required;
- no production path/provenance;
- no AudioManager event mapping.

Regression verification must include Audio Runtime, living-yard/world-life assertions, 01J Memory Echo, 01H, 01G, 01F, 01D, 01C, 01B, semantic manifest, replay/reset, and canonical Web compatibility.

## Human native verification

One exact-head session must cover:

- 25+ footstep traversal at slow and fast cadence;
- footstep 3D localization to courier movement;
- calm-yard Wind loop for at least 30 seconds;
- Wind + Footstep + worker/crawler activity;
- Wind under bike engine and Yardline radio;
- disturbance/pursuit/Memory Echo priority ducking;
- replay/reset with immediate stop then next-frame Wind re-arm and no duplicate loop;
- absence of any new world-radio chatter playback.

Judge fatigue, seam quality, masking, localization, artifacts, and production-vs-procedural improvement.

## Completion

01K reaches PASS only when Footstep and Wind have exact-head automated proof, exact-head native listening, fresh Standards/Spec review, merged PR, exact-main CI, and current playtest provenance. Radio Chatter remains retention-only and does not count as a production promotion.