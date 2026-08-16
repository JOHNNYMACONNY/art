# V8 M01 TICKETS: SCRAPHEAP WORLD IDENTITY, DRESSING & ATMOSPHERE

**Spec Reference**: [`contracts/v8_m01_scrapheap_world_spec.md`](file:///Users/bobbyinthelobby/{art/contracts/v8_m01_scrapheap_world_spec.md)  
**Parent Milestone**: V8 — Scrapheap World Identity & Visual Readability  
**Status**: TICKETS-PROPOSED / PENDING REVIEW  

---

## TICKET OVERVIEW & DEPENDENCY GRAPH

```
[V8 01.1: Modular Scrap Kit] ---> [V8 01.2: World Dressing & Landmarks]
                                              |
                                              v
[V8 01.3: Lighting & Atmosphere] ---> [V8 01.4: Readability & A/B Benchmark]
```

---

## TICKET V8 01.1: Visual Language & Modular Scrap Kit
- **Scope**:
  - Author reusable PBR materials: `mat_rusted_scrap.tres`, `mat_corrugated_metal.tres`, `mat_salvage_tarmac.tres`, `mat_hazard_trim.tres`, `mat_industrial_concrete.tres`.
  - Model 6 lightweight modular prop scenes in `godot/scenes/props/`:
    - `scrap_pile_a.tscn` (organic metal heap, LOD0 < 350 tris)
    - `scrap_pile_b.tscn` (crushed metal chassis stack, LOD0 < 400 tris)
    - `salvage_container.tscn` (corrugated shipping container with dent variations)
    - `pipe_rack_modular.tscn` (flanged industrial conduit run)
    - `corrugated_fence.tscn` (weathered metal panel perimeter wall segment)
    - `ground_debris_flat.tscn` (planar quad with dirty grease/shredded scrap decals)
  - Ensure zero collision snag points (all decorative colliders strictly align with gameplay boundary geometry).
- **Verification Gate**:
  - Test scene instantiating all 6 props; draw call budget verified < 25 for the entire kit.

---

## TICKET V8 01.2: World Dressing & Landmark Pass
- **Scope**:
  - Integrate modular props into `godot/scenes/world/scrap_test_block.tscn` without altering underlying collision boxes.
  - Dress the 5 hero landmarks:
    - **Cold Start Garage**: Lean-to corrugated roof, oil barrels, workbench silhouette.
    - **Tuner Outpost**: Transformer rig frame, ceramic insulators, high-contrast beacon mast.
    - **Extraction Bay**: Heavy industrial machinery chassis framing the Corroded Panel.
    - **Bike Staging Pad**: Concrete footing with hazard border.
    - **Signal Gate Barrier Assembly**: Reinforced pivot stanchions and overhead warning bracket.
    - **Shortcut Ramp**: Structural trusses and guide rails.
  - Populate perimeter walls with salvage containers, stacked scrap heaps, and background silhouettes.
- **Verification Gate**:
  - Visual inspection from 3/4 Camera3D view; zero player occlusion along all main transit routes.

---

## TICKET V8 01.3: Lighting, Atmosphere & Silhouette Depth
- **Scope**:
  - Configure `DirectionalLight3D` for dramatic low-angle industrial sunlight with shadow soft-filtering.
  - Configure `WorldEnvironment` for moody overcast ambient fill and subtle tonemapping.
  - Add atmospheric dust drift GPU particle emitter (`GPUParticles3D`) over the salvage yard.
  - Add emissive accent lights to the Tuner mast, Extraction Core, Gate hazard lights, and Bike headlight.
- **Verification Gate**:
  - High-contrast visual separation: Player, Bike, Pursuer, and Interactables clearly legible against all lighting zones.

---

## TICKET V8 01.4: Readability & Mobile Performance Falsification
- **Scope**:
  - Implement deterministic A/B benchmark exporter `_export_v8_benchmarks()` in `scrap_test_block.gd`.
  - Capture 8 high-resolution camera angles comparing V7 baseline vs V8 dressed slice.
  - Measure frame times and draw call counts in Godot Profiler.
  - Run full 15-suite regression sweep to guarantee 0 gameplay physics or interaction regressions.
- **Verification Gate**:
  - 8/8 benchmark screenshots exported and verified clean.
  - 15/15 regression suites 100% GREEN.
  - Frame time < 16.6ms at 1080p.
