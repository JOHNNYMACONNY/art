# Wayfinder Map: Chinatown-Wars-Feel Golden Slice v0

## Destination
A playable, mobile-first WebGL (Three.js) vertical slice of ECHOES IN THE SCRAPHEAP with a 3/4 low-FOV perspective camera, floating left-thumb joystick, right-thumb contextual interaction magnetism, audio feedback, and a 1–2s tactile "Corroded Panel Extraction" interaction.

## Notes
- **Engine**: Three.js/WebGL embedded in `code/`
- **Audio**: Web Audio API (`audio-engine.js`)
- **Target**: 60 FPS on mobile Safari/Chrome
- **Scope**: 1 scrap-yard test block, 1 runner placeholder, 1 interactable corroded panel, 0 combat/vehicles/missions

## Decisions so far
- [1. Renderer — Three.js WebGL](#decision-1) — Embedded in `code/` for zero-install mobile browser testing.
- [2. Camera Projection — Low-FOV Perspective](#decision-2) — 32° FOV, 58° downward pitch, 45° fixed yaw, 12% max velocity look-ahead.
- [3. Locomotion — Floating Left Joystick](#decision-3) — Screen-relative analog vector with 8-way visual mesh facing.
- [4. Interaction — Magnetism & Corroded Panel Extraction](#decision-4) — Right-thumb contextual action -> 1–2s tactile peel/pull core gesture.
- [5. Audio Bed — Web Audio Integration](#decision-5) — Ambience, footsteps, hum, panel peel, core pull, electrical sparks.
- [6. Environment — 1 Scrap-Yard Test Block](#decision-6) — Scrap geometry, lighting, particle FX, no missions/enemies.

---

### Decision 1: Renderer — Three.js WebGL
- **Choice**: Three.js WebGL canvas inside `code/`.
- **Rationale**: Existing 2D canvas (`renderer.js`) lacks 3/4 depth/parallax. Godot stubs stay for desktop/Steam exploration; WebGL allows instant URL testing on mobile touch devices.

### Decision 2: Camera Projection — Low-FOV Perspective
- **Choice**: `PerspectiveCamera` with low FOV (~32°), downward pitch ~58°, fixed yaw ~45°, camera look-ahead capped at 12% viewport displacement.
- **Rationale**: Delivers Chinatown Wars 3/4 depth without wide-angle third-person distortion.

### Decision 3: Locomotion — Floating Left Joystick
- **Choice**: Touch down on left half of screen sets origin; vector drag drives analog movement. Direction is screen-relative. Avatar faces 8 headings.
- **Rationale**: Fixed virtual joysticks fail on touchscreens; floating origin prevents missed inputs.

### Decision 4: Interaction — Magnetism & Corroded Panel Extraction
- **Choice**: Single right-thumb contextual action button with highlight magnetism. "Corroded Panel Extraction" sequence: Approach -> Highlight -> Action -> Peel Cover -> Pull Core (~1-2s).
- **Rationale**: Proves signature touch interactions over generic button presses.

### Decision 5: Audio Bed — Web Audio Integration
- **Choice**: Connect Web Audio engine (`audio-engine.js`) to prototype events (ambient bed, footsteps, proximity hum, metal peel, core pull, sparks).
- **Rationale**: Audio provides essential tactile feedback on touchscreen devices.

### Decision 6: Environment — 1 Scrap-Yard Test Block
- **Choice**: Single room with industrial floor, scrap silhouettes, lighting, particles, 1 interactable panel terminal.
- **Rationale**: Micro-scope keeps test focused purely on touch feel and camera readability.

## Not yet specified
- Vehicle camera transition and driving controls (deferred post-v0 slice).
- Weapon targeting and combat mechanics (deferred).

## Out of scope
- Engine migration to Godot 4 for v0 prototype.
- Missions, inventory, progression, AI agents, networking, save file migration.
