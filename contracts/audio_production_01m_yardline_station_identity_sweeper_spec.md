# Audio Production 01M — Yardline Station Identity & Sweeper Pack

**State:** SOURCES_SELECTED__PRODUCTION_INGESTION_AUTHORIZED  
**Baseline:** `main@860073387f87c696f3dc8ff2f063dc0105f88982`

## Objective

Replace three live Yardline 88.3 procedural interstitial identities with production media while preserving the existing radio program, playback owner, lifecycle, and mix behavior:

1. `radio.yardline.dj_sweeper` — short station-flow sweeper used by the DJ_LINK category;
2. `radio.yardline.station_id_01` — primary Yardline signature jingle / station ID;
3. `radio.yardline.station_id_02` — compact Yardline sting / alternate station ID.

Human candidate audition is complete. The three winners below are now locked and production ingestion of exactly those winners is authorized. No substitute source, runner-up promotion, layering, resampling, pitch-shifting, normalization, EQ, compression, reverb, time-stretching, or other identity-changing treatment is authorized without a new accepted selection decision.

## Locked production selections

### Target A — `radio.yardline.dj_sweeper`

**Selected source:** `GTA_SA:GENRL:BANK_44:SOUND_2`

- format: mono PCM16;
- native sample rate: `18,000 Hz`;
- frame count: `8,016`;
- natural duration: `0.4453 s`;
- raw bytes: `16,032`;
- peak: `-2.00 dB`;
- RMS: `-15.57 dB`;
- approximate dominant frequency: `1,265 Hz`;
- raw SHA-256: `188837f05074b791060d41d5265851be7ef84b443c54b4f42d8fd40f941022b3`;
- listening identity: crisp rising radio blip / broadcast sweep, fast and lightweight between track segments;
- start/end: clean natural transient/decay with zero boundary click;
- small-speaker readability: PASS, dominant ~1.2 kHz presence;
- repeated-session fatigue: PASS, 20 repetitions in simulated radio flow;
- engine + Wind compatibility: PASS;
- pursuit-duck / Echo-contamination compatibility: PASS;
- semantic distinction from both station IDs and gameplay cues: PASS;
- authorized edge treatment: **none**; preserve natural source boundary exactly.

**Runner-up:** `GTA_SA:SCRIPT:BANK_356:SOUND_16`

- mono PCM16;
- `15,000 Hz`;
- `9,909` frames;
- `0.6606 s`;
- `19,818` bytes;
- peak `-2.00 dB`;
- RMS `-14.36 dB`;
- raw SHA-256: `621aa1348b7d2e9bcdf40d10658e97b456ef594c925e983102a83342e5cc3c0b`.

Runner-up remains audition evidence only and is not authorized for production ingestion while the selected source remains available and valid.

Canonical production path:

`res://audio/radio/rad_yardline_dj_sweeper.wav`

### Target B — `radio.yardline.station_id_01`

**Selected source:** `GTA_SA:GENRL:BANK_44:SOUND_3`

- format: mono PCM16;
- native sample rate: `18,000 Hz`;
- frame count: `18,176`;
- natural duration: `1.0098 s`;
- raw bytes: `36,352`;
- peak: `-2.00 dB`;
- RMS: `-16.30 dB`;
- approximate dominant frequency: `995 Hz`;
- raw SHA-256: `a742e3d686fcfa91f8b643e0a820580a78dcd40db34f4c73ce517c894340c842`;
- listening identity: complete micro-jingle / resonant transmitter signature ident with warm analog broadcast character;
- start/end: smooth onset and natural decay with zero click;
- small-speaker readability: PASS, rich ~900 Hz–2.5 kHz harmonics;
- repeated-session fatigue: PASS, 15 iterations across a 10-minute simulated session;
- engine + Wind compatibility: PASS;
- pursuit-duck / Echo-contamination compatibility: PASS;
- semantic distinction from Sweeper, ID 02, and gameplay cues: PASS;
- authorized edge treatment: **none**; preserve natural source boundary exactly.

**Runner-up:** `GTA_SA:SCRIPT:BANK_356:SOUND_2`

- mono PCM16;
- `15,000 Hz`;
- `28,244` frames;
- `1.8829 s`;
- `56,488` bytes;
- peak `-2.00 dB`;
- RMS `-14.81 dB`;
- raw SHA-256: `96677f627d502e1650f48841b00ab828f1117ddef117c36b00093f8fb85854a1`.

Runner-up remains audition evidence only and is not authorized for production ingestion while the selected source remains available and valid.

Canonical production path:

`res://audio/radio/rad_yardline_station_id_01.wav`

### Target C — `radio.yardline.station_id_02`

**Selected source:** `GTA_SA:GENRL:BANK_44:SOUND_4`

- format: mono PCM16;
- native sample rate: `18,000 Hz`;
- frame count: `11,872`;
- natural duration: `0.6596 s`;
- raw bytes: `23,744`;
- peak: `-2.00 dB`;
- RMS: `-16.35 dB`;
- approximate dominant frequency: `943 Hz`;
- raw SHA-256: `7550cdb3f12086f78bea71b752b0edbd5e1f46b1e83136c459de5cc978d99051`;
- listening identity: compact punchy secondary station sting with the same broadcast acoustic family as ID 01 and a shorter sharper envelope;
- start/end: clean transient and rapid natural decay with zero edge noise;
- small-speaker readability: PASS, articulate ~900 Hz–3 kHz band;
- repeated-session fatigue: PASS, alternated 20 times against ID 01 and Sweeper;
- engine + Wind compatibility: PASS;
- pursuit-duck / Echo-contamination compatibility: PASS;
- semantic distinction from Sweeper, ID 01, and gameplay/UI cues: PASS;
- authorized edge treatment: **none**; preserve natural source boundary exactly.

**Runner-up:** `GTA_SA:SCRIPT:BANK_356:SOUND_13`

- mono PCM16;
- `12,000 Hz`;
- `8,534` frames;
- `0.7112 s`;
- `17,068` bytes;
- peak `-2.00 dB`;
- RMS `-18.42 dB`;
- raw SHA-256: `a3c7719ce246781d50c261898890aced94d0fb632064cc1e51b01846b536b4f5`.

Runner-up remains audition evidence only and is not authorized for production ingestion while the selected source remains available and valid.

Canonical production path:

`res://audio/radio/rad_yardline_station_id_02.wav`

## Pack-level audition result

Human source audition and discrimination result:

- Sweeper vs Station ID 01: PASS;
- Sweeper vs Station ID 02: PASS;
- Station ID 01 vs Station ID 02: PASS;
- all-three family coherence: PASS — cohesive `18 kHz` broadcast package from `GENRL:BANK_44`;
- all-three semantic distinction: PASS;
- 10-minute repetition fatigue: PASS;
- extraction / staging integrity: PASS.

The source-selection checkpoint therefore passes. These results authorize production ingestion of the three exact `GENRL:BANK_44` winners above, while final production acceptance still requires repository ingestion, exact-head automated verification, and exact-head native gameplay listening.

## Current runtime authority on baseline main

All three targets already exist in `AudioRegistry` and `RadioStationCatalog` and are reachable through the current Yardline program.

Shared registry authority before production integration:

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

The pre-production resolution path is:

1. optional developer-local `AudioReferenceResolver` stream for the current semantic slot when reference mode is permitted and enabled;
2. otherwise `_synthesize_segment_audio()` procedural fallback.

The authorized production integration may add one narrow registry-production resolution step for the three selected slots, but must preserve the same player and all current program/lifecycle/mix ownership.

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

Yardline 88.3 is an experimental pirate/scrap relay. These three locked clips establish a coherent broadcast signature without sounding like generic menu UI, police dispatch, a conventional commercial FM package, or copied spoken GTA station identity.

Shared accepted character:

- reclaimed transmitter / pirate relay;
- compact analog-electrical or industrial broadcast texture;
- memorable in the `300 Hz–4 kHz` small-speaker band;
- clear under vehicle engine and scrapyard Wind;
- leaves room for program music, DJ links, pursuit alerts, and Memory Echo contamination;
- no intelligible GTA station names, characters, slogans, or dialogue;
- no source reads as Signal Lock confirmation, Disturbance Alert, Evasion Release, Gate Slam, or Memory Echo signature.

## Owner-authorized source boundary

The owner-authorized GTA San Andreas production-audio exception applies to exactly the three locked winners above.

Exact provenance must be recorded in `AudioRegistry` at ingestion:

- Sweeper: `GTA_SA:GENRL:BANK_44:SOUND_2`;
- Station ID 01: `GTA_SA:GENRL:BANK_44:SOUND_3`;
- Station ID 02: `GTA_SA:GENRL:BANK_44:SOUND_4`.

Candidate staging, runner-ups, source archives, machine-specific paths, and bulk library material remain local/gitignored and must not enter Git.

Project-internal `LICENSED_FINAL` records the accepted project production lifecycle state and exact provenance; it is not an independent legal/license-clearance claim.

## Production treatment lock

All three winners passed clean-boundary audition without repair. Production ingestion must therefore preserve the selected source bytes and technical identity except for container/header changes that are unavoidable to place the same PCM payload in the canonical repository file.

Required:

- mono PCM16;
- native `18,000 Hz` sample rate;
- exact natural frame count and duration for each source;
- non-looping playback;
- no fade-in/fade-out added;
- no normalization or gain bake;
- no EQ;
- no compression/limiting;
- no reverb/delay;
- no resampling;
- no time stretching;
- no pitch shifting;
- no source layering.

Final repository WAV SHA-256 may differ from the audition raw SHA only if the extraction tooling produces a different but PCM-equivalent WAV header/container. The production contract must validate the exact PCM technical metadata and record the final repository-file SHA separately. If the extracted canonical file is byte-identical to the audition WAV, the raw SHA should match exactly.

## Authorized production ingestion and integration

Production ingestion of the three locked winners is now authorized.

Implementation may:

1. add only these three finalized files under `res://audio/radio/`:
   - `radio.yardline.dj_sweeper` -> `res://audio/radio/rad_yardline_dj_sweeper.wav`;
   - `radio.yardline.station_id_01` -> `res://audio/radio/rad_yardline_station_id_01.wav`;
   - `radio.yardline.station_id_02` -> `res://audio/radio/rad_yardline_station_id_02.wav`;
2. add only their non-destructive Godot `.import` sidecars as required;
3. promote only those three registry slots to project-internal `LICENSED_FINAL`;
4. set `replacement_required = false` only for those three slots;
5. record the exact canonical production path and locked GTA source provenance;
6. add one narrow `RadioProgramPlayer` production-stream resolution step;
7. preserve each exact existing procedural fallback as independently reachable if its production stream is unavailable;
8. preserve the existing single `RadioAudioStreamPlayer` and all director/lifecycle/mix ownership.

The authorized playback resolution order for these final slots is:

1. registry production stream when the final path exists and loads successfully;
2. otherwise the exact current procedural fallback.

Because final slots fail closed for local reference override under the existing registry policy, production integration must not make developer-local reference audio override a `LICENSED_FINAL` stream.

## Explicitly out of scope

Production ingestion must not:

- ingest either runner-up;
- add any other radio WAV/OGG file;
- promote any other radio slot;
- change `RadioProgramDirector` category weights or seeded selection;
- change anti-repeat logic, max-gap logic, event queues, or WORLD_REACTION rules;
- modify `RadioStationCatalog` item/category/context identity for the three targets;
- add a player, timer, scheduler, station, song, advert, DJ link, or world reaction;
- change pause/resume semantics;
- change lifecycle fade, pursuit duck, or Echo-contamination gain composition;
- change vehicle-radio mount/dismount behavior;
- change pursuit, Memory Echo, reset, or gameplay behavior.

## Candidate-selection guard during ingestion

The existing executable candidate-selection contract remains authoritative **until the first production-ingestion commit** and must stay green while no production files are present.

Once the three production assets and registry promotions are introduced, replace or evolve that guard into the 01M production contract in the same implementation change. Do not simply delete the protection. The production contract must prove the locked sources, exact technical metadata, runtime routing, preserved fallbacks, and unchanged radio architecture.

## Production automated verification

The 01M production contract must prove at minimum:

- exact registry `LICENSED_FINAL` status, `replacement_required=false`, production path, and source provenance for all three locked winners;
- production media exists and loads in Godot;
- Sweeper is mono PCM16, `18,000 Hz`, `8,016` frames, approximately `0.4453 s`;
- Station ID 01 is mono PCM16, `18,000 Hz`, `18,176` frames, approximately `1.0098 s`;
- Station ID 02 is mono PCM16, `18,000 Hz`, `11,872` frames, approximately `0.6596 s`;
- all three streams are non-looping;
- all three exact catalog segments resolve through the existing `RadioAudioStreamPlayer`;
- local-reference policy remains fail-closed for final slots;
- each target retains an independently reachable procedural fallback if its production stream is unavailable;
- one missing production target does not disable or alter either other production target;
- `RadioProgramDirector` weights, anti-repeat, max-gap, event priority/deferral, and seeded behavior remain unchanged;
- catalog item/category/context/semantic-slot mapping remains unchanged;
- pause/resume cursor state remains intact;
- lifecycle fade, pursuit duck, and Echo contamination still compose correctly;
- reset stops/clears radio with no leaked or doubled voice;
- Audio Runtime and canonical Web compatibility remain green on the exact production head.

Regression verification must include M22 radio program assertions, M23 vehicle radio, M24 radio mix, M25 Echo radio interference, Audio Runtime, 01L, 01K, 01J, 01H, and canonical Web compatibility.

## Exact-head native listening after ingestion

Production acceptance requires native listening on the exact production head covering:

- representative 10-minute Yardline session with all three selected identities recurring naturally;
- Sweeper at least 20 times with varied 1–4 second spacing and adjacent program material;
- ID 01 at least 15 times across representative songs/DJ links;
- ID 01 / ID 02 alternation at least 20 total repetitions;
- engine + Wind underlay at moderate/high vehicle movement;
- pursuit duck around approximately `-7 dB` and `-13 dB` plus recovery;
- Echo contamination up to approximately `-4 dB` and critical suppression transitions;
- direct comparison against Signal Lock, Disturbance Alert, Evasion Release, Gate Slam, and Memory Echo signatures;
- small-speaker/headphone clarity;
- start/end cleanliness and no segment-tail collision;
- reset/replay with no stale or doubled radio voice.

## Completion

The **01M source-selection checkpoint is PASS**: one human-auditioned winner and runner-up are locked for each target, all three winners passed family coherence, semantic distinction, fatigue, mix-context, and extraction/staging checks, and the candidate-selection contract remained green with no production/runtime mutation.

The next valid state is production ingestion of the three locked winners. 01M production PASS requires exact media integration, exact-head automated verification, exact-head native listening, fresh Standards/Spec review, PR merge, and exact-main evidence.