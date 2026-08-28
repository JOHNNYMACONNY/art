# Audio Production 01L — Continuous Signature Loops Pack

**State:** CANDIDATE_SELECTION_REQUIRED  
**Baseline:** `main@978f13a6d8d6908b1e571d1be573de3c8cd0d1f5`

## Objective

Replace three live procedural continuous-loop identities with production media while preserving their existing runtime owners and modulation logic:

1. `vehicle.engine_rev` — active courier vehicle propulsion / drivetrain loop;
2. `pursuit.siren_alarm` — spatial pursuer threat siren loop;
3. `echo.radio_interference` — hybrid precursor-Echo radio contamination loop.

All three targets are already live on main. 01L is media replacement plus narrow registry/runtime stream resolution only. Do not create new gameplay mechanics, new loop owners, new pursuit rules, new radio rules, or new vehicle physics.

## Runtime authority on baseline main

### 1. `vehicle.engine_rev` — live continuous vehicle feedback

Registry intent:

- domain: VEHICLE;
- DIEGETIC;
- DIEGETIC_3D;
- mix group: VEHICLE_FEEDBACK;
- CONTINUOUS_LOOP;
- `is_looping = true`;
- max concurrency: 2;
- PROCEDURAL_FALLBACK / replacement-required.

Current AudioManager owner:

- one existing `AudioStreamPlayer3D` named `EngineRevPlayer`;
- Master bus;
- `unit_size = 12.0`;
- `max_distance = 30.0`;
- current fallback stream: `0.5 s` procedural noise loop;
- player follows active vehicle world position.

Current modulation authority is **not optional** and must be preserved.

Courier Bike rich feedback path (`VehicleFeedbackLayer`):

- speed ratio: `0.0–1.0`;
- load ratio: `0.0–1.0`;
- stop if speed `<= 0.01` and load `<= 0.03`;
- pitch scale: `clamp(0.76 + speed*1.05 + load*0.28, 0.72, 2.12)`;
- gain: `clamp(-25 + speed*11 + load*7, -25 dB, -6 dB)`;
- priority states cap engine gain at `-12 dB`;
- no production replacement may change vehicle telemetry or those formulas.

Legacy/shared vehicle path:

- active vehicle position is supplied continuously;
- speed-responsive pitch remains part of the compatibility path for vehicles not currently driven by the richer feedback layer.

**Candidate consequence:** the selected loop must tolerate a very wide runtime pitch/speed range. A source that sounds good only at native pitch is not acceptable.

### 2. `pursuit.siren_alarm` — live continuous threat loop

Registry intent:

- domain: PURSUIT;
- DIEGETIC;
- DIEGETIC_3D;
- mix group: CRITICAL_THREAT;
- CONTINUOUS_LOOP;
- `is_looping = true`;
- max concurrency: 2;
- PROCEDURAL_FALLBACK / replacement-required.

Current AudioManager owner:

- one existing `AudioStreamPlayer3D` named `SirenAlarmPlayer`;
- Master bus;
- `unit_size = 15.0`;
- `max_distance = 35.0`;
- current fallback: `440 Hz`, `0.6 s` looping tone.

Pursuit pressure authority:

- pursuit pressure `p = clamp((20m - distance) / 15m, 0, 1)`;
- siren follows pursuer world position;
- pitch scale sweeps `1.0 -> 1.45` as pressure rises;
- gain sweeps `-4 dB -> +3 dB` as pressure rises;
- release decay preserves the same owner and eases pitch/gain down before stopping;
- Disturbance Alert, Intercept impact, tension layer, radio ducking, and pursuit state ownership remain separate.

**Candidate consequence:** audition at both native pitch and up to `1.45x` pitch/speed. The winner must remain urgent without becoming shrill or comical at maximum pressure.

### 3. `echo.radio_interference` — live gated hybrid loop

Registry intent:

- domain: ECHO;
- HYBRID diegesis;
- HYBRID spatial type;
- mix group: SIGNATURE_ECHO;
- CONTINUOUS_LOOP;
- `is_looping = true`;
- max concurrency: 1;
- PROCEDURAL_FALLBACK / replacement-required.

Current AudioManager owner:

- one existing `AudioStreamPlayer3D` named `RadioInterferencePlayer3D`;
- Master bus;
- `unit_size = 8.0`;
- `max_distance = 25.0`;
- current fallback: `1.0 s` procedural fractured-carrier loop;
- world position is the precursor/corroded-panel source position.

Live eligibility gates are already authored in the prototype controller:

- world state must be PANEL_POWERED;
- an active vehicle must exist;
- that vehicle must own the radio;
- radio must be enabled and actively streaming;
- otherwise interference is cleared immediately.

Distance/intensity authority:

- outer radius: `18 m`;
- inner radius: `3 m`;
- intensity rises continuously from 0 to 1 while approaching the source;
- base 3D voice gain rises approximately `-30 dB -> -12 dB` with intensity;
- contamination also applies up to `-4 dB` of radio suppression;
- pursuit pressure attenuates the interference further;
- DISTURBANCE attenuates it;
- MEMORY_ECHO suppresses it completely;
- critical interception duck suppresses it completely;
- reset/intercept clears the interference.

**Candidate consequence:** this is not the 01J Memory Echo arc and not a normal radio program. It must survive quiet low-level looping and remain identifiable when close, yet yield cleanly to threat and full Memory Echo states.

## Shared implementation constraints after source lock

Future 01L integration must:

- preserve the existing three player nodes;
- resolve production media from `AudioRegistry` rather than duplicate hardcoded paths;
- preserve existing unit sizes and max distances exactly;
- preserve all current pitch/gain/distance formulas;
- preserve all current start/stop/reset ownership;
- preserve each procedural fallback independently when its production stream is absent;
- allow one missing production loop without disabling the other two;
- avoid new timers, players, schedulers, or gameplay state;
- use loop-enabled imports and runtime streams;
- align registry loop window metadata to the selected natural loop only after human source selection.

## Owner-authorized candidate source boundary

Use only the owner-authorized local GTA San Andreas audio library already accepted for production-audio work.

For every candidate record exact provenance:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Candidate staging stays local/gitignored. Do not create production WAVs during this search.

## Target A — `vehicle.engine_rev`

Desired identity:

- compact electric / turbine / reclaimed propulsion texture;
- mechanical enough to feel attached to a physical courier vehicle;
- tonal/noisy balance that remains useful under runtime pitch modulation;
- enough low-mid body at low pitch/load;
- enough upper mechanical detail at high pitch/load;
- no obvious combustion-cylinder rhythm unless extremely abstract;
- should work for the existing shared vehicle presentation without forcing a new per-vehicle engine asset system;
- must sit beneath collision, brake, pursuit, and radio cues.

Preferred natural source length:

`0.8–3.0 s`

Longer candidates may be considered if their loop is exceptionally neutral and compact in memory footprint.

Reject:

- obvious horn/siren;
- one-shot acceleration pass-by;
- gear-change transient;
- strongly rhythmic piston pulse that becomes machine-gun-like at 2.12x;
- speech/music;
- engine clip with a baked acceleration/deceleration envelope;
- candidate that loses all low-mid identity when pitched above ~1.6x;
- candidate that becomes sub-bass mud below native pitch.

### Engine pitch/load audition

For every serious finalist, loop for at least 30 seconds and audition these representative pitch scales:

- `0.72x` — extreme low boundary;
- `0.90x` — low-speed / low-load region;
- `1.00x` — native;
- `1.30x` — moderate acceleration;
- `1.60x` — fast/high load;
- `2.12x` — runtime maximum.

Also test fast sweeps between those values rather than only static points.

Judge:

- seamless loop at every pitch;
- no periodic knocking/warble revealed by pitch change;
- no chipmunk/comical identity at 2.12x;
- no muddy drone at 0.72x;
- acceleration reads naturally when pitch rises;
- coast/low-load state remains distinguishable from high load;
- repeated 60-second driving fatigue;
- compatibility under Wind and Yardline radio;
- compatibility with production Brake Screech and collision cues.

## Target B — `pursuit.siren_alarm`

Desired identity:

- threatening autonomous pursuer alarm / electronic emergency siren;
- strongly readable at distance in 3D;
- recognizable as sustained threat rather than a one-shot alert;
- distinct from the production Disturbance Alert chirp;
- distinct from Intercept chassis impact;
- not so literal/iconic that it overwhelms the game's reclaimed near-future identity;
- should become more urgent as runtime pitch rises to 1.45x without becoming painfully shrill.

Preferred natural source length:

`0.8–2.5 s`

Reject:

- short beeps that produce obvious repetition;
- spoken police/radio material;
- horn blasts;
- alarm with an uneditable one-shot intro/outro that clicks each cycle;
- extremely bright tone that becomes fatiguing at 1.45x;
- loop whose pitch modulation changes perceived identity into a comedy/car alarm.

### Siren chase audition

For every serious finalist:

1. loop for at least 45 seconds;
2. test native pitch `1.0x`;
3. test intermediate `1.20x`;
4. test maximum `1.45x`;
5. sweep repeatedly between 1.0 and 1.45 to mimic closing/opening distance;
6. audition at low and high playback levels to approximate far/near 3D attenuation;
7. layer with representative Wind, engine, tension drone if practical, and production Disturbance Alert / Intercept.

Judge:

- loop seam;
- long-chase fatigue;
- urgency scaling;
- small-speaker readability;
- harshness at maximum pitch;
- distinction from Disturbance Alert;
- distinction from Evasion Release;
- distinction from Signal Lock;
- whether it leaves room for Intercept impact.

## Target C — `echo.radio_interference`

Desired identity:

- reclaimed-radio carrier contamination;
- fractured analog/digital telemetry residue;
- unstable RF flutter, carrier beating, narrow-band noise, or corrupted electrical texture;
- hybrid: clearly sourced from a world position while also contaminating the vehicle radio experience;
- eerie precursor identity, but not the full 01J Memory Echo apparition;
- subtle enough for proximity exploration and repeated passes;
- no intelligible speech required or desired.

Preferred natural source length:

`0.8–2.5 s`

Reject:

- conventional radio station/music;
- intelligible GTA dialogue;
- police dispatch phrases;
- pure unshaped white noise;
- alarm/siren;
- Signal Lock-like confirmation ping;
- obvious 01J Echo Onset/Peak/Tail clone;
- loop with a strong transient landmark every cycle.

### Interference proximity audition

For every serious finalist, loop for at least 45 seconds and audition at approximate relative levels representing:

- outer range / barely present: around `-30 dB`;
- mid proximity: around `-21 dB`;
- inner range / close: around `-12 dB`.

Also audition beneath representative Yardline radio playback.

Judge:

- whether the texture remains perceptible but non-distracting at low level;
- whether close-range identity is compelling without becoming a full alarm;
- loop seam and repeated landmark fatigue;
- compatibility with up to ~`-4 dB` radio contamination;
- 3D/small-speaker readability;
- distinction from 01J Echo Onset/Peak/Tail;
- distinction from Signal Lock;
- distinction from Disturbance Alert;
- whether sudden suppression to silence during MEMORY_ECHO / critical threat feels clean rather than exposing a bad loop edge.

## Loop treatment policy

Do not apply one-shot boundary tapers to continuous loops.

For each finalist report the raw seam behavior first.

Preferred treatment order:

1. use the raw loop unchanged if genuinely seamless;
2. otherwise use the smallest practical equal-power circular seam blend;
3. preserve original sample rate and total duration when possible;
4. do not time-stretch solely to match stale registry loop windows.

No gain normalization, EQ, compression, reverb, resampling, or time stretching is authorized during candidate selection unless a candidate is explicitly rejected for requiring it.

## Search scope

Start with:

- `GENRL`;
- `SCRIPT`.

Also deliberately inspect library families likely to contain:

- vehicle/engine loops;
- industrial machinery hums;
- sirens/alarms;
- radio/static/interference;
- electronics/communication carriers.

Do not constrain search to previously used GENRL 138/143 banks.

For engine candidates, prioritize naturally steady sources over one-shot vehicle maneuvers.
For siren candidates, prioritize steady threat loops over recognizable speech/police dispatch.
For interference candidates, prioritize generic carrier/noise textures over authored dialogue.

Aim for:

- 4–6 credible Engine candidates;
- 4–6 credible Siren candidates;
- 4–6 credible Interference candidates.

Approximately 12–18 serious candidates total is sufficient. Do not bulk-extract hundreds of sounds.

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
- loop seam quality;
- proposed seam treatment;
- pitch-range behavior where applicable;
- small-speaker readability;
- long-loop fatigue;
- neighboring-production distinction;
- gain change needed;
- resampling needed;
- EQ/compression/reverb/time-stretch needed.

## Final selection report

### Engine Rev — Selected

Return:

- exact source metadata;
- natural duration/rate;
- raw SHA-256;
- 30–60 second loop result;
- behavior at 0.72 / 0.90 / 1.0 / 1.30 / 1.60 / 2.12 pitch scales;
- rapid pitch-sweep result;
- low-pitch mud result;
- high-pitch harsh/comedy result;
- Wind/Yardline compatibility;
- Brake/Collision distinction;
- exact proposed loop treatment.

Runner-up:

- source;
- reason not selected.

### Pursuit Siren — Selected

Return:

- exact source metadata;
- natural duration/rate;
- raw SHA-256;
- 45-second loop result;
- 1.0 / 1.20 / 1.45 pitch results;
- repeated pressure-sweep result;
- far/near readability;
- maximum-pitch harshness;
- distinction from Disturbance Alert;
- distinction from Evasion Release / Signal Lock;
- Intercept headroom;
- exact proposed loop treatment.

Runner-up:

- source;
- reason not selected.

### Echo Radio Interference — Selected

Return:

- exact source metadata;
- natural duration/rate;
- raw SHA-256;
- 45-second loop result;
- low/mid/high proximity-level result (`-30 / -21 / -12 dB` approximations);
- Yardline-underlay result;
- low-level perceptibility;
- close-range identity;
- 01J Echo distinction;
- Signal Lock / Disturbance distinction;
- sudden-suppression behavior;
- exact proposed loop treatment.

Runner-up:

- source;
- reason not selected.

## Pack-level discrimination

Audition the three winners together in representative gameplay-like combinations:

- Engine + Wind + Yardline;
- Engine + Siren + Wind during pursuit;
- Engine + Interference + Yardline near the precursor source;
- Siren + Disturbance Alert transition;
- Interference suppression into Memory Echo if practical.

Report:

- Engine vs Siren: PASS / FAIL;
- Engine vs Interference: PASS / FAIL;
- Siren vs Interference: PASS / FAIL;
- all-three spectral separation: PASS / FAIL;
- overall loop-fatigue result: PASS / FAIL;
- overall extraction integrity: PASS / FAIL.

## Candidate-search boundary

During candidate search do not:

- add production WAVs/imports;
- promote registry slots;
- modify AudioManager or VehicleFeedbackLayer;
- change pitch/gain formulas;
- change unit sizes/max distances;
- alter pursuit distance thresholds;
- alter radio contamination rules;
- add vehicle-specific engine slots;
- add loop players;
- change reset behavior.

## Planned production paths after source lock

If winners pass:

- `vehicle.engine_rev` -> `res://audio/vehicle/loop_vehicle_engine_rev.wav`;
- `pursuit.siren_alarm` -> `res://audio/pursuit/loop_pursuit_siren_alarm.wav`;
- `echo.radio_interference` -> `res://audio/echo/loop_echo_radio_interference.wav`.

These paths are planned only. Candidate search must not create them.

## Completion

The 01L candidate-search checkpoint is complete when one human-auditioned winner and runner-up exist for each target, all three winners pass their required long-loop/pitch/proximity fatigue tests, the pack remains spectrally distinct in representative combinations, and no production/runtime mutation has occurred during search.