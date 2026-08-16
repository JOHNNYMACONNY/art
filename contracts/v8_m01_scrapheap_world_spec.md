# V8 M01 SPECIFICATION: SCRAPHEAP WORLD IDENTITY, DRESSING & ATMOSPHERE

**Status**: SPEC-PROPOSED / REVIEW-PENDING  
**Target Subsystems**:
- `godot/scenes/world/scrap_test_block.tscn` (Environment, lighting, mesh instances, dressing nodes)
- `godot/scripts/prototype/scrap_test_block.gd` (A/B benchmark capture harness, visual regression assertions)
- `godot/materials/` (Scrap metal, rust, asphalt/dirt terrain, emissive trims)
- `godot/scenes/props/` (Modular scrap piles, industrial containers, fencing, salvage landmarks)
**Target Baseline**: `main@a546189` (V7 Verified Golden Slice)  

---

## 1. GOAL & CONTEXT

Transform the existing Golden Slice greybox (40×40 BoxMesh floor, primitive blocks, flat untextured materials) into a distinctive, original, readable scrap-industrial salvage yard environment ("Echoes in the Scrapheap") without damaging any verified V7 gameplay geometry, driving handling, camera tracking, audio clarity, or mobile 60 FPS performance.

---

## 2. PLAYER CONTRACT & NON-NEGOTIABLES

1. **Immediate Scrap Identity**: At a single glance, the world reads as a gritty, industrial salvage yard with history and texture, not a developer testbed.
2. **Navigation Legibility**: Primary transit routes, bike driving lanes, and the shortcut ramp remain immediately readable from the fixed 3/4 top-down camera (`Camera3D`).
3. **Strict Visual Hierarchy**:
   - **Tier A (Gameplay Critical)**: Player avatar, Courier Bike, Pursuer, Signal Tuner, Corroded Panel, Signal Gate barrier arm, active pursuit path.
   - **Tier B (Navigation & Structure)**: Perimeter walls, road surface textures, ground curbs, shortcut ramp silhouette.
   - **Tier C (World Identity & Dressing)**: Modular scrap heaps, salvage bins, rusted pipe runs, corrugated sheet fencing, machinery silhouettes, localized ground debris.
   - **Tier D (Atmosphere & Lighting)**: High-contrast directional sunlight, rusted ambient fill, soft dust/ember particulates, subtle emissive beacons.
4. **Interactable Prominence**: Interactables (Signal Tuner, Corroded Panel, Bike socket) retain higher luminance, crisp silhouette framing, and distinctive accent colors over background clutter.
5. **High-Speed Driving Cleanliness**: Main driving lanes maintain clear tarmac/dirt textures with zero distracting floor micro-clutter that could be mistaken for solid collision.
6. **Collision Truthfulness**: Decorative dressing props placed near travel lanes either sit fully outside collision boundaries or have accurate, non-snagging collision shapes. Visuals must never create false collision expectations.
7. **Zero Camera Occlusion**: Tall background salvage structures and crane silhouettes are positioned north/west of the playfield so they never occlude the player or bike during fast maneuvers.
8. **Original & Modular Art**: All geometry and shaders are procedural, modular, or engine-native (Box/Cylinder/Prism primitives with custom UVs, trims, vertex color, and PBR roughness/metallic maps). Zero unlicensed third-party asset bloat.
9. **Zero Gameplay Physics Regressions**: All 15 existing V1–V7 assertion suites must continue passing 100% green.
10. **Mobile Performance Budget**: Total draw calls < 80, triangle count < 40,000, 60 FPS solid at 1080p mobile baseline.

---

## 3. MODULAR SCRAP KIT SPECIFICATION (`V8 01.1`)

The world dressing kit is constructed from a small, reusable library of 6 modular prop archetypes:
1. **`Prop_ScrapPile_A/B`**: Compound organic-industrial heap formed from angled metal plates, beams, and compressed salvage cubes with rust/wear materials.
2. **`Prop_SalvageContainer`**: Industrial corrugated cargo box with open/dented variants, used for perimeter bulk and spatial definition.
3. **`Prop_PipeRack_Modular`**: Overhead/ground conduit runs with flange joints for perimeter industrial framing.
4. **`Prop_CorrugatedFence_Section`**: Weathered metal panel fencing defining yard borders without blocking camera sightlines.
5. **`Prop_DebrisCluster_Flat`**: Non-colliding planar ground decal/quad mesh with tire tracks, oil stains, and metal filings for ground texture breakup.
6. **`Prop_IndustrialLightPost`**: Rusted stanchion with low-intensity spotlight cone illuminating key points of interest.

---

## 4. LANDMARK SILHOUETTE PASS (`V8 01.2`)

Five hero gameplay zones receive distinct architectural identities:
1. **The Starting Alcove (Player Cold Start)**: Sheltered garage/lean-to overhang with rusted corrugated roof providing a grounded starting vignette.
2. **The Signal Tuner Outpost (Z ≈ -3.5)**: Elevated transformer rig with ceramic insulators and subtle blinking diode mast.
3. **The Core Extraction Bay (Corroded Panel)**: Heavy decommissioned machinery husk with the glowing amber panel recessed into its chassis.
4. **The Courier Bike Staging Pad**: Clean concrete slab with yellow-and-black hazard striping marking the vehicle socket.
5. **The Signal Gate Barrier Assembly**: Dual reinforced steel pillars supporting the physical scrap barrier arm, with overhead warning hazard paint.
6. **The Elevated Shortcut**: Reinforced scrap steel ramp with visible cross-bracing and side guide rails.

---

## 5. LIGHTING, ATMOSPHERE & COLOR PALETTE (`V8 01.3`)

- **Palette**:
  - *Base Terrains*: Deep asphalt grey (`#2B2D31`), rusted iron (`#5C3A21`), weathered oxidized steel (`#3D4A52`).
  - *Interactable Accents*: Signal amber (`#FF9F1C`), neon cyan telemetry (`#2EC4B6`), alarm crimson (`#E71D36`).
  - *Sunlight*: Warm low-angle industrial sunlight (`#FFF4E6`, Energy: 1.6, Pitch: -52°, Yaw: 38°).
  - *Ambient / Sky*: Moody slate overcast (`#1A1E24`, Ambient Energy: 0.35).
- **Atmosphere FX**:
  - Ground dust drift GPU particles (subtle low-density scrap flecks blowing in wind).
  - Localized volumetric fog/glow around the Signal Tuner mast and Core extraction bay.

---

## 6. A/B VISUAL BENCHMARK MATRIX & REGRESSION GATES (`V8 01.4`)

A deterministic visual capture script (`_export_v8_benchmarks()`) exports high-resolution viewport captures across the 8 standard camera views:
1. `v8_01_cold_start.png`
2. `v8_02_tuner_approach.png`
3. `v8_03_panel_extraction.png`
4. `v8_04_bike_staging.png`
5. `v8_05_gate_approach.png`
6. `v8_06_shortcut_ramp.png`
7. `v8_07_active_chase.png`
8. `v8_08_quiet_aftermath.png`

Each shot is audited against:
- `IDENTITY`: Reads immediately as a scrap salvage yard.
- `ROUTE_READABILITY`: Driving surface and turn boundaries unambiguous.
- `INTERACTABLE_READABILITY`: Tuner, Panel, Bike, Gate stand out with high contrast.
- `PLAYER_VISIBILITY`: Player avatar and bike clearly distinguishable at all times.
- `DEPTH/SILHOUETTE`: Parallax and structure depth from 3/4 camera angle.
- `OCCLUSION`: Zero unwanted foreground obstruction.
- `PERFORMANCE`: Frame time < 16.6ms, draw calls < 80.
