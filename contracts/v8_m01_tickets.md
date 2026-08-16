# V8 M01 TICKETS: SCRAPHEAP WORLD IDENTITY, DRESSING & ATMOSPHERE (REVISED)

**Spec Reference**: [`contracts/v8_m01_scrapheap_world_spec.md`](file:///Users/bobbyinthelobby/{art/contracts/v8_m01_scrapheap_world_spec.md)  
**Parent Milestone**: V8 — Scrapheap World Identity & Visual Readability  
**Status**: APPROVED / SPEC-LOCKED  

---

## TICKET OVERVIEW & SEQUENTIAL PIPELINE

```
[V7 Baseline Capture (Visual + Performance)]
                      ↓
[V8 01.1: Style Proof → Full Modular Kit]
                      ↓
[V8 01.2: World Dressing & 6 Landmarks]
                      ↓
[V8 01.3: Lighting, Atmosphere & Depth]
                      ↓
[V8 01.4: Readability & Performance Verification]
```

---

## PRE-REQUISITE: V7 Baseline Telemetry & Screenshot Capture
- **Scope**:
  - Add benchmark exporter `_export_v8_benchmarks(prefix: String)` to `scrap_test_block.gd`.
  - Capture 8 baseline screenshots (`v7_baseline_01.png` through `v7_baseline_08.png`).
  - Capture baseline performance telemetry (draw calls, primitive count, average frame time, object count at 960×540 viewport).
- **Verification Gate**:
  - Baseline images and performance log committed to repository before any visual dressing changes.

---

## TICKET V8 01.1: Visual Language, Style Proof & Modular Scrap Kit
- **Phase A (Style Proof Checkpoint)**:
  - Author shared PBR materials: `mat_rusted_scrap.tres`, `mat_corrugated_metal.tres`, `mat_salvage_tarmac.tres`.
  - Create 3 proof assets:
    1. `scrap_pile_proof.tscn` (organic metal heap with chunky silhouette)
    2. `salvage_container_proof.tscn` (corrugated industrial salvage box)
    3. `ground_debris_proof.tscn` (flat planar ground decal / dirt quad)
  - Create dedicated art layer `godot/scenes/world/scrap_yard_dressing.tscn` (instanced in `scrap_test_block.tscn`).
  - Stage proof assets around Cold Start and Tuner Outpost (0 gameplay collision changes).
  - Capture Camera3D screenshots and relay render telemetry to ChatGPT for style verification before building full kit.
- **Phase B (Full Modular Kit Expansion)**:
  - Expand modular library: `scrap_pile_b.tscn`, `pipe_rack_modular.tscn`, `corrugated_fence.tscn`.
  - Ensure materials are aggressively shared across all props (minimize draw calls and state switches).

---

## TICKET V8 01.2: World Dressing & Landmark Pass
- **Scope**:
  - Populate `godot/scenes/world/scrap_yard_dressing.tscn` across the entire test block.
  - Dress the 6 functional landmarks:
    1. **Cold Start Shelter**: Low-profile corrugated steel overhang and oil barrel silhouettes.
    2. **Tuner Outpost**: Transformer rig frame with insulator geometry and antenna mast.
    3. **Extraction Bay**: Decommissioned machinery chassis enclosing the Corroded Panel.
    4. **Bike Staging Pad**: Concrete slab with hazard striping border.
    5. **Gate Barrier Assembly**: Reinforced pivot stanchions and overhead warning bracket.
    6. **Shortcut Ramp**: Structural steel trusses and guide rail silhouettes.
  - Perimeter wall dressing: Stacked containers, scrap heaps, and background silhouettes.
  - High-speed driving lane verification: Drive route at full bike speed; assert zero player/bike occlusion at decision points.

---

## TICKET V8 01.3: Lighting, Atmosphere & Silhouette Depth
- **Scope**:
  - Configure `DirectionalLight3D` for warm low-angle industrial sunlight with soft shadow filtering.
  - Configure `WorldEnvironment` for moody overcast ambient fill and subtle tonemapping.
  - Add low-density dust drift GPU particle emitter (`GPUParticles3D`).
  - Add emissive accents for interactable POIs (Tuner mast, Extraction Core, Gate hazard beacons, Bike headlight).
  - No expensive volumetric fog or excessive real-time spotlights.

---

## TICKET V8 01.4: Readability & Performance Falsification
- **Scope**:
  - Export 8 dressed screenshots (`v8_dressed_01.png` through `v8_dressed_08.png`).
  - A/B score all 8 shots against V7 baseline (`IDENTITY`, `ROUTE_READABILITY`, `INTERACTABLE_READABILITY`, `PLAYER_VISIBILITY`, `PURSUER_VISIBILITY`, `DEPTH/SILHOUETTE`, `FALSE-COLLISION CUES`, `OCCLUSION`, `CLUTTER`).
  - Measure dressed performance telemetry vs V7 baseline (assert 60 FPS maintained without material p95 regression).
  - Run full 15-suite regression sweep to guarantee 100% green compliance.
