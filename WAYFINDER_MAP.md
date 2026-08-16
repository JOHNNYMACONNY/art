# Wayfinder Map: Echos in the Scrapheap — Godot 4 Golden Slice

## 1. Project Overview & Destination
A playable, mobile-first Godot 4 3D vertical slice of **ECHOES IN THE SCRAPHEAP** featuring:
- Chinatown Wars-style fixed 3/4 top-down perspective camera (`Camera3D` with smoothed single-layer tracking, dual-rate look-ahead, speed-breathing FOV, and decoupled yaw).
- Floating left-thumb touch joystick locomotion with responsive screen-relative movement.
- Right-thumb contextual touch interactions (Signal Tuner frequency matching, Corroded Panel peeling & core extraction).
- Arcade Courier Bike with speed-sensitive steering, 2-stage gear acceleration, powerslide drift slip, handbrake, and glancing collision response.
- Dynamic pursuer interception, environmental Signal Gate barrier routing, and multi-tier procedural audio atmosphere.

---

## 2. Architecture & Tech Stack
- **Engine**: Godot 4.7.1 Stable Official (3D Forward+ / Mobile / Headless execution)
- **Primary Codebase**: `godot/scripts/`
  - `player/`: `player_character.gd`, `camera_3d.gd`
  - `vehicles/`: `courier_bike.gd`
  - `enemies/`: `pursuer_prototype.gd`
  - `interactables/`: `signal_tuner.gd`, `corroded_panel.gd`, `signal_gate_interactable.gd`
  - `audio/`: `audio_manager.gd`
  - `ui/`: `touch_controls.gd`
  - `prototype/`: `scrap_test_block.gd`
- **Audio Architecture**: Procedural analytical synthesis (frequency chirps, harmonic drone, square beep denial, filtered noise) managed through a centralized 3-tier perceptual hierarchy and bounded transient registry.

---

## 3. Milestones & Historical Record

### V1–V6: Core Prototype Evolution
- **V1**: Locomotion, floating joystick, reaction loop.
- **V2**: Micro-play loop (Signal Tuner & Corroded Panel).
- **V3**: Courier Bike mechanics, mount/dismount flow.
- **V4**: Pursuer AI, pressure pacing, proximity alarm.
- **V5**: Environmental evasion (Signal Gate slam, pursuer detour).
- **V6**: Full Golden Slice integration & screenshot export pipeline.

### V7: Golden Slice Hardening & Subsystem Polish (COMPLETE / VERIFIED)
- **Ticket 01**: Gate solid collision & peel touch-release cancellation.
- **Ticket 02 / 02.1**: Multi-touch isolation, dismount speed denial, chase detour balance.
- **Ticket 03**: Saturating `tanh` tuner accumulator, near-lock enter/exit lifecycle.
- **Ticket 04 (04.1, 04.2, 04.3)**: GTA 2-stage transmission, powerslide drift dynamics, glance collision slide retention.
- **Ticket 05**: Chinatown Wars camera feel, single-layer smoothed focus, dual-rate look-ahead, speed FOV breathing.
- **Ticket 06 (06.1–06.4)**: 3-tier audio hierarchy, pursuit pressure with hysteresis, true procedural sweeps, clean replay resets.

### V8: Scrapheap World Identity & Visual Readability (ACTIVE)
- **V8 M01**: Scrapheap World Identity, Dressing & Atmosphere.
  - `01.1`: Visual Language & Modular Scrap Kit.
  - `01.2`: World Dressing & Landmark Pass.
  - `01.3`: Lighting, Atmosphere & Silhouette Depth.
  - `01.4`: Readability & Mobile Performance Baseline.

---

## 4. Historical Context (Superseded)
> [!NOTE]
> Early exploratory v0 drafts originally investigated Three.js / WebGL in `code/` for quick browser previews. All production development is fully unified in Godot 4 under `godot/`.
