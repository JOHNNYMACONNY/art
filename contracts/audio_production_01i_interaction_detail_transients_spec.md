# Audio Production 01I — Interaction Detail Transients Pack

**State:** CANDIDATE_SEARCH__RUNTIME_AUTHORITY_GATED  
**Baseline:** `main@ca7f9643150ade9e83c7cdd47684d8f2ddde59ee`

## Objective

Batch candidate search and perceptual identity work for three reserved interaction-detail slots:

1. `interaction.panel_pry` — initial crowbar leverage / corroded metal stress;
2. `interaction.wire_clip` — precision wire-cutter snip / mechanical clip;
3. `interaction.battery_insert` — solid power-cell insertion / bay lock.

This slice is intentionally authority-gated. Candidate audition may proceed now, but production promotion is not authorized until each sound has a real gameplay event and timing point.

Do not invent placeholder mechanics solely to justify using an audio asset.

## Runtime authority findings on baseline main

### `interaction.panel_pry` — not live

Registry intent:

- domain: INTERACTION;
- diegesis: DIEGETIC;
- spatial type: DIEGETIC_3D;
- mix group: INCIDENTAL_UI;
- playback type: TRANSIENT;
- cooldown: 100 ms;
- max concurrency: 2;
- asset status: PROCEDURAL_FALLBACK;
- replacement required: true.

Actual gameplay authority:

- `CorrodedPanel` has no separate pry state or pry audio event;
- active sequence is `IDLE -> APPROACHED -> PEELING -> EXPOSED -> EXTRACTED`;
- `trigger_action()` immediately enters `PEELING` and emits `PANEL_PEEL`;
- no `PANEL_PRY` `SoundEvent` exists in `AudioManager`;
- no `EVENT_TO_SLOT_MAP` entry maps to `interaction.panel_pry`;
- no procedural fallback branch exists for a pry event.

Production disposition: **AUDITION/RETENTION ONLY** until a real pry interaction step exists.

### `interaction.wire_clip` — not live

Registry intent:

- domain: INTERACTION;
- diegesis: DIEGETIC;
- spatial type: DIEGETIC_3D;
- mix group: INCIDENTAL_UI;
- playback type: TRANSIENT;
- cooldown: 100 ms;
- max concurrency: 2;
- asset status: PROCEDURAL_FALLBACK;
- replacement required: true.

Actual gameplay authority:

- current extraction flow exposes core and completes extraction without a separate wire-cut state;
- current completion path emits existing `COMPLETION` and `SPARK` semantics;
- no `WIRE_CLIP` `SoundEvent` exists in `AudioManager`;
- no `EVENT_TO_SLOT_MAP` entry maps to `interaction.wire_clip`;
- no procedural wire-clip branch exists.

Production disposition: **AUDITION/RETENTION ONLY** until a real wire-cut interaction step exists.

### `interaction.battery_insert` — not live

Registry intent:

- domain: INTERACTION;
- diegesis: DIEGETIC;
- spatial type: DIEGETIC_3D;
- mix group: INCIDENTAL_UI;
- playback type: TRANSIENT;
- cooldown: 0 ms;
- max concurrency: 2;
- asset status: PROCEDURAL_FALLBACK;
- replacement required: true.

Actual gameplay authority:

- current interaction tree contains no power-cell insertion mechanic;
- no battery-insert gameplay signal is emitted;
- no `BATTERY_INSERT` `SoundEvent` exists in `AudioManager`;
- no `EVENT_TO_SLOT_MAP` entry maps to `interaction.battery_insert`;
- no procedural battery-insert branch exists.

Production disposition: **AUDITION/RETENTION ONLY** until a real battery insertion mechanic exists.

## Existing retained 01E incumbents

01I must not discard prior human-auditioned evidence. Treat these as incumbent candidates to beat:

### Panel Pry incumbent

- source: `GTA_SA:GENRL:BANK_143:SOUND_40`;
- duration: `0.1547 s`;
- native sample rate: `22,050 Hz`;
- mono 16-bit PCM;
- raw SHA-256: `3205a8aa7708517f6b036dfa89b66def9c4cf997efae790675e4657024b56127`.

### Wire Clip incumbent

- source: `GTA_SA:GENRL:BANK_143:SOUND_48`;
- duration: `0.0751 s`;
- native sample rate: `22,050 Hz`;
- mono 16-bit PCM;
- raw SHA-256: `c98b758a7463f8667be351cf9a16181e1c04b5ea0a57b9a20aa25345c62846e9`.

### Battery Insert incumbent

- source: `GTA_SA:GENRL:BANK_100:SOUND_0`;
- duration: `0.3132 s`;
- native sample rate: `17,968 Hz`;
- mono 16-bit PCM;
- raw SHA-256: `0668e15e846ce1cae9e2b77fc5955219bb5393745385ecfe84721a7d31682db6`.

These remain retention evidence only. No production WAVs for these sources currently belong in Git.

## Candidate search target A — Panel Pry

Desired identity:

- initial crowbar leverage against a seized/corroded metal panel;
- short stress-creak, metal flex, latch strain, or compact leverage groan;
- physically distinct from the already-produced `interaction.panel_peel` long peel/shear sound;
- suggests the moment resistance breaks or leverage bites before continuous peel motion;
- enough midrange texture for laptop/phone speakers;
- not a full crash, door slam, gunshot, explosion, or long scrape.

Preferred natural duration: approximately `0.10–0.45 s`.

Audition against existing production `PANEL_PEEL`. The pair should read as:

`PRY = initial leverage/stress`  
`PEEL = sustained panel removal/shear`

If a candidate sounds like a shortened peel rather than a distinct first action, reject it.

## Candidate search target B — Wire Clip

Desired identity:

- precise cutter/plier snip;
- small mechanical jaw close, wire sever, or spring-steel clip action;
- dry, immediate and tactile;
- distinct from `interaction.wire_spark` electrical arc;
- audible on small speakers without becoming a sharp digital click;
- tolerable if repeated for multiple wires.

Preferred natural duration: approximately `0.04–0.25 s`.

Audition against existing production `WIRE_SPARK`. The pair should read as:

`CLIP = tool/mechanical cut`  
`SPARK = electrical consequence`

Reject candidates that sound primarily electrical, glassy, gunshot-like, or like a UI click.

## Candidate search target C — Battery Insert

Desired identity:

- compact but solid power-cell seating action;
- body/thud plus latch or bay-lock component is ideal;
- communicates weight and secure mechanical engagement;
- not an engine start, giant door slam, collision, or electronic success chime;
- distinguishable from bike mount/dismount latches and Core Extracted;
- enough low-mid body for small speakers without sub-bass dependence.

Preferred natural duration: approximately `0.12–0.55 s`.

Audition against existing production:

- `player.bike_mount`;
- `player.bike_dismount`;
- `interaction.core_extracted`.

Battery Insert should read as a heavier contained bay lock rather than rider hardware or a core release.

## Search scope

Use only the owner-authorized local GTA San Andreas audio library already accepted for production-audio work.

Start with:

- `GENRL`;
- `SCRIPT`.

Search mechanical families broadly:

- doors / latches / catches;
- hand tools / clips / snaps;
- metal stress / scrape / flex;
- switches / relays;
- vehicle interior hardware;
- container / hatch / bay mechanisms;
- compact impacts and insertion sounds.

Aim for approximately 4–6 credible candidates per target. Include the retained 01E incumbent in each target's final comparison even if it would not otherwise surface in the new search.

Do not extract hundreds of files. Rough target: 12–18 total candidates plus incumbents.

## Audition quality gate

Human listening is authoritative.

For each target:

1. audition raw candidates individually;
2. compare top candidates against the retained incumbent;
3. compare against neighboring production sounds listed above;
4. perform a 5–8 repetition fatigue test;
5. test on built-in laptop/phone-class speakers if practical;
6. choose a winner only if it is meaningfully more specific to the intended mechanic than the incumbent.

If the incumbent remains best, keep it. Do not change source just to create novelty.

## Candidate report requirements

For each candidate report:

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
- listening description;
- comparison with retained incumbent;
- distinction from neighboring production cue;
- small-speaker readability;
- repetition/fatigue result;
- boundary pop/truncation/pitch/PCM artifact status;
- gain change needed;
- boundary taper needed;
- resampling needed;
- other processing needed.

## Final selection report

Return one retained winner + runner-up per target.

### Panel Pry — Selected

Report exact source metadata plus:

- why it reads as initial leverage rather than sustained peel;
- direct comparison with `GENRL:143:40` incumbent;
- distinction from production Panel Peel;
- recommended future production treatment.

### Wire Clip — Selected

Report exact source metadata plus:

- why it reads as tool cut rather than spark;
- direct comparison with `GENRL:143:48` incumbent;
- distinction from production Wire Spark;
- recommended future production treatment.

### Battery Insert — Selected

Report exact source metadata plus:

- why it reads as weighted cell seating/lock;
- direct comparison with `GENRL:100:0` incumbent;
- distinction from Bike Mount/Dismount and Core Extracted;
- recommended future production treatment.

## Production boundary

01I candidate search does **not** authorize integration.

Until runtime authority exists, do not:

- add production WAVs under `godot/audio/interaction/`;
- add `.wav.import` files;
- promote registry status;
- add source provenance or production paths to these slots;
- add `SoundEvent` values;
- add AudioManager mappings or playback branches;
- add fake pry/wire/battery mechanics;
- alter the current Corroded Panel sequence.

After audition, the next valid step is one of:

1. **RETENTION PASS** — record better/final candidate identities and stop; or
2. **FEATURE-AUTHORITY PLAN** — separately design/authorize real interaction steps before audio production promotion.

## Completion for this phase

This 01I opening phase reaches its candidate-search checkpoint when:

- runtime authority remains accurately documented;
- one human-auditioned winner is identified for each reserved slot;
- retained incumbents were explicitly compared;
- no production asset or fake gameplay event was added.
