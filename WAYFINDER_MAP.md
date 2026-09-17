# Wayfinder Map: Echos in the Scrapheap — Historical Architecture Map

> **Status note (2026-08-30):** This file is retained for architecture/history and is **not the current Wayfinder or milestone/status tracker**. The canonical **Burnside Open World Design** Wayfinder map lives in GitHub Issue #101 (`Burnside Open World Design — Wayfinder Map`); do not expand this file into a competing tracker. Current implementation truth lives in `HANDOFF.md`, current GitHub PR/issue state, and machine-readable verification records such as `godot/verification/feel/wave1_retention_summary.json`. Labels such as `ACTIVE` below describe the historical snapshot in which this map was written and must not be used to infer present completion state.

## 1. Project Overview & Destination
A playable, mobile-first Godot 4 3D vertical slice of **ECHOES IN THE SCRAPHEAP** featuring:
- Chinatown Wars-style fixed 3/4 top-down perspective camera (`Camera3D` with smoothed single-layer tracking, dual-rate look-ahead, speed-breathing FOV, and decoupled yaw).
- Floating left-thumb touch joystick locomotion with responsive screen-relative movement and safe-area boundary enforcement.
- Right-thumb compact 2-column touch controls (Signal Tuner frequency matching, Corroded Panel peeling & core extraction, discrete Action/Gas parity, Handbrake, and contextual Route Switch).
- Arcade Courier Bike with speed-sensitive steering, single-speed responsive throttle curve, powerslide drift slip, handbrake, and glancing collision response.
- Dynamic pursuer interception, environmental Signal Gate barrier routing, de-escalating threat aftermath, and multi-tier procedural audio atmosphere.

---

## 2. Architecture & Tech Stack
- **Engine**: Godot 4.7.1 Stable Official (3D Forward+ / Mobile / Headless execution)
- **Primary Codebase**: `godot/scripts/`
  - `player/`: player and runner behavior
  - `camera/`: retained dynamic 3/4 camera behavior
  - `vehicles/`: Courier Bike and Scrap Hauler
  - `entities/`: pursuer and ambient actors
  - `interactions/`: tuner, panel, Signal Gate and shared interactions
  - `audio/`: centralized AudioManager, radio and vehicle-feedback layers
  - `input/`: touch/desktop input normalization
  - `prototype/`: golden-slice orchestration
  - `verification/`: deterministic CTW feel harnesses
- **Audio Architecture**: centralized semantic/runtime audio with procedural fallbacks, reactive radio, bounded transient ownership and authoritative reset.

---

## 3. Milestones & Historical Record

### V1–V6: Core Prototype Evolution
- **V1**: Locomotion, floating joystick, reaction loop.
- **V2**: Micro-play loop (Signal Tuner & Corroded Panel).
- **V3**: Courier Bike mechanics, mount/dismount flow.
- **V4**: Pursuer AI, pressure pacing, proximity alarm.
- **V5**: Environmental evasion (Signal Gate slam, pursuer detour).
- **V6**: Full Golden Slice integration & screenshot export pipeline.

### V7: Golden Slice Hardening & Subsystem Polish (HISTORICALLY COMPLETE / VERIFIED)
- **Ticket 01**: Gate solid collision & peel touch-release cancellation.
- **Ticket 02 / 02.1**: Multi-touch isolation, dismount speed denial, chase detour balance.
- **Ticket 03**: Saturating `tanh` tuner accumulator, near-lock enter/exit lifecycle.
- **Ticket 04 (04.1, 04.2, 04.3)**: Courier bike transmission curve, powerslide drift dynamics, glance collision slide retention.
- **Ticket 05**: Chinatown Wars camera feel, single-layer smoothed focus, dual-rate look-ahead, speed FOV breathing.
- **Ticket 06 (06.1–06.4)**: 3-tier audio hierarchy, pursuit pressure with hysteresis, true procedural sweeps, clean replay resets.

### V8: Scrapheap World Identity, Mobile Touch UX & Threat Aftermath — Historical Snapshot
- **V8 M01**: Scrapheap World Identity, Dressing & Atmosphere (historically complete / verified).
  - `01.1`: Visual Language & Modular Scrap Kit.
  - `01.2`: World Dressing & Landmark Pass.
  - `01.3`: Lighting, Atmosphere & Silhouette Depth.
  - `01.4`: Readability & Mobile Performance Baseline.
- **V8 M02**: Mobile Safe-Area, Touch Ergonomics, Global Pointer Ownership & Multi-Touch (historically complete / verified).
  - `02.1A`: Safe-Area Viewport Scale & Offset Mapper.
  - `02.2A`: Compact 2-Column Right-Thumb Hierarchy, 16px Grid & Cutout Touch Rejection.
  - `02.3 & 02.3B`: Global Pointer Registry (`is_pointer_index_claimed`), Mouse Sentinel (-999), 18-Test Adversarial Matrix (A-R).
  - `02.4`: Multi-Viewport Telemetry, 8-Gameplay-State Capture Matrix & Scorecard.
- **V8 M03**: Threat Aftermath & World Continuity (**historical `ACTIVE` label; current status superseded by `HANDOFF.md`**).
  - `03.1`: Pursuer De-escalation & Retreat/Search Behavior.
  - `03.2`: Aftermath Pressure Decay & Audio Fade.
  - `03.3`: Deterministic Reset & Retrigger Lifecycle.
  - `03.4`: Automated Falsification & Visual Transition Proof.

---

## 4. Current Continuity Pointer

For the current retained gameplay configuration and next-state rules, use:

1. `HANDOFF.md`
2. `godot/verification/feel/wave1_retention_summary.json`
3. current GitHub issue / PR / workflow state

The CTW Feel Wave 1 functional retention record explicitly distinguishes retained, reverted and pending experiments. In particular, the current camera follow is retained while the separate occlusion experiment is non-retained; experimental touch steering conditioning remains disabled pending device qualification.

---

## 5. Historical Context (Superseded)
> [!NOTE]
> Early exploratory v0 drafts originally investigated Three.js / WebGL in `code/` for quick browser previews. All production development is fully unified in Godot 4 under `godot/`.
