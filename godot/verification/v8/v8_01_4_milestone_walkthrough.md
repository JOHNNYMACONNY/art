# Milestone V8 M01 Walkthrough & Verification Summary
**Title**: Echoes in the Scrapheap — Scrapheap World Identity & Visual Readability

## 1. Executive Summary
Milestone V8 M01 establishes the complete visual identity, modular dressing kit, functional hero landmarks, lighting rig, atmosphere, and dynamic route readability for the scrap yard while strictly preserving gameplay collision, mechanics, and 60 FPS performance.

---

## 2. Completed Ticket Specifications

### Ticket V8 01.1 & 01.1B: Modular Scrap Dressing Kit & Geometry Hardening
- **Modular Prop Kit** (`godot/scenes/props/`):
  - `scrap_pile_a.tscn`: Crushed chassis core, angled bent plate, low-poly torus wheel rim (`rings=16, segs=10`), rusted axle cylinder (`radial=8`).
  - `scrap_pile_b.tscn`: Heavy engine block, low-poly drum barrel (`radial=10`), angled steel I-beam.
  - `salvage_container.tscn`: Shipping container with directional corrugated metal ribs, framing beams, and roof rails.
  - `pipe_rack_modular.tscn`: Dual vertical stanchions, crossbar, and dual horizontal industrial pipes (`radial=8`).
  - `corrugated_fence.tscn`: Rusted steel posts, corrugated sheet panel, and top angle cap.
  - `ground_debris_flat.tscn`: 7-sided organic heptagon oil stain decal (`cast_shadow=0`, flat plane) with scattered metal flakes.
- **Procedural Shaders & Materials** (`godot/materials/`):
  - `mat_corrugated_metal.tres`: Procedural directional normal gradient for crisp vertical ribs without external textures.
  - `mat_oil_stain.tres`: Embedded procedural noise for irregular dark surface grime.

### Ticket V8 01.2 & 01.2A: Landmark Population & Hero Landmark Silhouettes
- **6 Hero Functional Landmarks** (`godot/scenes/world/scrap_yard_dressing.tscn`):
  1. **Cold Start Shelter**: Low-profile lean-to corrugated roof overhang on dual steel posts (`landmark_cold_start_shelter.tscn`).
  2. **Tuner Outpost**: Vertical radio spire mast (`radial=8`) with dual insulator toruses (`landmark_tuner_mast.tscn`).
  3. **Extraction Bay**: Heavy machinery housing arch header and structural side stanchions enclosing the Corroded Panel (`landmark_extraction_housing.tscn`).
  4. **Bike Staging Pad**: Flat concrete slab pad with rusted hazard border (`landmark_bike_pad.tscn`).
  5. **Gate Barrier Assembly**: Overhead warning gantry beam and warning banner plate framing the swinging gate arm (`landmark_gate_arch.tscn`).
  6. **Shortcut Ramp Guide**: Sloped side guide trusses visually framing the elevated ramp jump (`landmark_ramp_truss.tscn`).
- **Dynamic Readability Route Matrix** (`--run-v8-readability`):
  - 8 distinct traversal routes validated under full player/bike speed and active pursuer chases with zero camera occlusion, zero false collision, and 100% entity visibility.

### Ticket V8 01.3: Lighting, Atmosphere & Post-Processing
- **Directional Light Rig**: Key sun at `Color(1.0, 0.90, 0.78, 1)`, energy `1.4`, casting defined shadows with tuned bias (`shadow_bias = 0.04`).
- **World Environment**: Cool slate ambient fill (`Color(0.22, 0.26, 0.32, 1)`, energy `1.1`), ACES tonemapper (`exposure = 1.05`, `white = 1.1`), and subtle bloom (`intensity = 0.5`, `bloom = 0.12`).
- **Atmospheric Particles**: Low-overhead GPU particle emitter (`dust_drift_particles.tscn`, 48 unshadowed motes).

### Ticket V8 01.4: Technical Regression & Falsification
- **15-Suite Regression Suite**: 100% GREEN (15/15 test suites passed).
- **8-View Canonical Visual Benchmark Suite**: Exported to `godot/verification/v8/v8_dressed_01_cold_start.png` through `08_quiet_aftermath.png`.

---

## 3. Rendering Telemetry & Performance Progression

| Metric | V7 Baseline (Greybox) | V8 01.1B Hardened | V8 01.2 Dressed | V8 01.3 Lit + Landmarks | Total Delta vs Baseline |
|---|---|---|---|---|---|
| **Draw Calls (Frame)** | 68 | 120 | 191 | **216** | +148 |
| **Primitives / Triangles** | 59,410 | 61,690 | 68,186 | **68,726** | **+9,316** (+15.6% tris) |
| **Total Objects in Frame** | 75 | 144 | 344 | **343** | +268 |
| **Average Frame Time** | 16.46 ms (60.8 FPS) | 16.39 ms (61.0 FPS) | 16.44 ms (60.8 FPS) | **16.44 ms (60.8 FPS)** | 0.0 ms |
| **P95 Frame Time** | 17.20 ms | 17.23 ms | 17.32 ms | **17.46 ms** | +0.26 ms |

**Status**: `DEV CADENCE: STABLE | DRAW SCALING: MEASURED | REAL MOBILE: UNKNOWN`

---

## 4. Benchmark Views
1. `godot/verification/v8/v8_dressed_01_cold_start.png`
2. `godot/verification/v8/v8_dressed_02_tuner_approach.png`
3. `godot/verification/v8/v8_dressed_03_panel_extraction.png`
4. `godot/verification/v8/v8_dressed_04_bike_staging.png`
5. `godot/verification/v8/v8_dressed_05_gate_approach.png`
6. `godot/verification/v8/v8_dressed_06_shortcut_ramp.png`
7. `godot/verification/v8/v8_dressed_07_active_chase.png`
8. `godot/verification/v8/v8_dressed_08_quiet_aftermath.png`
