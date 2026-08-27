# Sound Library Intake & Production Audio Contract (Audio Intake 01A)

**Status:** ACTIVE / BASELINE CONTRACT  
**Target Engine:** Godot 4.7.1 Stable  
**Scope:** Sound Library Intake, Metadata Schema, Inventory Tooling, Repository Boundary & Incremental Replacement Protocol  

---

## 1. Architectural Principles & Non-Negotiables

1. **Zero Binary Bloat in Git History**: Raw external sound libraries, multi-gigabyte sample packs, unvetted takes, and staging directories MUST NEVER be committed to Git. Only finalized, trimmed, peak-normalized, and slot-mapped production audio files enter the repository under strict size budgets.
2. **Offline & Non-Mutating Intake**: Library inventory and indexing tools are completely read-only and offline. They never modify source sound libraries or write machine-specific absolute paths into versioned files.
3. **Preserve Current Audio Architecture**: Intake contracts build directly on existing `AudioRegistry`, `AudioReferenceResolver`, `UIAudioSemanticRegistry`, and `AudioManager` subsystems. No speculative replacement audio frameworks are permitted.
4. **Fail-Closed Fallback Security**: All game semantic audio slots start with verified procedural or synthesised audio fallbacks. Production assets replace procedural streams incrementally without changing game state or runtime contracts.
5. **Human Listening Verification**: Audio assets must pass explicit perceptual, mix, and mobile-hardware criteria before transitioning to final production status.

---

## 2. Local Library Inventory & Indexing Protocol

The local sound library is inventoried using a standalone offline tool (`code/audio_intake/sound_library_indexer.py`).

### Captured File Metadata:
* `relative_path`: Path from the library root using POSIX forward slashes (guaranteed never to include absolute system paths like `/Users/...` or `C:\...`).
* `filename`: Base name of the file including extension.
* `extension`: Lowercase file extension (e.g., `wav`, `ogg`, `mp3`, `flac`).
* `file_size_bytes`: Integer byte count.
* `sha256`: Hexadecimal SHA-256 hash of the file contents for deduplication, provenance tracking, and content validation.
* `format`: Audio container / codec type (`WAV_PCM`, `WAV_FLOAT`, `OGG_VORBIS`, `MP3`, `FLAC`, `UNKNOWN`).

### Format-Specific Metadata:
* **WAV files**: Extracted natively via RIFF/WAVE header parsing without external dependencies:
  * `sample_rate`: Sample rate in Hz (e.g., 44100, 48000).
  * `channels`: Number of audio channels (1 = mono, 2 = stereo).
  * `bit_depth`: Bits per sample (e.g., 16, 24, 32).
  * `duration_sec`: Duration in seconds computed from sample rate and data frame count.
* **Compressed formats (OGG, MP3, FLAC)**: Unless an optional external probe (e.g., `ffprobe`) is available in the local environment, sample rate, bit depth, channels, and duration MUST remain `null`/unknown. The tool must never fail or crash on non-WAV formats.

---

## 3. Game Audio Categories & Semantic Domains

The inventory tool and shortlist manifests categorize candidate sounds into the established canonical domains of *Echos in the Scrap*:

| Domain | Description | Mix Group | Spatial Default | Format Default |
|---|---|---|---|---|
| `PLAYER` | Courier locomotion, boots on scrap/dirt, mounting/dismounting clicks, breath | `INCIDENTAL_UI` | `DIEGETIC_3D` | 16-bit WAV Mono |
| `VEHICLE` | Courier Bike electric motor coil whine, hauler diesel rumble, brake screech, tire slip, chassis rattle, glance/head-on crunch | `VEHICLE_FEEDBACK` | `DIEGETIC_3D` | 16-bit WAV Mono |
| `INTERACTION` | Corroded panel pry stress, sheet metal groan/peel, wire clip snap, spark crackle, battery insert latch, memory core pneumatic release | `INCIDENTAL_UI` / `SIGNATURE_ECHO` | `DIEGETIC_3D` | 16-bit WAV Mono |
| `PURSUIT` | Security drone siren oscillation, distance tension drone, radar sweep ping, intercept impact / EMP pulse, signal gate barrier slam | `CRITICAL_THREAT` | `DIEGETIC_3D` / `NON_DIEGETIC_2D` | 16-bit WAV Mono / Stereo |
| `ECHO` | Precursor memory echo onset, crystalline shimmer bed, heterodyne radio interference, memory completion stinger | `SIGNATURE_ECHO` | `NON_DIEGETIC_2D` / `HYBRID` | 16-bit WAV / Ogg Stereo |
| `WORLD` | Scrap valley dry wind, distant mechanical stamp presses, scrap settling clinks, industrial servo hums | `AMBIENT_TEXTURE` | `DIEGETIC_3D` / `NON_DIEGETIC_2D` | 16-bit WAV Mono / Ogg Stereo |
| `UI` | Analog cassette clicks, tactile relay confirm, descending back tick, mode switch latch, dry reject double-pulse | `INCIDENTAL_UI` | `NON_DIEGETIC_2D` | 16-bit WAV Stereo |
| `RADIO` | Yardline 88.3 station sweeps, DJ intro/outro links, satirical adverts, commercial music tracks | `RADIO_MUSIC` | `NON_DIEGETIC_2D` / `DIEGETIC_3D` | Ogg Vorbis Stereo |

---

## 4. Candidate Shortlist & Curation Criteria

Candidate sounds selected from the inventory must satisfy the following technical and aesthetic gates before entering the repository:

1. **Transient Punch & Attack Intelligibility**: Critical interaction and collision transients must reach peak energy within the first **20–50 ms** to ensure zero perceived input lag.
2. **Monophonic Spatial Purity**: All in-world 3D sounds (`DIEGETIC_3D`) MUST be strictly single-channel (mono). Stereo in-world files cause incorrect Godot 3D panning and phase cancellation.
3. **Headroom & Dynamic Range**:
   * Short SFX / Transients: Peak normalized between **-6.0 dBFS** and **-3.0 dBFS** with zero clipping and zero DC offset.
   * Ambient Loops & Radio Music: Integrated loudness normalized to **-14.0 LUFS** (±1.0 LUFS) with true peak < **-1.0 dBFS**.
4. **Seamless Loop Boundaries**: Continuous sounds (`vehicle.engine_rev`, `pursuit.siren_alarm`, `echo.bed_loop`, `world.ambient_wind`) must have exact zero-crossing loop start and end points with zero boundary clicks or phase discontinuities.
5. **Frequency Clarity on Mobile Hardware**: Essential semantic cues must have significant harmonic energy in the **300 Hz – 4,000 Hz** band so they remain legible on small mobile phone speakers without requiring sub-bass reproduction.

---

## 5. Licensing, Attribution & Provenance Ledger

Every imported sound asset must include explicit provenance tracking:
* `provenance`: Origin sound pack, library collection, or bespoke recording date.
* `license_type`: Standard identifier (e.g., `CC0_1_0`, `CC_BY_4_0`, `COMMERCIAL_ROYALTY_FREE`, `INTERNAL_BESPOKE`).
* `author`: Original creator / sound designer name or organization.
* `source_ref`: URL, order receipt ID, or recording session ID.
* `commercial_use_allowed`: Boolean (MUST be `true` for production release).
* `attribution_required`: Boolean.
* `attribution_text`: Exact text to be included in game credits if attribution is required.

---

## 6. Godot 4.7 Audio Format & Import Settings

* **Short SFX & Transients (< 5.0 seconds)**:
  * File format: `.wav` (Uncompressed 16-bit PCM, 44.1 kHz or 48.0 kHz).
  * Godot resource: `AudioStreamWAV`.
  * Import settings: `compress/mode = 0` (Disabled / 16-bit PCM for zero-latency instant playback).
* **Music, Radio Broadcasts & Long Ambiences (> 5.0 seconds)**:
  * File format: `.ogg` (Ogg Vorbis, Quality 6 / ~160 kbps, 44.1 kHz or 48.0 kHz).
  * Godot resource: `AudioStreamOggVorbis`.
  * Import settings: Streaming enabled for minimal RAM footprint.

---

## 7. Repository Storage Conventions & Size Budgets

### Canonical Path Structure:
```
godot/
  audio/
    player/
      sfx_player_footstep_01.wav
      sfx_player_bike_mount.wav
      sfx_player_bike_dismount.wav
    vehicles/
      sfx_vehicle_engine_rev_loop.wav
      sfx_vehicle_brake_screech.wav
      sfx_vehicle_collision_glance.wav
      sfx_vehicle_collision_head_on.wav
    interactions/
      sfx_interaction_panel_pry.wav
      sfx_interaction_panel_peel.wav
      sfx_interaction_wire_clip.wav
      sfx_interaction_wire_spark.wav
      sfx_interaction_battery_insert.wav
      sfx_interaction_core_extracted.wav
    pursuit/
      sfx_pursuit_disturbance_alert.wav
      sfx_pursuit_siren_loop.wav
      sfx_pursuit_intercept_impact.wav
    echo/
      sfx_echo_onset.wav
      mus_echo_bed_loop.ogg
      sfx_echo_completion.wav
    ui/
      sfx_ui_nav_move.wav
      sfx_ui_nav_confirm.wav
      sfx_ui_nav_back.wav
      sfx_ui_reject.wav
    radio/
      rad_yardline_station_id_01.ogg
      mus_yardline_track_01.ogg
```

### Strict Size Budgets:
* Single transient WAV: <= 150 KB.
* Single ambient/music Ogg: <= 1.5 MB.
* Total production audio footprint for vertical slice: <= 15.0 MB.

---

## 8. Incremental Replacement Lifecycle

Each semantic slot in `AudioRegistry` tracks its asset replacement state:

`PROCEDURAL_FALLBACK -> ORIGINAL_WIP / REFERENCE_ONLY -> ORIGINAL_FINAL / LICENSED_FINAL`

1. **Step 1 (Fallback)**: System defaults to procedural synthesis (`_create_tone_wav`, `_create_sweep_wav`).
2. **Step 2 (Local Reference Testing)**: Sound designer tests external candidate via `AudioReferenceResolver` using `--allow-local-reference-audio` and local manifest.
3. **Step 3 (Curated Import)**: Selected asset is trimmed, normalized, verified, and placed into `godot/audio/...`.
4. **Step 4 (Registry Promotion)**: Slot's `asset_status` in `AudioRegistry` is promoted to `ORIGINAL_FINAL` or `LICENSED_FINAL`, and `replacement_required` is set to `false`.

---

## 9. Human Listening Verification Checklist

Before any production sound is approved into `ORIGINAL_FINAL` / `LICENSED_FINAL`, the sound designer must verify:

- [ ] **Tier Separation**: In a high-speed chase with active siren, the critical signal lock / gate slam / dismount reject transient is clearly audible without ducking distortion.
- [ ] **Mobile Speaker Clarity**: Sound audited on physical phone speaker or band-pass filter (300Hz-4kHz); no key transient disappears.
- [ ] **Headroom & Summing**: No digital clipping or inter-sample peaks when 4 simultaneous SFX trigger simultaneously during max engine rev.
- [ ] **Loop Consistency**: 60 seconds continuous playback of loop streams without audible phase clicks, pops, or tonal fatigue.
- [ ] **UI Rapid-Fire Fatigue**: UI confirm/back sounds played 30 times in 5 seconds do not produce harsh buildup or user fatigue.
