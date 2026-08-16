# V8 M01 SPECIFICATION: SCRAPHEAP WORLD IDENTITY, DRESSING & ATMOSPHERE (REVISED)

**Status**: APPROVED / SPEC-LOCKED  
**Target Subsystems**:
- `godot/scenes/world/scrap_yard_dressing.tscn` (Dedicated art & dressing instance scene)
- `godot/scenes/prototype/scrap_test_block.tscn` (Live gameplay scene instancing `scrap_yard_dressing.tscn`)
- `godot/scripts/prototype/scrap_test_block.gd` (A/B benchmark exporter & runtime regression suite)
- `godot/materials/` (Scrap metal, rust, salvage ground, emissive trims)
- `godot/scenes/props/` (Modular scrap piles, salvage containers, industrial fencing, ground decals)
**Target Baseline**: `main@4745650` (V7 Verified Golden Slice)  

---

## 1. GOAL & CONTEXT

Transform the existing Golden Slice greybox (40×40 floor box, primitive blocks, flat untextured materials) into a distinctive, original, readable scrap-industrial salvage yard environment ("Echoes in the Scrapheap") without damaging any verified V7 gameplay geometry, driving handling, camera tracking, audio clarity, or 60 FPS performance.

---

## 2. SCENE ARCHITECTURE & REVERSIBILITY

To strictly protect verified gameplay and vehicle physics from scene corruption:
```
godot/scenes/prototype/scrap_test_block.tscn (Gameplay Scene)
    ├── WorldEnvironment, DirectionalLight3D, Camera3D
    ├── PlayerCharacter, CourierBike, PursuerPrototype
    ├── SignalTuner, CorrodedPanel, SignalGate
    ├── StaticBody3D (All existing V7 gameplay collision geometry - UNCHANGED)
    └── ScrapYardDressing (Instance of godot/scenes/world/scrap_yard_dressing.tscn)
            ├── Props (Decorative scrap piles, containers, pipe racks)
            ├── Landmark Shells (Visual facades around gameplay objects)
            ├── Visual Ground Treatment (Tarmac/dirt meshes and decals)
            └── Atmospheric Particles & Emissive Accents
```
- **Decorative Art Non-Colliding Contract**: Existing V7 collision geometry = gameplay truth. V8 dressing nodes have **zero new collision shapes by default**. Passive clutter stays outside playable collision envelopes.

---

## 3. COLOR PALETTE & VISUAL HIERARCHY

The visual language reinforces existing Tier-A gameplay roles:
- **Passive World (Environment)**: Muted rust (`#4A3020`), soot/coal (`#222428`), desaturated weathered steel (`#38424B`), and dirty industrial blue-gray (`#2D3742`). Medium-dark values with broad, chunky silhouettes. No inverted-hull outline bloat on passive dressing.
- **Cyan (`#2EC4B6`)**: Reserved for Player avatar and signal-tech interactive indicators.
- **Orange-Amber (`#FF9F1C`)**: Reserved for Courier Bike, active salvage energy, Tuner dial highlights, and Extraction core glow.
- **Red (`#E71D36`)**: Reserved for Pursuer alarm, gate warning beacon, and active pursuit danger. Zero passive red ambient lighting along gameplay routes.
- **Dark Contours**: Retained specifically on Tier-A gameplay subjects (Player, Bike, Pursuer) for instant readability against textured backgrounds.

---

## 4. SIX FUNCTIONAL LANDMARK SILHOUETTES

Working art-development labels (implying industrial salvage function without declaring unverified story lore):
1. **Cold Start Shelter**: Low-profile corrugated steel lean-to roof with oil drum silhouettes.
2. **Tuner Outpost**: Structural transformer frame with ceramic insulator shapes and prominent antenna mast.
3. **Extraction Bay**: Heavy decommissioned machinery housing enclosing the Corroded Panel.
4. **Bike Staging Pad**: Concrete slab with yellow/black industrial hazard border.
5. **Gate Barrier Assembly**: Reinforced dual pivot stanchions supporting the scrap barrier arm with overhead warning bracket.
6. **Elevated Shortcut Ramp**: Industrial steel truss structure with side guide rails.

---

## 5. OCCLUSION & LIGHTING CONTRACT

- **Occlusion Contract**: No sustained or gameplay-critical occlusion. Brief foreground crossings (e.g. high crane silhouette or overhead pipe) are permitted for parallax depth, provided the player, bike, interactables, pursuer, and gate never disappear at steering or decision points.
- **Atmosphere & Lighting**:
  - Warm low-angle key sunlight with soft shadow filtering.
  - Moody overcast ambient fill.
  - Low-density ground dust drift GPU particles (`GPUParticles3D`).
  - Emissive geometry for point-of-interest beacons (no excessive real-time spotlights).
  - No expensive volumetric fog by default.

---

## 6. A/B VISUAL EVIDENCE & PERFORMANCE GATES

- **A/B Visual Capture**: Export 8 deterministic camera views comparing V7 baseline vs V8 dressed slice:
  1. `v8_01_cold_start.png`
  2. `v8_02_tuner_approach.png`
  3. `v8_03_panel_extraction.png`
  4. `v8_04_bike_staging.png`
  5. `v8_05_gate_approach.png`
  6. `v8_06_shortcut_ramp.png`
  7. `v8_07_active_chase.png`
  8. `v8_08_quiet_aftermath.png`
- **Scored Evaluation**: Each view scored across `IDENTITY`, `ROUTE_READABILITY`, `INTERACTABLE_READABILITY`, `PLAYER_VISIBILITY`, `PURSUER_VISIBILITY`, `DEPTH/SILHOUETTE`, `FALSE-COLLISION CUES`, `OCCLUSION`, `CLUTTER`.
- **Measured Baseline Performance**: Record V7 baseline telemetry (draw calls, primitive count, average and p95 frame times at 960×540 viewport) before dressing, and assert 60 FPS without material p95 regression.
- **15-Suite Regression Gate**: All 15 existing automated test suites must remain 100% GREEN.
