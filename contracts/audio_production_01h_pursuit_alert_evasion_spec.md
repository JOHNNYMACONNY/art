# Audio Production 01H — Pursuit Alert & Evasion Pack

**State:** CANDIDATE_SELECTION_REQUIRED  
**Baseline:** `main@306352950bb92047ba8cb2869e5312f750b92aec`

## Objective

Batch the next pursuit-audio identity work into one production slice:

1. `pursuit.disturbance_alert` — detection / security escalation cue;
2. `pursuit.evaded_stinger` — safe evasion / tension-release cue;
3. `pursuit.pursuer_sweep` — pursuer-local scanner/search identity.

Use the proven batched workflow: one GTA candidate search/audition pass, one source-lock phase, one repo-side implementation pass, one asset-ingestion pass, one exact-head verification/review cycle, and one PR/merge.

Do not change pursuit steering, chase thresholds, gate behavior, interception behavior, vehicle physics, or unrelated audio slots.

## Runtime authority findings on baseline main

### 1. Disturbance alert — live

`AudioManager.SoundEvent.DISTURBANCE_ALERT` is live.

Current path:

- `set_mix_state(MixState.DISTURBANCE)` calls `play_event(DISTURBANCE_ALERT, Vector3.ZERO)`;
- procedural cue: `350 Hz -> 700 Hz` sweep, `0.4 s`, volume `0.6`;
- generic synth helper creates an `AudioStreamPlayer3D` with `unit_size = 10.0`;
- the same event branch also calls `set_siren_audio(true, pos)`.

Registry metadata:

- domain: PURSUIT;
- diegesis: NON_DIEGETIC;
- spatial type: NON_DIEGETIC_2D;
- mix group: CRITICAL_THREAT;
- playback type: TRANSIENT;
- max concurrency: 1.

**Critical integration invariant:** a production-media early return must not bypass `set_siren_audio(true, pos)`. The siren activation side effect must execute exactly once for both production and fallback playback.

The current registry/runtime spatial mismatch is pre-existing. Candidate audition does not resolve it. Integration must treat shipping behavior and semantic/reference metadata separately and must not make an unreviewed spatial-authority rewrite.

### 2. Evaded stinger — live

`AudioManager.SoundEvent.EVASION_RELEASE` is live.

Current path:

- `set_mix_state(MixState.EVASION_RELEASE)` calls `play_event(EVASION_RELEASE, Vector3.ZERO)`;
- procedural cue: `500 Hz -> 1000 Hz` sweep, `0.5 s`, volume `0.5`;
- generic synth helper creates an `AudioStreamPlayer3D` with `unit_size = 10.0`.

Registry semantic slot:

- `pursuit.evaded_stinger`;
- domain: PURSUIT;
- diegesis: NON_DIEGETIC;
- spatial type: NON_DIEGETIC_2D;
- mix group: SIGNATURE_ECHO;
- playback type: TRANSIENT;
- max concurrency: 1.

Radio recovery remains owned by the existing pursuit-release decay envelope. 01H must not introduce a second radio-recovery owner or short-circuit the existing de-escalation flow.

The current registry/runtime spatial mismatch is pre-existing and must be handled deliberately during integration rather than silently rewritten during candidate selection.

### 3. Pursuer sweep — reserved semantic authority, not currently live

`pursuit.pursuer_sweep` exists in `AudioRegistry`, but baseline main has:

- no `AudioManager.SoundEvent.PURSUER_SWEEP`;
- no production/procedural event mapping for this slot;
- no dedicated scanner player in `AudioManager`;
- no scanner emission hook in `PursuerPrototype`.

Current registry metadata:

- domain: PURSUIT;
- diegesis: DIEGETIC;
- spatial type: DIEGETIC_3D;
- mix group: CRITICAL_THREAT;
- playback type: CONTINUOUS_LOOP;
- `is_looping = true`;
- nominal loop window `0.0–0.8 s`;
- max concurrency: 2.

Therefore this target is **not a production replacement yet**. It is an authority-backed reserved slot that 01H may activate as one narrowly bounded feature after source selection.

If the selected source is suitable, the default 01H implementation direction is:

- preserve the slot as a DIEGETIC_3D continuous loop;
- add one bounded pursuer-local scanner voice owned by `AudioManager`;
- update its world position from the already-authoritative pursuer position supplied to `set_pursuit_pressure(distance, pursuer_pos)`;
- play only during active pursuit pressure;
- stop during pursuit clear, de-escalation/quiet aftermath, interception reset, and authoritative audio reset;
- do not alter pursuer steering/state thresholds;
- retain a procedural scanner fallback if production media is absent.

This bounded activation must be test-first and will require fresh native gameplay verification because it adds an audible runtime behavior rather than merely replacing media.

If human audition cannot find a clean loop-compatible source, 01H must retain the scanner candidate as non-promoted evidence rather than force a poor loop or convert the semantic slot to a transient without a separate authority decision.

## Candidate source restriction

Use only the local owner-authorized GTA San Andreas audio library already used for prior production slices.

For each winner, record exact provenance as:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Rejected candidates and archive containers remain local/ignored.

## Audition target A — disturbance alert

Desired identity:

- immediate security/detection escalation;
- electronic or mechanical scan-alert pulse rather than generic menu beep;
- strong enough to mark transition into disturbance without competing with the siren that follows;
- crisp on laptop/phone speakers;
- distinct from Signal Lock, Wire Spark, Pursuer Intercept, and Gate Slam;
- not a firearm, explosion, musical victory/failure sting, or long alarm loop;
- low fatigue across retries.

Preferred natural duration: approximately `0.20–0.65 s`.

## Audition target B — evaded stinger

Desired identity:

- unmistakable release of pressure / successful contact break;
- restrained, physical/electronic confirmation rather than triumphant music;
- lighter and calmer than disturbance/interception cues;
- compatible with siren/tension decay rather than masking it;
- distinct from Signal Lock and Core Extracted completion;
- readable on small speakers at moderate volume;
- low fatigue across repeated evasion loops.

Preferred natural duration: approximately `0.25–0.80 s`.

## Audition target C — pursuer sweep loop

Search for a short loop-compatible scanner/search cycle, not merely the loudest ping.

Desired identity:

- diegetic pursuer scanner/radar/search mechanism;
- directional 3D identity that can live on the pursuer body;
- controlled pulse/sweep cadence that can repeat during chase;
- audible beneath siren/tension without becoming another siren;
- clearly different from Signal Lock and disturbance alert;
- not musical, not a weapon charge, not a continuous harsh alarm;
- low fatigue over at least 10–15 seconds of repetition.

Preferred source/cycle length: approximately `0.40–1.20 s`.

For scanner candidates, audition actual repeated looping. Report:

- loop-seam click/pop;
- cadence fatigue;
- whether natural start/end support a seamless or near-seamless loop;
- whether minimal crossfade/boundary treatment would be required;
- whether the source instead behaves like a one-shot and should be rejected for this slot.

Do **not** apply the standard one-shot boundary taper blindly to a loop candidate; loop treatment must be chosen from actual seam behavior.

## Production destinations after source lock

Planned canonical destinations:

- disturbance alert → `res://audio/pursuit/sfx_pursuit_disturbance_alert.wav`;
- evaded stinger → `res://audio/pursuit/sfx_pursuit_evaded_stinger.wav`;
- pursuer sweep → `res://audio/pursuit/sfx_pursuit_scanner_sweep.wav`.

`AudioRegistry` remains canonical path/provenance authority.

## Candidate-selection gate

For each target return 4–6 credible candidates, with a winner and runner-up.

For every winner report:

- pak / bank / sound index;
- native rate, channels, bit depth;
- frame count / duration / bytes;
- raw SHA-256;
- listening identity;
- small-speaker readability;
- masking against siren/tension/engine where relevant;
- fatigue result;
- extraction integrity;
- gain change needed;
- resampling needed;
- boundary treatment needed;
- other processing needed.

For scanner-sweep winner additionally report:

- 10–15 second repeated-loop audition result;
- seam quality;
- loop cadence;
- exact proposed loop treatment;
- whether it remains suitable as `CONTINUOUS_LOOP`.

## Expected integration behavior after source selection

### Disturbance alert

- production media resolves through registry;
- existing siren activation executes for both production and fallback paths;
- no duplicate siren trigger;
- old 350→700 Hz procedural sweep remains independently reachable.

### Evaded stinger

- production media resolves through registry;
- existing evasion/de-escalation and radio recovery ownership remains unchanged;
- old 500→1000 Hz procedural sweep remains independently reachable.

### Pursuer sweep

If candidate passes the loop gate:

- add one bounded `AudioStreamPlayer3D` scanner voice owned by `AudioManager`;
- source position tracks supplied `pursuer_pos` during active pursuit pressure;
- one concurrent scanner loop only;
- production stream resolves through registry;
- procedural loop fallback remains available;
- no new pursuit-state authority is created;
- voice stops on `clear_pursuit_pressure()` and `reset_audio_instant()`;
- scanner never survives into quiet aftermath;
- scanner does not replace or suppress siren/tension ownership.

If candidate fails loop suitability, do not promote this slot in 01H.

## Verification requirements after integration

Exact-head automated verification must cover:

- exact event/slot mapping for the two live transient targets;
- exact paths/provenance/native media characteristics;
- production vs fallback reachability;
- disturbance siren side effect preserved under production path;
- evasion release does not take ownership of radio recovery;
- scanner activation only if loop candidate passed;
- scanner follows pursuer position and is bounded to one voice;
- scanner stops on clear/reset/aftermath;
- existing interception, collision, gate, signal-lock, 01D, 01C, 01B, semantic-manifest, Audio Runtime, pursuit, and canonical Web regressions remain green.

## Human native verification after integration

One exact-head pursuit session should cover:

- disturbance onset into siren activation;
- active chase with scanner loop if promoted;
- representative pursuit/collision overlap;
- clean contact break and evasion release;
- scanner/siren/tension fade or stop behavior through de-escalation;
- quiet aftermath with no leaked scanner voice;
- repeated retry/fatigue pass.

## Completion

01H reaches PASS only when every promoted target has exact-head automated proof, exact-head native listening, fresh Standards/Spec review, merged PR, exact-main CI, and current playtest provenance. A scanner candidate that is auditioned but not runtime-promoted is not counted as production-final.
