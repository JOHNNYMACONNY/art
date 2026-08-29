# Audio Production 01M — Yardline Station Identity & Sweeper Pack

**State:** CANDIDATE_SELECTION_REQUIRED  
**Baseline:** `main@860073387f87c696f3dc8ff2f063dc0105f88982`

## Objective

Replace three live Yardline 88.3 procedural interstitial identities with production media while preserving the existing radio program, playback owner, lifecycle, and mix behavior:

1. `radio.yardline.dj_sweeper` — short station-flow sweeper used by the DJ_LINK category;
2. `radio.yardline.station_id_01` — primary Yardline signature jingle / station ID;
3. `radio.yardline.station_id_02` — compact Yardline sting / alternate station ID.

01M is a **candidate-selection workstream first**. During search and audition, no production radio asset, registry promotion, runtime stream-resolution change, director weight change, scheduler change, new player, new station, or gameplay behavior is authorized.

## Current runtime authority on baseline main

All three targets already exist in `AudioRegistry` and `RadioStationCatalog` and are reachable through the current Yardline program.

Shared registry authority for all three:

- domain: `RADIO`;
- diegesis: `DIEGETIC`;
- spatial type: `NON_DIEGETIC_2D`;
- mix group: `RADIO_MUSIC`;
- playback type: `TRANSIENT`;
- `is_looping = false`;
- max concurrency: `1`;
- asset status: `PROCEDURAL_FALLBACK`;
- `replacement_required = true`;
- no production asset path;
- no production source provenance.

### `radio.yardline.dj_sweeper`

Catalog authority:

- item id: `dj_03_sweeper`;
- category: `DJ_LINK`;
- context: `SWEEPER`;
- title: `DJ Sweeper - Yardline Flow`;
- one BODY segment;
- semantic slot: `radio.yardline.dj_sweeper`;
- authored fallback duration: `0.8 s`;
- authored fallback base frequency: `520 Hz`.

### `radio.yardline.station_id_01`

Catalog authority:

- item id: `id_01_yardline_jingle`;
- category: `STATION_ID`;
- title: `Yardline 88.3 Signature Jingle`;
- one BODY segment;
- semantic slot: `radio.yardline.station_id_01`;
- authored fallback duration: `1.5 s`;
- authored fallback base frequency: `660 Hz`.

### `radio.yardline.station_id_02`

Catalog authority:

- item id: `id_02_yardline_sting`;
- category: `STATION_ID`;
- title: `Yardline Stinger`;
- one BODY segment;
- semantic slot: `radio.yardline.station_id_02`;
- authored fallback duration: `0.8 s`;
- authored fallback base frequency: `880 Hz`.

## Existing playback architecture to preserve

`RadioProgramPlayer` owns one `AudioStreamPlayer` named `RadioAudioStreamPlayer` on the Master bus. It advances catalog segments, preserves pause/resume cursor state, and composes three independent gain layers:

- lifecycle fade;
- pursuit/critical ducking;
- Echo radio-contamination ducking.

The current candidate-stage resolution path is:

1. optional developer-local `AudioReferenceResolver` stream for the current semantic slot when reference mode is permitted and enabled;
2. otherwise `_synthesize_segment_audio()` procedural fallback.

The production integration after source lock may add one narrow registry-production resolution step for the three selected slots, but must preserve the same player and all current program/lifecycle/mix ownership.

`RadioProgramDirector` authority is out of scope and must remain unchanged, including:

- SONG weight `60`;
- DJ_LINK weight `15`;
- STATION_ID weight `10`;
- ADVERT weight `10`;
- max non-song gap `2`;
- song/interstitial anti-repeat history behavior;
- event-driven WORLD_REACTION priority and deferral behavior;
- deterministic seeded selection/state serialization.

## Identity direction

Yardline 88.3 is an experimental pirate/scrap relay. These three clips should establish a coherent broadcast signature without sounding like generic menu UI, police dispatch, a conventional commercial FM package, or a copied GTA station identity.

Shared desired character:

- reclaimed transmitter / pirate relay;
- compact analog-electrical or industrial broadcast texture;
- memorable in the `300 Hz–4 kHz` small-speaker band;
- clear enough under vehicle engine and scrapyard Wind;
- leaves room for program music, DJ links, pursuit alerts, and Memory Echo contamination;
- no intelligible GTA station names, characters, slogans, dialogue, or recognizable musical branding;
- no source that reads as a gameplay warning, Signal Lock confirmation, Disturbance Alert, Evasion Release, or Memory Echo signature.

## Target A — `radio.yardline.dj_sweeper`

Desired identity:

- fastest and lightest of the three;
- reads as a transition/sweep rather than a full station ID;
- useful between program elements without demanding attention;
- short rising/falling RF motion, relay chirp, tape/electrical sweep, or compact broadcast transition texture;
- should tolerate frequent recurrence without fatigue.

Preferred natural source length:

`0.25–1.2 s`

Reject:

- spoken dialogue;
- recognizable radio station branding;
- alarm/siren identity;
- long reverb tail that masks following content;
- hard impact that reads as collision/gameplay feedback;
- tonal confirmation ping too close to Signal Lock;
- clip that becomes irritating when heard repeatedly in a 10-minute radio session.

Audition:

- repeat 20 times with 1–4 second gaps;
- place immediately before and after representative Yardline song fallback material;
- audition under engine + Wind at moderate driving level;
- audition with approximately `-7 dB` and `-13 dB` pursuit duck;
- audition with up to `-4 dB` Echo contamination;
- verify clean start/end with no click and no tail collision into the next segment.

## Target B — `radio.yardline.station_id_01`

Desired identity:

- primary station signature;
- strongest and most memorable of the pack;
- a complete micro-jingle or transmitter ident, not merely a UI chime;
- recognizably related to the sweeper and alternate ID while still distinct;
- confident but not louder/more urgent than critical gameplay cues.

Preferred natural source length:

`0.7–2.5 s`

Reject:

- copyrighted song hook or recognizable musical phrase;
- spoken GTA station name/dialogue;
- siren/security warning;
- comedy/cartoon sting;
- oversized cinematic impact;
- long low-frequency tail that muddies engine/Wind;
- close match to production Disturbance Alert, Evasion Release, Signal Lock, Gate Slam, or Memory Echo onset/tail.

Audition:

- repeat at least 15 times across a 10-minute simulated radio session;
- compare directly against ID 02 and the sweeper;
- audition before and after songs/DJ links;
- audition under engine + Wind;
- audition during radio duck recovery after pursuit;
- verify small-speaker readability and non-fatiguing high-frequency content.

## Target C — `radio.yardline.station_id_02`

Desired identity:

- compact alternate Yardline sting;
- same family as ID 01 but shorter, sharper, and clearly non-identical;
- useful as a secondary identifier without sounding like a gameplay success/failure cue;
- may share texture/spectral language with ID 01, but not the same envelope or melodic contour.

Preferred natural source length:

`0.35–1.4 s`

Reject:

- near-duplicate of ID 01;
- generic UI confirm/back sound;
- alarm/siren;
- recognizable GTA branding/dialogue/music;
- bright single ping too close to Signal Lock;
- descending cue too close to Evasion Release;
- Echo-like electrical rupture/dissolve.

Audition:

- alternate ID 01 / ID 02 for at least 20 total repetitions;
- verify listener can distinguish them immediately without either sounding unrelated to Yardline;
- audition between representative songs and DJ links;
- audition under engine + Wind and during pursuit duck;
- verify short tail and clean handoff into the following segment.

## Owner-authorized candidate source boundary

Use only the owner-authorized local GTA San Andreas audio library already accepted for production-audio work.

For every serious candidate record exact provenance:

`GTA_SA:<PAK>:BANK_<bank_id>:SOUND_<sound_index>`

Start with `GENRL` and `SCRIPT`, then inspect other local banks that contain radio stingers, broadcast transitions, electronics, relay/RF sweeps, compact musical-neutral identifiers, and industrial/electrical textures.

Candidate staging remains local/gitignored. Do not commit extracted candidate WAVs, source archives, machine-specific paths, or bulk library material.

Aim for:

- 4–6 credible Sweeper candidates;
- 4–6 credible Station ID 01 candidates;
- 4–6 credible Station ID 02 candidates.

Approximately 12–18 serious candidates total is enough. Do not bulk-extract hundreds of sounds.

## Candidate treatment policy

During selection:

- preserve the raw source sample rate, channels, bit depth, and duration;
- do not normalize, EQ, compress, add reverb, resample, time-stretch, pitch-shift, or layer multiple GTA sources;
- report boundary quality first;
- for a selected short transient, only minimal edge cleanup/fades may be proposed after source lock if required to remove a click;
- do not fabricate station voiceover or spoken branding from GTA dialogue.

The winning identity should come from source selection, not heavy repair.

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
- start/end cleanliness;
- small-speaker readability;
- repetition fatigue;
- engine/Wind compatibility;
- pursuit-duck compatibility;
- Echo-contamination compatibility;
- distinction from the other two 01M targets;
- distinction from Signal Lock / Disturbance / Evasion / Memory Echo;
- gain change needed;
- resampling needed;
- EQ/compression/reverb/time-stretch needed.

## Final selection report

For each target, return one human-auditioned winner and one runner-up.

Winner report must include:

- exact GTA source provenance;
- natural duration/rate/channels/bit depth;
- raw SHA-256;
- repeated-session fatigue result;
- small-speaker result;
- engine + Wind result;
- pursuit-duck result;
- Echo-contamination result;
- neighboring-production distinction result;
- exact proposed edge treatment, if any.

Pack-level discrimination must report:

- Sweeper vs Station ID 01: PASS / FAIL;
- Sweeper vs Station ID 02: PASS / FAIL;
- Station ID 01 vs Station ID 02: PASS / FAIL;
- all-three family coherence: PASS / FAIL;
- all-three semantic distinction: PASS / FAIL;
- 10-minute repetition fatigue: PASS / FAIL;
- extraction/staging integrity: PASS / FAIL.

## Candidate-search boundary

During candidate search do not:

- add production radio WAV/OGG files or import sidecars;
- promote any registry slot;
- add production path/provenance metadata;
- modify `RadioProgramPlayer`, `RadioProgramDirector`, or `RadioStationCatalog` behavior;
- change category weights, anti-repeat logic, max-gap rules, event queues, pause/resume, fades, or radio gain composition;
- add a radio player, timer, scheduler, station, song, advert, DJ link, or world reaction;
- change gameplay, vehicle radio lifecycle, pursuit, Echo contamination, or reset behavior.

The executable 01M candidate-selection contract must stay green throughout search and must prove this boundary from repository/runtime metadata.

## Planned production integration after source lock

Only after all three human-selected winners are accepted may implementation:

1. add final curated short-form production media under `res://audio/radio/`;
2. promote only the three target registry slots to project-internal `LICENSED_FINAL` and clear `replacement_required`;
3. record exact production path and GTA source provenance;
4. add a narrow `RadioProgramPlayer` registry-production resolution step between permitted local-reference resolution and procedural synthesis;
5. preserve independent procedural fallback when an expected production stream is absent;
6. preserve the existing single `RadioAudioStreamPlayer` and all director/lifecycle/mix ownership.

Planned filenames, subject to the selected source format and final accepted treatment:

- `radio.yardline.dj_sweeper` -> `res://audio/radio/rad_yardline_dj_sweeper.wav`;
- `radio.yardline.station_id_01` -> `res://audio/radio/rad_yardline_station_id_01.wav`;
- `radio.yardline.station_id_02` -> `res://audio/radio/rad_yardline_station_id_02.wav`.

No production media is authorized by this candidate-search checkpoint itself.

## Future production verification after source lock

The later 01M production contract must prove at minimum:

- exact registry status/path/provenance for the three winners;
- selected media exists and loads in Godot with expected technical metadata;
- all three exact catalog segments resolve through the existing `RadioAudioStreamPlayer`;
- local-reference policy still fails closed for final slots;
- each target retains an independently reachable procedural fallback if its production stream is unavailable;
- one missing production target does not disable the other two;
- director weights, anti-repeat/max-gap/event behavior remain unchanged;
- pause/resume cursor state remains intact;
- lifecycle fade, pursuit duck, and Echo contamination still compose correctly;
- reset stops/clears the radio without leaking a voice;
- Audio Runtime and canonical Web compatibility remain green on the exact production head.

Exact-head native listening after integration must cover a representative Yardline session, engine + Wind underlay, pursuit duck/recovery, Echo contamination/suppression transitions, and repeated station-ID/sweeper fatigue.

## Completion

The **01M candidate-selection checkpoint** is complete when one human-auditioned winner and runner-up exist for each of the three target slots, the three winners pass pack-level coherence/distinction/fatigue checks, exact source metadata and treatment decisions are recorded, and the candidate-selection contract remains green with no production/runtime mutation.

01M production PASS is a later checkpoint requiring selected media integration, exact-head automated and native listening verification, fresh Standards/Spec review, merge, and exact-main evidence.